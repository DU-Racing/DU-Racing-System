-- Params
raceID = "test1" --export: sent from the central system to set the current race ID

testRace = false --export: if set to true this will not emit times but allow the course to be run
testTrackKey = "Test Track" --export: Active track key, only used for test races

-- Organiser Params
-- Current Track Key (the current race key to use for saving waypoints)
organiserMode = false --export: if set to true this will allow new waypoints to be saved and exported

-- Globals
messageParts = {}
waypoints = {}
sectionTimes = {} -- stores the times for each section
savedWaypoints = {} -- stores the waypoints when an organiser is plotting a race
currentWaypointIndex = 1 -- keeps track of the current active waypoint index
currentWaypoint = nil -- vec3 of the current waypoint poisition, used for working out distance
startTime = 0 -- start time in ms
endTime = 0 -- end time ms
splitTime = 0 -- current splt time start
lapTime = 0 -- tracks lap time
lapTimes = {} -- tracks all lap times
laps = 1 -- updated when the waypoints for the track are loaded
trackName = "" 
raceStarted = false

-- Functions
function handleTextCommandInput(text)

  system.print("Command: " .. text)

  -- Help
  if text == "help" then
    -- Outputs all commands with a description
    system.print("-==:: DU Racing Command Help ::==-")
    system.print('"add waypoint {ALT+2}" - adds the current position to the track waypoints')
    system.print('"save track [track name]" - saves the stored waypoints to screen')
    system.print('"list tracks" - lists all track keys saved in the databank')
    system.print('"broadcast track [track name]" - broadcasts track to central system')
    system.print('"export track [track name]" - exports the track JSON to the screen')
    system.print('"start {ALT+1}" - starts the test race with the set track key')
    return true
  end

  if text == "add waypoint" then
    if organiserMode == false then 
        system.print("Waypoints can only be saved ")
        return false
    end
    return saveWaypoint()
  end

  if text == "start" then
    if testRace == false then
      system.print("Races can only be started manually when in test mode")
      return false
    end
    return startRace()
  end

  if text:find("save track ") then
    local trackName = string.gsub(text, "save track ", "")
    if trackName == "" then
      system.print("A track name must be used when saving a track. eg 'save track Alioth Loop'")
      return false
    end
    return saveTrack(trackName)
  end

  if text == "list tracks" then
    local keys = json.decode(db.getKeys())
    local out = ""
    for key, value in pairs(keys) do
      if value ~= "activeRace" then
        out = value .. ", " .. out
      end
    end
    return system.print(out)
  end

  if text:find("export track ") then
    local trackName = string.gsub(text, "export track ", "")
    if trackName == "" then
      system.print("A track name must be used when exporting a track. eg 'export track Alioth Loop'")
      return false
    end
    return exportTrack(trackName)
  end

  if text:find("broadcast track ") then
    local trackName = string.gsub(text, "broadcast track ", "")
    if trackName == "" then
      system.print("A track name must be used when broadcasting a track. eg 'broadcast track Alioth Loop'")
      return false
    end
    return broadcastTrack(trackName)
  end

  system.print("I can't... " .. text)
end

-- calcDistance(vec3 v1, vec3 v2)
-- Returns the distance in metres between 2 vectors
function calcDistance(v1, v2)
  v = {}
  v.x = v1.x - v2.x;
  v.y = v1.y - v2.y;
  v.z = v1.z - v2.z;
  return math.sqrt(v.x*v.x + v.y*v.y + v.z*v.z)
end

-- Message part system functions
function getKeysSortedByValue(tbl, sortFunction)
    local keys = {}
    for key in pairs(tbl) do
    table.insert(keys, key)
    end

    table.sort(keys, function(a, b)
    return sortFunction(tbl[a], tbl[b])
    end)

    return keys
end

function getCompleteMessage()
    local sorted = getKeysSortedByValue(messageParts, function(a, b) return tonumber(a["index"]) < tonumber(b["index"]) end )    
    message = ""
    for _, key in ipairs(sorted) do
        message = message .. messageParts[key]["content"]
    end
    return message
end

function split(str, maxLength)
  local lines = {}

  local partLength = math.ceil(str:len() / maxLength)
  local len = partLength
  local startNum = 1
  local endNum = maxLength
  while partLength > 0 do
    table.insert(lines, string.sub(str, startNum, endNum))
    startNum = startNum + maxLength
    endNum = endNum + maxLength
    partLength = partLength - 1
  end 
  return { lines = lines, length = len }
