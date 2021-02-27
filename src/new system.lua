--DU RACING v1.0 created by rexsilex, NinjaFox and cAIRLs

-- Screen receiver system and stats display
-- Official races require a race adjudicator that mans this board
-- Params

-- Race ID (Sets the active race ID used to receive and store stats, auto in future
raceEventName = raceDB.getStringValue('activeRaceID')
trackKey = raceDB.getStringValue('activeTrackID')
activeTrack = nil
trackName = '' -- Set from the databank when looking up track key
messageParts = {}
messageQueue = {}
consumerStarted = false
myDebug = false --export: Toggles debug printouts to the console.

-- Do not adjust version
version = '1.0'

-- Text controller
function handleTextCommandInput(text)
  local commands = {
    help = function()
      -- Outputs all commands with a description
      system.print("-==:: DU Racing Command Help ::==-")
      system.print('Use "setTrack" and "setRaceEvent" to create a event under the "setRaceEvent"-Name on the "setTrack"-Track. Use "startRace" to start after all racers registered.')
      system.print('"setTrack(trackName)" - sets the active track.')
      system.print('"setRaceEvent(yourRaceName)" - creates a race event under the name you make up.')
      system.print('"startRace" or {ALT+1} - initializes the start of race sequence.')
      system.print('"endRace" or {ALT+2} - closes all further time submissions to this race (not the be mistaken as crossing the finish line)')
      system.print('"listRacers" - prints out a list of all registered racers for the set race.')
      system.print('"disqRacer(racerName)" - disqualifies the player with "racerName" from the set race.')
      system.print('"listTracks" - prints out a list of all stored tracks.')
    end,
    
    setTrack = function(trackKey)
      if trackDB.hasKey(trackKey) == 1 then
        raceDB.setStringValue('activeTrackID', trackKey)
        system.print('Track name has been set.')
        buildRaceStatScreen()
        createRace(raceEventName)
      else
        doError('Could not set track. No such track name stored: "'..trackKey..'".')
      end
    end,
    
    startRace = function()
      -- Emits a message to prepare, then emits a GO signal 3 seconds later
      -- Can control traffic lights
      local race = getRace(raceEventName)
      if race == nil then
        return errorPrint('No race found with this name: "'..raceEventName..'".')
      end
      race["status"] = 'started'
      -- save the race
      raceDB.setStringValue(raceEventName, json.encode(race))
      -- start the race
      system.print('Race "'..raceEventName..'" started!')
      emitter.send(raceEventName, 'start')
    end,

    endRace = function() -- Marks the race as complete, no more times will be accepted and the race is archived.
      local race = getRace(raceEventName)
      if race == nil then
        return errorPrint('No race event created that could end.')
      end
      race["status"] = 'ended'
      raceDB.setStringValue(raceEventName, json.encode(race)) -- save the race data
      emitter.send(raceEventName, 'end')
      return system.print('Race "'..raceEventName..'" has ended. No further time submissions are taken.')
    end,

    -- List racers
    listRacers = function()
      local race = getRace(raceEventName)
      if race == nil then
        return errorPrint('Can not list racers. No race event name found with this name: "'..raceEventName..'".')
      end
      local racers
      for key, value in pairs(race["racers"]) do
        racers = racers == nil and race["racers"][key]["name"] or racers .. ', ' .. race["racers"][key]["name"]
      end
      return system.print('Registered racers for "'..raceEventName..'": ' .. racers)
    end,

    -- Disqualify racer
    disqRacer = function(dqf)
      local race = getRace(raceEventName)
      if race == nil then
        return errorPrint('Could not disqualify racer "'..dqf..'" as there is no race event found with this name: "'..raceEventName..'".')
      end
      for key, value in pairs(race["racers"]) do
        if race["racers"][key]["name"] == dqf then
          race["racers"][key]["time"] = "DQF"
          raceDB.setStringValue(raceEventName, json.encode(race))
          return system.print(dqf .. ' has been disqualified from race "'..raceEventName..'".')
        end
      end
      return errorPrint('Could not disqualify racer "'..dqf..'". No racer with this name in the race event.')
    end,

    -- Set race id
    setRaceEvent = function(raceEventName)
      raceDB.setStringValue('activeRaceID', raceEventName)
      buildRaceStatScreen()
      return createRace(raceEventName)
    end,

    -- List all saved race keys
    listTracks = function()
      local keys = json.decode(raceDB.getKeys())
      local out
      for key, value in pairs(keys) do
        if value ~= "activeRaceID" and value ~= "activeTrackKey" then
          out = out == nil and value or out..', '..value
        end
      end
      return system.print(out)
    end,

    -- export race, hidden function
    exportRaceEvent = function(exportKey)
      local raceExport = raceDB.getStringValue(exportKey)
      if screen then
        screen.setHTML(raceExport)
        ystem.print('The race has been exported to the screen HTML content.')
      else
        errorPrint('Could not export race data as there is no screen connected to a slot named "screen".')
      end
    end
  }

  if myDebug then system.print('Entered Command: "'..text..'".') end

  local paramStart = string.find(text,'%(')
  local cmd = paramStart and string.sub(text,1,paramStart-1) or text
  local paramsString = ''
  
  if paramStart then
    local paramEnd = string.find(text,'%)')
    paramEnd = paramEnd or #text+1--we assume someone just forgot the closing ) and try to process anyway
    paramsString = string.sub(text,paramStart+1,paramEnd-1)
  end
  if commands[cmd] then
    commands[cmd](paramsString)
  else
    doError('Following command could not be executed: "'..text..'".')
  end
end

function consumeQueue()
  local sortedMessages = getKeysSortedByValue(
    messageQueue,
    function(a, b)
      return tonumber(tonumber(a["time"]) < tonumber(b["time"]))
    end
  )
  for _, key in ipairs(sortedMessages) do
    emitter.send(messageQueue[key]["channel"], messageQueue[key]["message"])
    unqueueMessage(key)
    break
  end    
end

function queueMessage(channel, message)
  if consumerStarted == false then
    -- Message queue consumer
    unit.setTimer("consumeQueue", 1)
    consumerStarted = true
  end
  table.insert(messageQueue, { channel = channel, message = message, time = system.getTime()})
end

function unqueueMessage(key)
  table.remove(messageQueue, key)
  local count = 0
  for _ in pairs(messageQueue) do count = count + 1 end
  if count == 0 then 
    unit.stopTimer("consumeQueue")
    consumerStarted = false
  end 
end

function getCompleteMessage()
  local sorted =
    getKeysSortedByValue(
    messageParts,
    function(a, b)
      return tonumber(a["index"]) < tonumber(b["index"])
    end
  )
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
  return {lines = lines, length = len}
end

function splitBroadcast(action, channel, message)
  local index = 1
  local parts = split(message, 350)
  for _, line in ipairs(parts["lines"]) do
  local jsonStr = json.encode({i = index, len = parts["length"], action = action, content = line})
  local send = string.gsub(jsonStr, '\\"', "|")
  send = string.gsub(send, '"', '\\"')
  queueMessage(channel, send)
  index = index + 1
  end
end

function getKeysSortedByValue(tbl, sortFunction)
  local keys = {}
  for key in pairs(tbl) do
  table.insert(keys, key)
  end

  table.sort(
  keys,
  function(a, b)
    return sortFunction(tbl[a], tbl[b])
  end
  )

  return keys
end

function formatTime(seconds)

  local function leadingZero(num)
    return num < 10 and '0' .. num or num
  end

  local function modulus(a, b)
  return a - math.floor(a / b) * b
  end

  local hours = math.floor(seconds / 3600)
  seconds = modulus(seconds, 3600)
  local minutes = math.floor(seconds / 60)
  seconds = round2(modulus(seconds, 60))

  return leadingZero(hours) .. ':' .. leadingZero(minutes) .. ':' .. leadingZero(string.format("%.0f", seconds))
end

function createTrack(str)
  local track = json.decode(str)
  return trackDB.setStringValue(track["name"], str)
end

-- Race Functions

function createRace(raceID)
  local err = ''
  if trackKey == "" or trackKey == nil then
  err = 'Could not create race: No track set, use the "setTrack" command. '
  end
  if raceEventName == "" or raceEventName == nil then
  err = err..'Could not create race: No race event set, use the "setRaceEvent" command.'
  end
  if err ~= '' then
  return errorPrint(err)
  else
  if raceDB.hasKey(raceID) == 0 then
    local race = {raceEventName = raceID, trackKey = trackKey, status = "pending", racers = {}}
    raceDB.setStringValue(raceID, json.encode(race))
    system.print('Created new race: "'..raceID..'" on track: "'..trackKey..'"')
  else
    -- if the race hasnt started, update the track key
    local race = getRace(raceID)
    if race["status"] == "pending" then
      race["trackKey"] = trackKey
      raceDB.setStringValue(raceID, json.encode(race))
    end
  end
  end
end

function getRace(raceID)
  local race = raceDB.getStringValue(raceID)
  if race ~= nil then
  race = json.decode(race)
  return race
  end
  return nil
end

-- Receive Time
function setTime(timesJSON)

  local data = json.decode(timesJSON)
  if data == '' then
    -- The ship is sending invalid data so tell it to stop sending
    -- TODO: Update this to send an error to the vehicle so it can be checked
    queueMessage(data['racer'] .. '-data-received', 'Received data')
    return false
  end

  queueMessage(data['racer'] .. '-data-received', 'Received data')

  local race = getRace(data["raceEventName"])
  if not race then
    -- TODO: isn't this kind of an error we need to handle as well? I think in this case a ship assumes it's in a race that does not exist?
    return false 
  end

  if race["status"] == "ended" then
    --This would occur if a race is manually ended before the last player crosses finish line
    --This stops data being submitted to races after they are completed
    return false 
  end

  for key, value in pairs(race["racers"]) do
    if value["racer"] == data["racer"] then
      -- The racer exists on the board already if DQF, just no time is assigned to them
      if race["racers"][key]["time"] ~= "DQF" then
        race["racers"][key]["time"] = data["finalTime"]
        raceDB.setStringValue(data["raceEventName"], json.encode(race))
        checkRankedTime(data["finalTime"], race["trackKey"], data["racer"], data["raceEventName"])
        buildRaceStatScreen()
      end
    end
  end
end

-- Check ranked time
function checkRankedTime(time, track, racer, raceID)
  system.print("Checking: " .. time .. ", " .. track .. ", " .. racer .. ", " .. raceID)
  -- Check top 10 times for this race, if faster then slot in position
  -- looks like easiest way is to add to array then sort and keep top 10
  -- Refresh race screen
end

-- Start race
function startRace()
  -- Emits a message to prepare, then emits a GO signal 3 seconds later
  -- Can control traffic lights
  local race = getRace(raceEventName)
  if race == nil then
    system.print("ERROR: No race found with this name: "..raceEventName..'"')
    return false
  end
  race["status"] = "started"
  -- save the race
  raceDB.setStringValue(raceEventName, json.encode(race))
  -- start the race
  system.print('Race "'..raceEventName..'" started.')
  emitter.send(raceEventName, 'start')
end

-- Register Racer
function registerRacer(registerJSON)
  -- Adds the playerId to the active race
  -- emits the track data
  local data = json.decode(registerJSON)
  local race = getRace(data["raceEventName"])
  if race == nil then
    return false
  end

  if race["status"] == "ended" then
    -- The race has ended
    return false
  end

  -- add player if he doesnt exist, use IDs for future name changes
  local racerExists = false
  for key, value in ipairs(race["racers"]) do
    if value["racer"] == data["racer"] then
      racerExists = true
    end
  end

  if racerExists == false then
    local racer = data["racer"]
    table.insert(race["racers"], {racer = racer, time = 0, name = system.getPlayerName(data["racer"])})
    raceDB.setStringValue(data["raceEventName"], json.encode(race))
    system.print("New racer registered")
    -- update screen
    buildRaceStatScreen()
  else
    system.print("Racer already registered")
  end

  -- Emit the track data here, it allows a reset of the board to refetch the data on vehicle
  local trackJSON = json.encode(activeTrack)
  splitBroadcast("register-save-track", data["racer"] .. "-splitmsg", trackJSON)
end

-- Race Stats Screen

-- Build current race screen
function buildRaceStatScreen() -- Sets the screen up showing the registered racers in a list and their times in order (if set)
  local race = getRace(raceEventName)
  if race == nil then
  return errorPrint('Screen info can not be build while there is no active race.')
  end
  local sortedKeys = getKeysSortedByValue(
  race["racers"],
  function(a, b)
    return tonumber(a["time"]) ~= nil and tonumber(a["time"]) < tonumber(b["time"]) and tonumber(a["time"]) > 0
  end
  )
  
  local tableItems = ''
  local pos = 1

  for _, key in ipairs(sortedKeys) do
  if race["racers"][key]["time"] > 0 then 
    tableItems = tableItems ..
    [[<tr>
      <td>]]..pos..[[</td>
      <td>]]..race["racers"][key]["name"]..[[</td>
      <td>]]..formatTime(race["racers"][key]["time"])..[[</td>
    </tr>]]
    pos = pos + 1
  end
  end
  local html = [[
  <style> 
    body { background: #000 url(assets.prod.novaquark.com/100694/8f81cc10-5f12-4f17-84db-314fbdb7c186.jpg) center center no-repeat; background-size: cover; color: #a1ecfb !important; }
    #wrapper { padding: 2vw; width: 100vw; height: 100vh; margin: 0; background-color: rgba(2,17,20,0.65); }
    #header { height: calc(10vh - 1vw); width: 98vw; }
    h1 { font-size: 4vw !important; width: 100%; text-align: center; text-shadow: 0 0 4px rgba(161,236,251,0.65); text-transform: uppercase; color: #a1ecfb !important; }
    #content { height: 85vh; width: 98vw; }
    table { margin-top: 1vh; width: 100%; }
    table th { display: none; padding: 1vh 3vh; font-size: 4vw; text-align: center; background-color: rgb(227, 68, 57); }
    table th:first-child { border-top-left-radius: 20px; }
    table td { font-size: 1.5vw; padding: 3vh; text-align: center; color: #a1ecfb !important; display: inline-block; }
    table tbody tr { margin: 1vh 0; display: block; background-color: rgba(2,17,20,0.65); width: calc(100% - 2vh); border: 1px solid rgb(2, 157, 187); }
    table tbody tr:first-child { box-shadow: 0 0 8px rgba(161,236,251,0.65); }
    table tbody tr td:nth-child(1){ width: calc(10% - 6vh); }
    table tbody tr td:nth-child(2){ width: calc(70% - 6vh); }
    table tbody tr td:nth-child(3){ width: calc(10% - 6vh); }
    table tbody tr:first-child td { font-size: 3vw; }
    table tbody tr:nth-child(2) td { font-size: 2.5vw; }
    table tbody tr:nth-child(3) td { font-size: 2vw; }
    #footer { height: calc(5vh - 1vw); width: 98vw; }
    #footer p { text-align: right; font-size: 1.5vw; margin: 0; padding: 0; position: absolute; right: 2vw; bottom: 2vh; }
  </style>
  <div id="wrapper">
    <div id="header">
    <h1>^]]..trackName ..[[</h1>
    </div>
    <div id="content">
    <table>
      <thead>
      <tr>
        <th>Pos</th>
        <th>Racer</th>
        <th>Time</th>
      </tr>
      </thead>
      <tbody>]]
      ..tableItems ..
      [[</tbody>
    </table>
    </div>
    <div id="footer">
    <p>du-racing - version]]..version ..[[</p>
    </div>
  </div>]]

  if screen then 
  screen.setHTML(html)
  end
  if screen1 then
  screen1.setHTML(html)
  end
end

function errorPrint(msg)
  return msg and system.print('ERROR: '..tostring(msg)) or system.print('ERROR: Nil value handed to error print, could not print error.')
end

-- On start
function onStart() 
  local startError
  system.print('-==:: DU Racing System Online ::==-')  
  system.print('Active Race Event Name: ' .. raceEventName)
  system.print('Active Track: ' .. trackKey)
  system.print('Type "help" to get a list of commands.')

  if trackKey ~= nil and trackKey ~= "" then
    local trackJson = trackDB.getStringValue(trackKey)
    activeTrack = json.decode(trackJson)
    trackName = activeTrack["name"]
  else 
    startError = 'No active track has been set, type "set track your-track-here" to set one. '
  end

  if raceEventName ~= nil and raceEventName ~= "" then
    createRace(raceEventName)
  else
    startError = startError .. 'No raceEventName set, type "set raceEventName your-name-here" to set one'
  end

  if startError then
    system.print(startError)
  end

  -- Update race screen
  buildRaceStatScreen()
end

onStart()

