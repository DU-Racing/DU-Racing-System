--DU RACING v1.0 created by rexsilex, NinjaFox and cAIRLs

-- Screen receiver system and stats display
-- Official races require a race adjudicator that mans this board
-- Params

-- Race ID (Sets the active race ID used to receive and store stats, auto in future
local myDebug = true


function debugPrint(msg)
  if(myDebug) then
    system.print('System--  '..msg)
  end
end

raceEventName = raceDB.getStringValue('activeRaceID') or 'No event set.'
trackKey = raceDB.getStringValue('activeTrackID')
activeTrack = nil
trackName = 'No track set.' -- Set from the databank when looking up track key
messageParts = {}
consumerStarted = false
myDebug = true
masterId = unit.getMasterPlayerId()

-- Do not adjust version
version = '1.0'

function customEncode(data)
  local encodedData = json.encode(data)
  debugPrint('JSON Encoded Data: '..tostring(encodedData))
  return encodedData
end
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
        local trackJson = trackDB.getStringValue(trackKey)
        activeTrack = json.decode(trackJson)
        trackName = activeTrack["name"]
        createRace(raceEventName)
        buildRaceStatScreen()
        system.print('Track has been set.')
      else
        errorPrint('Could not set track. No such track name stored: "'..trackKey..'".')
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
      MSG:queueMessage(raceEventName,'start')
    end,

    endRace = function() -- Marks the race as complete, no more times will be accepted and the race is archived.
      local race = getRace(raceEventName)
      if race == nil then
        return errorPrint('No race event created that could end.')
      end
      race["status"] = 'ended'
      raceDB.setStringValue(raceEventName, json.encode(race)) -- save the race data
      MSG:queueMessage(raceEventName,'end')
      system.print('Race "'..raceEventName..'" has ended. No further time submissions are taken.')
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
      system.print('Registered racers for "'..raceEventName..'": ' .. racers)
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
      errorPrint('Could not disqualify racer "'..dqf..'". No racer with this name in the race event.')
    end,

    -- Set race id
    setRaceEvent = function(newRaceEventName)
      raceEventName = newRaceEventName
      raceDB.setStringValue('activeRaceID', newRaceEventName)
      createRace(newRaceEventName)
      buildRaceStatScreen()
    end,

    -- List all saved race keys
    listTracks = function()
      local keys = json.decode(trackDB.getKeys())
      local out
      for key, value in pairs(keys) do
        if value ~= "activeRaceID" and value ~= "activeTrackID" then
          out = out == nil and 'Saved tracks: '..value or out..', '..value
        end
      end
      if out ~= nil then
        system.print(out)
      else
        system.print('No tracks saved.')
      end
    end,
    
    --NEEDED: list all events

    -- export race, hidden function
    exportRaceEvent = function(exportKey)
      local raceExport = raceDB.getStringValue(exportKey)
      if screen then
        screen.setHTML(raceExport)
        system.print('The race has been exported to the screen HTML content.')
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
    errorPrint('Following command could not be executed: "'..text..'".')
  end
end

MSG = {
  queue = {},
  lastSendChannel = '',
  lastReceived = {channel='',msg=''},
  
  queueMessage = function(self, channel, message)
    table.insert(MSG.queue, {channel = channel, message = message}) --, time = system.getTime()})
    if not consumerStarted then
      MSG:consumeQueue() --we can send the first msg instantly.
      unit.setTimer('consumeMsgQueue', 1)
      consumerStarted = true
    end
  end,
  
  getQueueCount = function()
    local count = 0
    for _ in pairs(MSG.queue) do count = count+1 end
    return count
  end,

  consumeQueue = function()
    -- local sortedMessages = getKeysSortedByValue(
      -- MSG.queue,
      -- function(a, b)
        -- return a['time'] < b['time']
      -- end)
    -- for _, key in ipairs(sortedMessages) do
      --emitter.send(MSG.queue[key]['channel'], MSG.queue[key]['message'])
      emitter.broadcast(MSG.queue[1]['channel']..'@'..MSG.queue[1]['message'])
      MSG.lastSendChannel = MSG.queue[1]['channel']
      MSG.unqueueMessage(key)
    --end    
  end,
  
  -- unqueueMessage = function(key)
    -- table.remove(MSG.queue, key)
    -- local count = 0
    -- for _ in pairs(MSG.queue) do count = count + 1 end
    -- if count == 0 then 
      -- unit.stopTimer('consumeMsgQueue')
      -- consumerStarted = false
    -- end
  -- end,
  
  unqueueMessage = function()
    local function checkQueueEmpty()
      if #MSG.queue == 0 then
        unit.stopTimer('consumeMsgQueue')
        consumerStarted = false
        return true
      else
        return false
      end
    end
    
    if checkQueueEmpty() == false then
      table.remove(MSG.queue, 1)
      checkQueueEmpty()
    end
  end,

	send = function(self, channel, data)

    local function split(str, maxLength)
      local splitParts = {}
      local strLength = str:len()

      local splitCount = math.ceil(strLength / maxLength)
      local remainingSplitsCount = splitCount
      local startPos = 1
      local endPos = maxLength
      while remainingSplitsCount > 0 do
        table.insert(splitParts, string.sub(str, startPos, endPos))
        startPos = endPos + 1
        endPos = endPos + maxLength > strLength and strLength or endPos + maxLength
        remainingSplitsCount = remainingSplitsCount - 1
      end
      return splitParts, splitCount
    end

    local index = 1
    local dataParts, dataPartsCount = split(data, 250)
    for lineId, dataContent in ipairs(dataParts) do
      local sendContent = customEncode({i = index, msgPartsCount = dataPartsCount, content = dataContent})
      MSG:queueMessage(channel, sendContent)
      index = index + 1
    end
	end,
  
  confirmReceive = function(self,channel)
    MSG:queueMessage(channel,'DUR-system-received')
  end
}