end

function splitBroadcast(action, channel, message)
    local index = 1
    local parts = split(message, 200)
    for _, line in ipairs(parts["lines"]) do
       local jsonStr = json.encode({ i = index, len = parts["length"], action = action, content = line})
       local send = string.gsub(jsonStr, '\\"', '|')
       send = string.gsub(send, '"', '\\"')
       emitter.send(channel, send)
       index = index + 1
    end    
end

-- xyzPosition(float x, float y, float z)
-- Returns a waypoint string from the given coordinates
function xyzPosition (x,y,z)
  -- 0,2 for Alioth, although this seems broken it outputs 0,0 and works correctly, when setting the pos as "0,2" for Alioth the waypoint is incorrect
  return "::pos{0,0," .. tostring(x) .. "," .. tostring(y) .. "," .. tostring(z) .. "}";
end

-- checkWaypoint()
-- returns bool if user is in range of waypoint, triggers nextWaypoint
function checkWaypoint()
  if currentWaypoint == nil then
    return false
  end
  -- This is checked on loop
  pos = vec3(core.getConstructWorldPos())
  dest = vec3(waypoints[currentWaypointIndex])

  distance  = calcDistance(pos, dest)

  -- Are we within 20m of our target destination?
  if distance <= 20 then
    -- If so, save time, trigger next waypoint
    local t = round(system.getTime() - splitTime)
    table.insert(sectionTimes, t)
    splitTime = system.getTime()

    -- show on screen
    screen.setCenteredText(t .. " s")
    -- show in console
    system.print("Section time: " .. t .. " s")
    nextWaypoint()
    return true
  end

  return false
end

-- nextWaypoint
-- returns null increments the active index in use of waypoint, sets the vec3 waypoint for user
function nextWaypoint()
  local now = system.getTime()
  -- Queries the databank and set the next waypoint
  currentWaypointIndex = currentWaypointIndex + 1
  nextPoint = waypoints[currentWaypointIndex]
  -- no more waypoints?
  if nextPoint == nil then

    -- display lap time
    local lap = round(now - lapTime)
    screen.setCenteredText("Lap time " .. lap .. " s")
    system.print("Lap time: " .. lap .. " s")
    table.insert(lapTimes, lap)

    -- check laps
    laps = laps - 1
    if laps == 0 then
      endTime = now
      endRace()
      return true
    end

    -- reset lap start
    lapTime = now
    -- reset the waypoints for next lap
    nextPoint = waypoints[1]
  end
  currentWaypoint = vec3(nextPoint[1],nextPoint[2],nextPoint[3])
  system.setWaypoint(xyzPosition(currentWaypoint.x, currentWaypoint.y,currentWaypoint.z))
end

-- Race Countdown
-- Sets the active race which is used to fetch waypoints
-- Triggered from a startline emitter, which waits 3 seconds then emits
-- Countdown 3,2,1 GO (await emit from start system, trigger start race)

-- Start Race
function startRace()
  if raceStarted == false then
    screen.setCenteredText("GO")
    system.print("GO")
    raceStarted = true
    -- set first waypoint
    currentWaypoint = vec3(waypoints[1][1],waypoints[1][2], waypoints[1][3])
    system.setWaypoint(xyzPosition(currentWaypoint.x,currentWaypoint.y,currentWaypoint.z))

    -- set start time and first split time
    startTime = system.getTime()
    lapTime = startTime
    splitTime = startTime
  end
end

-- End Race
function endRace()
  system.setWaypoint(nil)
  
  screen.setCenteredText("Final time " .. round(endTime - startTime) .. " s")

  system.print("Finished race")
  system.print("Section times:  " .. json.encode(sectionTimes))
  system.print("Lap times:  " .. json.encode(lapTimes))
  system.print("Final time: " .. round(endTime - startTime) .. " s")

  -- Emit this data
  if testRace == false then
    emitFinalTimes()
  end

end

function round(n)
  return tonumber(string.format("%.3f", n))
end


-- Emitter/Receiver functions

-- Clear DB
function clearDB()
  -- Clears the databank of all entries
  db.clear()
end

-- Set Track Waypoints
function setTrackWaypoints(trackKey, trackJson)
  -- Sets the JSON as waypoints for the location
  db.setStringValue(trackKey, trackJson)
end

