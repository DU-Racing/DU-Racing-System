if myDebug then system.print('Vehicle received: "'..message..'" on channel: "'..channel..'"') end

local function splitMsgAssembly(msgPart)
  mess = string.gsub(msgPart, "|", '\\"')
  local part = json.decode(mess)
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

  elseif channel == masterId .. "-splitmsg" then
    MSG:confirmReceive(channel)
    local assembeledMessage = splitMsgAssembly(message)
    if assembeledMessage then
      saveBroadcastedTrack(assembeledMessage)
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
    saveBroadcastedTrack(message)
  end

  MSG.lastReceived = {channel=channel,msg=message}
end