function getCompleteMessage()
  -- local sorted =
    -- getKeysSortedByValue(
    -- messageParts,
    -- function(a, b)
      -- return a['index'] < b['index']
    -- end
  -- )
  local assembeledMessage = ''
  --for order,key in ipairs(sorted) do
  for key in ipairs(messageParts) do
    assembeledMessage = assembeledMessage .. messageParts[key]['content']
  end
  return assembeledMessage
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
    num = tonumber(num)
    return num < 10 and '0' .. num or num
  end

  local function modulus(a, b)
  return a - math.floor(a / b) * b
  end

  local hours = math.floor(seconds / 3600)
  seconds = modulus(seconds, 3600)
  local minutes = math.floor(seconds / 60)
  seconds = modulus(seconds, 60)

  return leadingZero(hours) .. ':' .. leadingZero(minutes) .. ':' .. leadingZero(string.format("%.3f", seconds))
end

function createTrack(str)
  local track = json.decode(str)
  trackDB.setStringValue(track["name"], str)
end

-- Race Functions

function createRace(raceID)
  local err = ''
  if trackKey == '' or trackKey == nil then
    err = 'Could not create race: No track set, use the "setTrack" command. '
  end
  if raceEventName == '' or raceEventName == nil then
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
    --queueMessage(data['racer'] .. '-data-received', 'Received data')
    return false
  end

  --queueMessage(data['racer'] .. '-data-received', 'Received data')

  local race = getRace(data["raceEventName"])
  if not race then
    -- TODO: isn't this kind of an error we need to handle as well? I think in this case a ship assumes it's in a race that does not exist?
    return false 
  end

  if race["status"] == "ended" then
    --This would occur if a race is manually ended before the last player crosses finish line
    --This stops data being submitted to races after they are completed
    errorPrint('Racer "'..system.getPlayerName(data["racer"])..'" tried submitting a time after the race already ended. Time has not been added.')
    return false 
  end

  for key, value in pairs(race["racers"]) do
    if value["racer"] == data["racer"] then
      -- The racer exists on the board already if DQF, just no time is assigned to them
      if race["racers"][key]["time"] ~= "DQF" then
        race["racers"][key]["time"] = data["finalTime"]
        raceDB.setStringValue(data["raceEventName"], json.encode(race))
        --checkRankedTime(data["finalTime"], race["trackKey"], data["racer"], data["raceEventName"])
      end
    end
  end
  buildRaceStatScreen()
end

-- Check ranked time
--function checkRankedTime(time, track, racer, raceID)
  --system.print("Checking: " .. time .. ", " .. track .. ", " .. racer .. ", " .. raceID)
  -- Check top 10 times for this race, if faster then slot in position
  -- looks like easiest way is to add to array then sort and keep top 10
  -- Refresh race screen
--end

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
  MSG:queueMessage(raceEventName, 'start')
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
    system.print('New racer registered.')
  else
    system.print('Racer already registered.')
  end
  buildRaceStatScreen()

  -- Emit the track data here, it allows a reset of the board to refetch the data on vehicle
  local trackJSON = json.encode(activeTrack)
  
   Print('Sending track JSON: '..trackJSON)
  MSG:send(data["racer"] .. "-splitmsg", trackJSON) --registers and saves track