-- Get Race Track
function getTrackWaypoints(trackKey)
  -- Fetches the waypoints from the DB and decodes them
  local track = db.getStringValue(trackKey)
  -- Sets the number of laps for this track
  track = json.decode(track)
  if track == nil then
     system.print("ERROR: Track not found")
     return false
  end
  laps = track["laps"]
  return track["waypoints"]
end

-- Emit final times
function emitFinalTimes()
  -- JSON encode the logged times and emit them to the stadium
  local times = {
    lapTime = round(endTime - startTime),
    raceID = raceID,
    racer = unit.getMasterPlayerId()
  }

  -- TODO: Save these locally for inspection if needed

  -- TODO: this is an important notification, it should be sent on a loop until a confirmation message is returned
  local json = json.encode(times)
  local send = string.gsub(json, '"', '\\"')
  emitter.send("fdu-finish", send)
end

-- Race Organiser Functions

-- Save waypoint
function saveWaypoint()
  -- Saves the current position as a waypoint
  local pos = vec3(core.getConstructWorldPos())
  table.insert(savedWaypoints, {pos.x, pos.y, pos.z})

  -- Output to lua console for debug
  local curr = xyzPosition(pos.x,pos.y,pos.z)
  system.print(curr)
end

-- Save Track
function saveTrack(trackName)
  -- Exports current saved waypoints to JSON
  local track = { name = trackName, laps = 1, waypoints = savedWaypoints}
  screen.setHTML(json.encode(track))
  system.print("Track data has been exported to the screen. Edit the HTML to copy it. " ..
  "It has also been broadcast to the central system, you trigger this manually again if needed.")
  system.print("The data has also been saved to the database, exit organiser mode, " ..
  "set the active track as the name of the saved track and enter test mode to try it out.")

  db.setStringValue(trackName, json.encode(track))

  -- Add it as screen HTML so it can be copied as well
  -- TODO: Emits data to central hub
  local send = string.gsub(json.encode(track), '"', '\\"')
  emitter.send("fdu-addtrack", send)
end

-- save broadcasted track
function saveBroadcastedTrack(str)
   local track = json.decode(str)
   db.setStringValue(track["name"], str)
   loadTrack(track["name"])
   screen.setCenteredText("Welcome to " .. track["name"])
   system.print(track["name"] .. " has been loaded")
end

-- load track
function loadTrack(name)
   waypoints = getTrackWaypoints(name) 
   trackName = name
end

-- export track
function exportTrack(trackName)
  local track = db.getStringValue(trackName)
  if track == nil then 
    system.print("ERROR: Track not found")
    return false
  end
  screen.setHTML(track)
  return system.print("Track has been exported to the screen HTML")
end


-- broadcast track
function broadcastTrack(trackName)
  local track = db.getStringValue(trackName)
  if track == nil then 
    system.print("ERROR: Track not found")
    return false
  end
  local send = string.gsub(track, '"', '\\"')
  emitter.send("fdu-addtrack", send)
  return system.print("Track has been broadcasted to central system")
end


-- Race screen
-- Sets up the race screen
-- Default is welcome screen, with buttons for test race

-- Test screen shows saved races and allows them to be selected
-- Hit the start button to start the countdown, then test starts

-- If we have start time show it on the screen instead of the welcome with split times
-- If we have end time then show final time with split times

-- Activate screen
screen.activate()
if organiserMode then
  system.print("-==:: DU Racing Organiser Mode ::==-")
  system.print(
  "Travel to waypoints, type 'add waypoint' in lua console or press {ALT+2} " ..
  "to save the current location as a new waypoint. " ..
  "Type 'save track [track name]' to save the track or 'broadcast track [track name]' to add it to the central system."
  )

  screen.setCenteredText("Organiser Mode")
elseif testRace then
  system.print("-==:: DU Racing Test Mode ::==-")

  -- Check they have an active track
  if testTrackKey == "" then
    system.print("ERROR: No test track key has been set")
    return false
  end

  -- Check this track exists
  waypoints = getTrackWaypoints(testTrackKey)
  if waypoints == nil then
    system.print("ERROR: No track waypoints found in database")
    return false
  end

  system.print(
  "Type 'start' in lua console or hit {ALT+1} to start the test race"
  )

  screen.setCenteredText("Test Mode")
else
  -- emit racer online if we have a race ID
  if raceID ~= "" then
    local startData = {raceID = raceID, racer = unit.getMasterPlayerId()}
    emitter.send("fdu-register", string.gsub(json.encode(startData), '"', '\\"'))
  end
  screen.setCenteredText("Awaiting Race Information")
end

