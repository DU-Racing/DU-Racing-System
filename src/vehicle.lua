-- Params
raceID = "test1" --export: sent from the central system to set the current race ID

testRace = true --export: if set to true this will not emit times but allow the course to be run
testTrackKey = "Mos Espa Circuit" --export: Active track key, only used for test races
ad = "assets.prod.novaquark.com/74927/55ab19e2-29c8-47f7-b267-a3b87f40a392.png" --export: Sponsor for this race. 
map = "assets.prod.novaquark.com/74927/a28ec69c-1a26-4d85-b579-5acedc3f69c2.png" --export: Image for background on map 
-- Organiser Params
-- Current Track Key (the current race key to use for saving waypoints)
organiserMode = false --export: if set to true this will allow new waypoints to be saved and exported
radius = 100 --export: radius /this should nto be left public long term
sponsorText = "Prize Sponsor - 1M " --export: Text by sponsor image.
-- Globals
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
remainingLaps = 1 -- updated when the waypoints for the track are loaded
totalLaps = 1
trackName = "" 
raceStarted = false
messageParts = {} -- multipart messaging table
gTab = "race" --race tracks new test config
gState = "start" -- start, awaiting, ready, set, live, finished, error, organizer, test
gData = json.decode('{"mainMessage": "Loading...", "toast": "Welcome to DU Racing" }')
-- Functions
function handleTextCommandInput(text)

  print("Command: " .. text,false)

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
        system.print("Waypoints can only be saved in organizer mode.")
        return false
    end
    return saveWaypoint()
  end
  if text == "countdown" then
    return startCountdown()
  end
  if text == "start" then
    if testRace == false then
      doError("Races can only be started manually when in test mode")
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

-- calcDistance(vec3 v1, vec3 v2)
-- Returns the distance in metres between 2 vectors
function calcDistance(v1, v2)
  v = {}
  v.x = v1.x - v2.x;
  v.y = v1.y - v2.y;
  v.z = v1.z - v2.z;
  return math.sqrt(v.x*v.x + v.y*v.y + v.z*v.z)
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
  if distance <= radius then
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
  print("Waypoint #"..currentWaypointIndex..' complete.', true)
  incrementWaypoint()
  nextPoint = waypoints[currentWaypointIndex]
  -- no more waypoints?
  if nextPoint == nil then

    -- display lap time
    local lap = round(now - lapTime)
    screen.setCenteredText("Lap time " .. lap .. " s")
    system.print("Lap time: " .. lap .. " s")
    table.insert(lapTimes, lap)

    -- check laps
    decrementLaps()

    if remainingLaps == 0 then
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
function decrementLaps()
  remainingLaps = remainingLaps - 1
  print("Lap complete.", true)
