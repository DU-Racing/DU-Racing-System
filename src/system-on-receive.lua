-- Lua 5.1+ base64 v3.0 (c) 2009 by Alex Kloss <alexthkloss@web.de>
-- licensed under the terms of the LGPL2


--
--!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
--WITH LATEST CHANGES THE CHANNEL ISN'T DYNAMIC!  WE MUST PASS THAT INFO VIA JSON OBJ
--!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
local myDebug = true

message = message:gsub('|', '\\"')

function mysplit (inputstr, sep)
        if sep == nil then
                sep = '%s'
        end
        local t={}
        for str in string.gmatch(inputstr, '([^'..sep..']+)') do
                table.insert(t, str)
        end
        return t
end

split  = mysplit(message, '\\@')
channel = split[1]
message = split[2]

if myDebug then system.print('System received: "'..message..'" on channel: "'..channel..'"') end

if message ~= 'DUR-system-received' then --we don't want to try act on our own confirmation
  if channel == MSG.lastSendChannel and message == 'DUR-vehicle-received' then
    debugPrint('System. Unqueue message, it was received.  Remaining in queue: '..tostring(MSG.getQueueCount()))
    MSG:unqueueMessage()
    
  --elseif channel == MSG.lastReceived.channel and message == MSG.lastReceived.msg then
  --  MSG:confirmReceive(channel)

  elseif channel == "fdu-centralsplit" then
    MSG:confirmReceive(channel)
    debugPrint('Before decode'..message)
    local part = json.decode(message) --decode the full wrapper
    if part == nil then
      system.print("Invalid message: " .. message)
      return false
    end
    table.insert(messageParts, {index = part["i"], content = part["content"]})
    if part["i"] == part["msgPartsCount"] then
      local fullMessage = getCompleteMessage()

      --if part["action"] == "save-track" then
        createTrack(fullMessage)
      --end
    end

  elseif channel == raceEventName .. "-register" then
    MSG:confirmReceive(channel)
    registerRacer(message)

  elseif channel == raceEventName .. "-finish" then
    MSG:confirmReceive(channel)
    setTime(message)

  elseif channel == "fdu-addtrack" then
    MSG:confirmReceive(channel)
    createTrack(message)
  else
    debugPrint('Channel is: '..channel)
  end

  MSG.lastReceived = {channel=channel,msg=message}
end

