-- Screen receiver system and stats display
-- Official races require a race adjudicator that mans this board


-- Params

    -- Race ID (Sets the active race ID used to receive and store stats, auto in future
    raceID = raceDB.getStringValue("activeRaceID")
    trackKey = raceDB.getStringValue("activeTrackID")
    activeTrack = nil
    trackName = "" -- Set from the databank when looking up track key

-- Do not adjust version
version = "1.0"

-- Text controller
function handleTextCommandInput(text) 
    system.print("Command: " .. text)
    -- Help
    if text == "help" then 
        -- Outputs all commands with a description
        system.print("-==:: DU Racing Command Help ::==-")
        system.print('"list racers" - lists out all registered racers for this race')
        system.print('"disqualify racer RacerName" - disqualifies RacerName from this race')
        system.print('"start race {ALT+1}" - starts the race and broadcasts start signal to racers')
        system.print('"end race {ALT+2}" - closes all further time submissions to this race')
        system.print('"set track track-name" - sets the active track name')
        system.print('"set key your-race-key" - sets the active race key for the system')
        system.print('"list races" - lists all stored race keys')
        system.print('"list tracks" - lists all stored track keys')
        return true
    end

    -- Start Race
    if text == "start race" then        
        return startRace() 
    end

      -- End Race
      if text == "end race" then 
        return endRace()
    end

    -- List racers
    if text == "list racers" then 
        local race = getRace(raceID)
        if race == nil then
            system.print("ERROR: No race found with this ID")
            return false
        end
        local racers = "";
        for key, value in pairs(race["racers"]) do
            racers = racers .. race["racers"][key]["name"] .. ", "
        end
        return system.print("Registered racers: " .. racers)
    end

    -- Disqualify racer
    if text:find("disqualify racer ") then
        local dqf = string.gsub(text, "disqualify racer ", "")
        local race = getRace(raceID)
        if race == nil then
            system.print("ERROR: No race found with this ID")
            return false
        end
        local racers = "";
        for key, value in pairs(race["racers"]) do
            if race["racers"][key]["name"] == dqf then
                race["racers"][key]["time"] = "DQF"
                raceDB.setStringValue(raceID, json.encode(race))
                return system.print(dqf .. " has been disqualified") 
            end
        end
        return system.print(dqf .. " was not found") 
    end

    -- Set race id
    if text:find("set key ") then
        raceID = string.gsub(text, "set key ", "")
        raceDB.setStringValue("activeRaceID", raceID)
        buildRaceStatScreen()
        return createRace(raceID)
    end

    -- List all saved race keys
    if text == "list races" then 
        local keys = json.decode(raceDB.getKeys())
        local out = ""
        for key, value in pairs(keys) do
            if value ~= "activeRaceID" and value ~= "activeTrackKey" then 
                out = value .. ", " .. out
            end
          end
        return system.print(out)
    end

    -- export race
    if text:find("export race ") then
        local exportKey = string.gsub(text, "export race ", "")
        local raceExport = raceDB.getStringValue(exportKey)
        screen.setHTML(raceExport)
        return system.print("The race has been exported to the screen HTML content")
    end

    -- Set track
    if text:find("set track ") then
        trackKey = string.gsub(text, "set track ", "")
        -- TODO CHECK THIS TRACK EXISTS
        raceDB.setStringValue("activeTrackID", trackKey)
        system.print("Track key has been set")
        buildRaceStatScreen()
        return createRace(raceID)
    end

    -- list saved tracks
    if text == "list tracks" then 
        local keys = json.decode(trackDB.getKeys())
        local out = ""
        for key, value in pairs(keys) do
            if value ~= "activeRaceID" and value ~= "activeTrackKey" then 
                out = value .. ", " .. out
            end
          end
        return system.print(out)
    end

    system.print("SYSTEM: I Can't... " .. text)
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

function createTrack(str)
    local track = json.decode(str)
    return trackDB.setStringValue(track["name"], str)
end

-- Race Functions

    function createRace(raceID)
        if trackKey == "" or trackKey == nil then 
            return system.print("ERROR: No track set, use the 'set track' command")
        end
        if raceDB.hasKey(raceID) == 0 then 
            local race = {raceID = raceID, trackKey = trackKey, status = "pending", racers = {}}
            raceDB.setStringValue(raceID , json.encode(race))
            system.print("Created new race")
        else
            -- if the race hasnt started, update the track key
            local race = getRace(raceID)
            if race["status"] == "pending" then
                race["trackKey"] = trackKey
                raceDB.setStringValue(raceID , json.encode(race))
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
        -- Receives the time from the ship and stores in the db for this race
        -- Emits a confirmation message that the message was received, this stops the ship sending it
        local data = json.decode(timesJSON)

        -- get the race from the db from the raceID passed
        local race = getRace(data["raceID"])
        if race == nil then 
            return false
        end

        if race["status"] == "ended" then
            -- The race has ended
            return false
        end

        -- parse and set the times for this user (who should have an index already following registration)
        for key, value in pairs(race["racers"]) do
            -- if the current time is not 0 then cheating?
            if value["racer"] == data["racer"] then
                -- Set the time here, record laps are stored on diff db
                --race["racers"][key] = { racer = value["racer"], time = data["lapTime"], name = value["name"] }

                -- Check if this racer is DQF
                if race["racers"][key]["time"]  ~= "DQF" then 
                    race["racers"][key]["time"] = data["lapTime"]
                    raceDB.setStringValue(data["raceID"], json.encode(race))
                    checkRankedTime(data["lapTime"], race["trackKey"], data["racer"], data["raceID"])
                end
            end
        end    

    end

    -- Check ranked time
    function checkRankedTime(time, track, racer, raceID)
        system.print('Checking: ' .. time .. ', ' .. track .. ', ' .. racer .. ', ' .. raceID)
        -- Check top 10 times for this race, if faster then slot in position
        -- looks like easiest way is to add to array then sort and keep top 10
        -- Refresh race screen
    end


    -- Start race
    function startRace()
        -- Emits a message to prepare, then emits a GO signal 3 seconds later
        -- Can control traffic lights
        local race = getRace(raceID)
        if race == nil then
            system.print("ERROR: No race found with this ID: " .. raceID)
            return false
        end
        race["status"] = "started"
        -- save the race
        raceDB.setStringValue(raceID, json.encode(race))  
        -- start the race
        system.print("Race Started!")
        emitter.send(raceID, "start")
    end

    -- End race
    function endRace()
        -- Marks the race as complete, no more times will be accepted and the race is archived
        local race = getRace(raceID)
        if race == nil then
            system.print("ERROR: No race found with this ID")
            return false
        end
        race["status"] = "ended"
        -- save the rcae
        raceDB.setStringValue(raceID, json.encode(race))
        emitter.send(raceID, "end")
        return system.print("Race has ended")
    end

    -- Register Racer
    function registerRacer(registerJSON)    
        -- Adds the playerId to the active race
        -- emits the track data
        local data = json.decode(registerJSON)
        local race = getRace(data["raceID"])
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
            table.insert(race["racers"], { racer = racer, time = 0, name = system.getPlayerName(data["racer"]) })
            raceDB.setStringValue(data["raceID"], json.encode(race))
            system.print("New racer registered")
            -- update screen
            buildRaceStatScreen()          
        else 
            system.print("Racer already registered")
        end

        -- Emit the track data here, it allows a reset of the board to refetch the data on vehicle
        local trackJSON = json.encode(activeTrack)
        splitBroadcast("save-track", data["racer"] .. "-splitmsg", trackJSON)

    end


-- Race Stats Screen

    -- Build current race screen
    function buildRaceStatScreen()
        -- Sets the screen up showing the registered racers in a list and their times in order (if set)
        local race = getRace(raceID)
        if race == nil then
            return false
        end
        local sortedKeys = getKeysSortedByValue(race["racers"], function(a, b) return tonumber(a["time"]) ~= nil and tonumber(a["time"]) < tonumber(b["time"]) and tonumber(a["time"]) > 0 end )
        local tableItems = ""
        local pos = 1

        for _, key in ipairs(sortedKeys) do
            tableItems = tableItems .. '<tr><td>' .. pos ..'</td><td>' .. race["racers"][key]["name"] .. '</td><td>' .. race["racers"][key]["time"] .. '</td></tr>'
            pos = pos + 1
        end

        screen.setHTML(' <style> body { background: #000 url(assets.prod.novaquark.com/100694/8f81cc10-5f12-4f17-84db-314fbdb7c186.jpg) center center no-repeat; background-size: cover; color: #a1ecfb !important; } #wrapper { padding: 2vw; width: 100vw; height: 100vh; margin: 0; background-color: rgba(2,17,20,0.65); } #header { height: calc(10vh - 1vw); width: 98vw; } h1 { font-size: 4vw !important; width: 100%; text-align: center; text-shadow: 0 0 4px rgba(161,236,251,0.65); text-transform: uppercase; color: #a1ecfb !important; } #content { height: 85vh; width: 98vw; } table { margin-top: 1vh; width: 100%; } table th { display: none; padding: 1vh 3vh; font-size: 4vw; text-align: center; background-color: rgb(227, 68, 57); } table th:first-child { border-top-left-radius: 20px; } table td { font-size: 1.5vw; padding: 3vh; text-align: center; color: #a1ecfb !important; display: inline-block; } table tbody tr { margin: 1vh 0; display: block; background-color: rgba(2,17,20,0.65); width: calc(100% - 2vh); border: 1px solid rgb(2, 157, 187); } table tbody tr:first-child { box-shadow: 0 0 8px rgba(161,236,251,0.65); } table tbody tr td:nth-child(1){ width: calc(10% - 6vh); } table tbody tr td:nth-child(2){ width: calc(70% - 6vh); } table tbody tr td:nth-child(3){ width: calc(10% - 6vh); } table tbody tr:first-child td { font-size: 3vw; } table tbody tr:nth-child(2) td { font-size: 2.5vw; } table tbody tr:nth-child(3) td { font-size: 2vw; } #footer { height: calc(5vh - 1vw); width: 98vw; } #footer p { text-align: right; font-size: 1.5vw; margin: 0; padding: 0; position: absolute; right: 2vw; bottom: 2vh; } </style> <div id="wrapper"> <div id="header"><h1>' .. trackName .. '</h1></div> <div id="content"> <table> <thead> <tr> <th>Pos</th> <th>Racer</th> <th>Time</th> </tr> </thead> <tbody> ' .. tableItems .. ' </tbody> </table> </div> <div id="footer"> <p>du-racing - version ' .. version .. '</p> </div> </div> ')
    end

    -- Build race time stats page
    -- Sets up screen showing the race times for the specified track



-- On start
--raceDB.clear()


system.print("-==:: DU Racing System Online ::==-")
system.print("Active Race Key: " .. raceID)
system.print("Active Track Key: " .. trackKey)

if trackKey ~= nil and trackKey ~= "" then 
  local trackJson = trackDB.getStringValue(trackKey)
  activeTrack = json.decode(trackJson)
  trackName = activeTrack["name"]
end

if raceID ~= nil and raceID ~= "" then
    createRace(raceID)
else
    system.print("SYSTEM: No race ID set, type 'set key your-key-here' to set one")
end

buildRaceStatScreen()