end
function incrementWaypoint()
  currentWaypointIndex = currentWaypointIndex + 1
  system.updateData(currentWaypointRef, '{"value":"'..currentWaypointIndex..'"}')
  system.updateData(currentWaypointBarRef, '{"percentage": '..math.floor((currentWaypointIndex/ #waypoints )*100)..'}')
end

function modulus(a, b)
  return a - math.floor(a/b)*b
end

-- Race Countdown
-- Sets the active race which is used to fetch waypoints
-- Triggered from a startline emitter, which waits 3 seconds then emits
-- Countdown 3,2,1 GO (await emit from start system, trigger start race)

-- Start Race
function startRace()
  unit.stopTimer("countGo")
  if raceStarted == false then
    gState = "test"
    gData.mainMessage = ""
    print("GO!", true)
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

--TODO Counts down from 5 to go. Needs to be able to communicate with tower
function startCountdown()
  unit.setTimer("count3", 1)
  unit.setTimer("count2", 2)
  unit.setTimer("count1", 3)
  unit.setTimer("countSet", 4)
  unit.setTimer("countGo", 5);
end
function countdownReady3()
  unit.stopTimer("count3")
  print("Ready.", true)

end
function countdownReady2()
  unit.stopTimer("count2")
  print("Ready..", true)
end
function countdownReady1()
  unit.stopTimer("count1")
  print("Ready...", true)
end
function countdownSet()
  unit.stopTimer("countSet")
  print("Set...", true)
end
-- End Race
function endRace()
  system.setWaypoint(nil)--TODO where do we set final waypoint? 
  
  gData.mainMessage= "Final time " .. round(endTime - startTime) .. " s"

  print("Finished race", true)
  print("Section times:  " .. json.encode(sectionTimes), false)
  print("Lap times:  " .. json.encode(lapTimes), false)
  print("Final time: " .. round(endTime - startTime) .. " s", false)

  -- Emit this data
  if testRace == false then
    emitFinalTimes()
  end

end

function round(n)
  return tonumber(string.format("%.3f", n))
end

function round2(n)
  return tonumber(string.format("%.0f", n))
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
  remainingLaps = track["laps"]
  totalLaps = track["laps"]
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
    doError("ERROR: Track not found")
    return false
  end
  screen.setHTML(track)
  return system.print("Track has been exported to the screen HTML")
end

function toggleTestMode()
  testRace = ~testRace
  if(testRace)then
    enterTestMode()
  else
    exitTestMode()
  end  
end


-- broadcast track
function broadcastTrack(trackName)
  local track = db.getStringValue(trackName)
  if track == nil then 
    system.print("ERROR: Track not found")
    return false
  end
  splitBroadcast("save-track", "fdu-centralsplit", track)
  return system.print("Track has been broadcasted to central system")
end

--UI stuff
function updateOverlay()  
  local html = '<div class="mainWrapper">'
  html = html .. '<div style="position: absolute; left: 38vw;top: 40vh;" class="mainMessage">'..gData.mainMessage..'</div>'
  if(gData.toast ~= "") then
    html = html .. '<div class="toast" style="position: relative; top: 80vh;display: block;" class="toastMessage"><div class="centered">'..gData.toast..'</div></div>'
  end
  html = html ..  
       '<div style="position: absolute; right: 5vw; top: 25vh;width: 10vw; height: 8vh;border:5px solid red;"><img class="map" src="'..map..'"/></div>'..
       '<div style="position: absolute; left: 3vw; top: 2vh;width: 10vw;"><img class="ad" src="'..ad..'"/><h2 class"sponsorText">'..sponsorText..'</h2></div>'..
       '</div>'  
  system.setScreen(styles..html)
end

function updateScreen()
  doUpdateScreen = false
end

function requestScreenUpdate(doOverlayToo)
  doUpdateScreen = true
  if(doOverlayToo) then
    updateOverlay()
  end  
end

function clearOverlay()
  system.destroyWidgetPanel(raceInfoPanel);
end

function initOverlay()
    system.showScreen(1)
  --section: Race Status
  raceInfoPanel = system.createWidgetPanel('Race Status')
  currentWaypointBarRef = addProgressWidget(raceInfoPanel,1)
  currentWaypointRef = addStaticWidget(raceInfoPanel,'1','Waypoint','/3')
  currentLapBarRef = addProgressWidget(raceInfoPanel, math.floor(1/(totalLaps+1)*100))
  currentLapRef = addStaticWidget(raceInfoPanel, '1','Current Lap','/'..totalLaps)
  
  lapTimeRef = addStaticWidget(raceInfoPanel,'0:00:00.000', 'Lap Time','')
  totalTimeRef = addStaticWidget(raceInfoPanel,'0:00:00.000', 'Total Time','')
  deltaTimeRef = addStaticWidget(raceInfoPanel,'--:--:--.---', 'Your Best Lap','')
  
  
  --section: Race Info
  infoTitleWidget = system.createWidget(raceInfoPanel, 'title')
  infoTitleData = system.createData('{"text":"Race Info"}')
  system.addDataToWidget(infoTitleData, infoTitleWidget)

  addStaticWidget(raceInfoPanel, 'Mos Espa Circuit', 'Track Name', '')
  addStaticWidget(raceInfoPanel, 'XS-X-X', 'Class', '')
  addStaticWidget(raceInfoPanel,'0:00:00.000', 'Track Record','')
  addStaticWidget(raceInfoPanel, 'testKey1782','Race Key', '')
  addStaticWidget(raceInfoPanel, '37', 'Length', 'km')
  addStaticWidget(raceInfoPanel, 'Atmos', 'Type', '')

  

  --section: Driver Profile
  racerTitleWidget = system.createWidget(raceInfoPanel, 'title')
  racerTitleData = system.createData('{"text":"Driver Profile / Config"}')
  system.addDataToWidget(racerTitleData, racerTitleWidget)

  
  addStaticWidget(raceInfoPanel, 'Obsidian', 'Team Name', '')
  addStaticWidget(raceInfoPanel, 'Red', 'Color', '')
  

 

  --set up styles
  styles = [[

    <style type="text/css">
    .mainWrapper, .glowText{
    	color: #a1ecfb;
      margin: 0 0 20px;
      transition: color 250ms ease-out;
      font-weight: bold;
      text-shadow: 0 0 4px rgba(161,236,251,0.65);
      text-transform: uppercase;
    }
    .mainMessage{
      font-size: 8vh;
    }
    .toast{
      -webkit-animation: cssAnimation 0s ease-in 5s forwards;
      background-color: #a1ecfb;
      font-size: 2vh;
      font-weight: 700;
      color: black;
      display: block;
      border-radius: 10px;
      padding: 20px;
      animation-fill-mode: forwards;
    }
    .centered{
      margin: 0 30vw !important;
      text-align: center;
      display: block !important;
      width: 40vw !important;
    }
    .ad, .map{
      width: 100%;
    }
    @-webkit-keyframes cssAnimation {
      to {width: 0; height: 0; visibility: hidden;}
    }
      </style>  
  ]]
  
  requestScreenUpdate(true)
  system.showScreen(1)
end

function toast(message)
  gData.toast = message
  requestScreenUpdate(true)
end

function addProgressWidget(parentPanel, value)
  local tempWidget = system.createWidget(parentPanel, 'gauge')
  local tempData = system.createData('{"percentage": '..value..'}')
  system.addDataToWidget(tempData, tempWidget)
  return tempData;
end

function addStaticWidget(parentPanel, value, label, unit)
  local tempWidget = system.createWidget(parentPanel, 'value')
  local tempData = system.createData('{"value": "'..value..'","label":"'..label..'", "unit": "'..unit..'"}')
  system.addDataToWidget(tempData, tempWidget)
  return tempData;
end

function updateTime()
  if not raceStarted then
    return
  end
  local now = system.getTime()
  system.updateData(totalTimeRef,'{"value": "'..formatTime(now - startTime)..'"}')
  system.updateData(lapTimeRef,'{"value": "'..formatTime(now - lapTime)..'"}')
end

function formatTime(seconds)
    local secondsRemaining = seconds
    local hours = math.floor(secondsRemaining / 3600)
    secondsRemaining = modulus(secondsRemaining, 3600)
    local minutes = math.floor(secondsRemaining / 60)
    local seconds = round2(modulus(secondsRemaining, 60))

    return leadingZero(hours)..":"..leadingZero(minutes)..":"..leadingZero(seconds)
end

function leadingZero(num)
  if(num<10) then 
    return "0"..num
  end
  return num
end

-- Race screen
-- Sets up the race screen
-- Default is welcome screen, with buttons for test race

-- Test screen shows saved races and allows them to be selected
-- Hit the start button to start the countdown, then test starts

-- If we have start time show it on the screen instead of the welcome with split times
-- If we have end time then show final time with split times

-- Activate screen and UI
initOverlay()
screen.activate()

function setDefaults()
end


function main()
  setDefaults()
  if organiserMode then
    newRaceInfoPanel = system.createWidgetPanel('New Race')
    gState = "organiser"
    print("-==:: DU Racing Organiser Mode ::==-", false)
    print([[
    "Travel to waypoints, type 'add waypoint' in lua console or press {ALT+2} to save the current location as a new waypoint. 
    Type 'save track [track name]' to save the track or 'broadcast track [track name]' to add it to the central system."]], false
    )
    gData.mainMessage= ""
    toast("Entering Organizer Mode")
    
  elseif testRace then
    enterTestMode()
  else
    -- emit racer online if we have a race ID
    if raceID ~= "" then
      local startData = {raceID = raceID, racer = unit.getMasterPlayerId()}
      emitter.send("fdu-register", string.gsub(json.encode(startData), '"', '\\"'))
    end
    gState = "awaiting"
    gData.mainMessage="REGISTERING"
    toast("Registering with mainframe.")
  end
end

function enterTestMode()
  print("-==:: DU Racing Test Mode ::==-")
    -- Check they have an active track
    if testTrackKey == "" then
      doError("No test track key has been set")
      return false
    end

    initWaypoints()

  print("Type 'start' in lua console or hit {ALT+1} to start the test race",false)
  gData.mainMessage= "Press ALT+1 to begin. "
  toast("Test mode activated.")
end

function initWaypoints()
  waypoints = getTrackWaypoints(testTrackKey)
  if waypoints == nil then
    doError("No track waypoints found in database")
    return false
  end
  system.updateData(currentWaypointRef, '{"value": 1, "unit": "/'..#waypoints..'"}')
  
end

function exitTestMode()
  print("Exiting Test Mode", true)
end
function setState(newState, newData, clear)
  gState = newState
  if(clear==true) then
    gData = newData
  else
  --todo, only overwrite new data
  end
end


function doError(msg)
  print("ERROR: "..msg, true)
  gState = "error"
  
end

--Helper function to wrap system.print().  If second argument is true, it will also call a toast with the same message.
function print(msg, doToast)
  if(doToast) then
    toast(msg)
  end
  return system.print(msg)
end

main()





