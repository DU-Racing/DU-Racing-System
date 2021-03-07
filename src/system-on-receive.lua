if myDebug then system.print('System received: "'..message..'" on channel: "'..channel..'"') end

if message ~= 'DUR-system-received' then --we don't want to try act on our own confirmation
  if channel == MSG.lastSendChannel and message == 'DUR-vehicle-received' then
    MSG:unqueueMessage()
    
  --elseif channel == MSG.lastReceived.channel and message == MSG.lastReceived.msg then
  --  MSG:confirmReceive(channel)

  elseif channel == "fdu-centralsplit" then
    MSG:confirmReceive(channel)
    mess = string.gsub(message, "|", '\\"')
    local part = json.decode(mess)
    if part == nil then
      system.print("Invalid message: " .. mess)
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
  end

  MSG.lastReceived = {channel=channel,msg=message}
end
