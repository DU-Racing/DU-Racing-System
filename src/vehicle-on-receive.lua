-- character table string
local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'




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

if myDebug then system.print('Vehicle received: "'..message..'" on channel: "'..channel..'"') end

local function splitMsgAssembly(msgPart)
  debugPrint('SplitMsgAssembly')
  mess = msgPart
  debugPrint(mess)
  local part = json.decode(mess)
  debugPrint('Part received ('..part['i']..'/'..part['msgPartsCount'].. ') :'..mess)
  if part == nil then
    system.print("Invalid message: " .. mess)
    return nil
  end
  table.insert(messageParts, {index = part["i"], content = part["content"]})
  if part["i"] == part['msgPartsCount'] then
    local fullMessage = getCompleteMessage()
    messageParts = {} --reset global for next message
    if myDebug then system.print('Vehicle assemebeled message: "'..json.encode(fullMessage)..'"') end
    return fullMessage
  else
    return false
  end
end

if message ~= 'DUR-vehicle-received' then --we don't want to try act on our own confirmation
  if channel == MSG.lastSendChannel and message == 'DUR-system-received' then
    MSG:unqueueMessage()
    debugPrint('Vehicle Unqueuing message.')
  --elseif channel == MSG.lastReceived.channel and message == MSG.lastReceived.msg then
  --  MSG:confirmReceive(channel)

  elseif channel == masterId .. "-splitmsg" then
    MSG:confirmReceive(channel)
    debugPrint('Received split')
    local assembeledMessage = splitMsgAssembly(message)
    if assembeledMessage then
      --[[if part["action"] == "save-track" then
        saveBroadcastedTrack(fullMessage)
      end]]
      --if part["action"] == "register-save-track" then
        debugPrint('Saving broadcasted Track')
        saveBroadcastedTrack(assembeledMessage)

        --if registered then
        --  registerConfirm()
        --end
      --end
    else
      return false
    end

  elseif channel == raceEventName then
    MSG:confirmReceive(channel)
    if message == "start" then
      startCountdown()
    end

  elseif channel == masterId .. "-registered" then
    MSG:confirmReceive(channel)
    debugPrint('Registered.')
    saveBroadcastedTrack(message)
  end

  MSG.lastReceived = {channel=channel,msg=message}
end