end

-- Race Stats Screen

-- Build current race screen
function buildRaceStatScreen() -- Sets the screen up showing the registered racers in a list and their times in order (if set)
  local race = getRace(raceEventName)
  local tableItems = ''
  if race then
  --  return errorPrint('Screen info can not be build while there is no active race.')
  --end
    local sortedKeys = getKeysSortedByValue(
    race["racers"],
    function(a, b)
      return tonumber(a["time"]) ~= nil and tonumber(a["time"]) > 0 and tonumber(a["time"]) < tonumber(b["time"])
    end
    )
    
    local pos = 1

    for _, key in ipairs(sortedKeys) do
      local racerTime
      if race["racers"][key]["time"] > 0 then
        racerTime = formatTime(race["racers"][key]["time"])
      else
        racerTime = '---'
      end
        tableItems = tableItems ..
        [[<tr>
          <td>]]..pos..[[</td>
          <td>]]..race["racers"][key]["name"]..[[</td>
          <td>]]..racerTime..[[</td>
        </tr>]]
        pos = pos + 1
      --end
    end
  end
  local html = [[
    <style> 
      body { background: #000 url(assets.prod.novaquark.com/100694/8f81cc10-5f12-4f17-84db-314fbdb7c186.jpg) center center no-repeat; background-size: cover; color: #a1ecfb !important; }
      #wrapper { padding: 2vw; width: 100vw; height: 100vh; margin: 0; background-color: rgba(2,17,20,0.65); }
      #header { height: calc(10vh - 1vw); width: 98vw; }
      h1 { font-size: 3.5vw !important; width: 100%; text-align: center; text-shadow: 0 0 4px rgba(161,236,251,0.65); text-transform: uppercase; color: #a1ecfb !important; }
      #content { height: 85vh; width: 98vw; }
      table { margin-top: 1vh; width: 100%; }
      table th { display: none; padding: 1vh 3vh; font-size: 4vw; text-align: center; background-color: rgb(227, 68, 57); }
      table th:first-child { border-top-left-radius: 20px; }
      table td { font-size: 1.5vw; padding: 3vh; color: #a1ecfb !important; display: inline-block; }
      table tbody tr { margin: 1vh 0; display: block; background-color: rgba(2,17,20,0.65); width: calc(100% - 2vh); border: 1px solid rgb(2, 157, 187); }
      table tbody tr:first-child { box-shadow: 0 0 8px rgba(161,236,251,0.65); }
      table tbody tr td:nth-child(1){ width: calc(15% - 3vw); }
      table tbody tr td:nth-child(2){ width: calc(55% - 3vw); }
      table tbody tr td:nth-child(3){ width: calc(20% - 4vw); }
      table tbody tr:first-child td { font-size: 3vw; }
      table tbody tr:nth-child(2) td { font-size: 2.5vw; }
      table tbody tr:nth-child(3) td { font-size: 2vw; }
      #footer { height: calc(5vh - 1vw); width: 98vw; }
      #footer p { text-align: right; font-size: 1.5vw; margin: 0; padding: 0; position: absolute; right: 2vw; bottom: 2vh; }
    </style>
    <div id="wrapper">
      <div id="header">
      <h1>]]..raceEventName..' @ '..trackName ..[[</h1>
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
  return msg and system.print('ERROR: '..tostring(msg))
end

-- On start
function onStart() 
  local startError = ''
  system.print('-==:: DU Racing System Online ::==-')  
  system.print('Active Race Event Name: ' .. raceEventName)
  system.print('Active Track: ' .. trackKey)
  system.print('Type "help" to get a list of commands.')


  if trackKey ~= nil and trackKey ~= '' then
    local trackJson = trackDB.getStringValue(trackKey)
    debugPrint(trackJson)
    activeTrack = json.decode(trackJson)
    debugPrint('Active track data: '..tostring(activeTrack))
    if activeTrack ~= nil then
      trackName = activeTrack["name"]
    else
      system.print("Track name not loaded due to error, see next output.")
    end 
  else 
    startError = 'No active track has been set, type "setTrack(Track name here)" to set a track. '
  end

  if raceEventName ~= nil and raceEventName ~= '' and raceEventName ~= 'No event set.' then
    createRace(raceEventName)
  else
    startError = startError .. 'No race event name set, type "setRaceEvent(your Race Name here)" to create an event.'
  end

  if startError ~= '' then
    system.print(startError)
  end

  -- Update race screen
  buildRaceStatScreen()
  unit.setTimer('slowUpdate',0.5)
end

onStart()




