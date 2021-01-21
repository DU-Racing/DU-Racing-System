local uid = unit.getMasterPlayerId()

if channel == uid .. "-splitmsg" or channel == "dur-splitmsg" then
    mess = string.gsub(message, '|', '\\"')
    local part = json.decode(mess)
    if part == nil then
        system.print("Invalid message: " .. mess)
        return false
    end
    table.insert(messageParts, { index = part["i"], content = part["content"]})
    if part["i"] == part["len"] then 
       local fullMessage = getCompleteMessage()

        if part["action"] == "save-track" then
          saveBroadcastedTrack(fullMessage)
        end
    end
end

if channel == raceID then
   if message == "start" then
      startRace()  
   end
end

if channel == uid .. "-registered" then
   saveBroadcastedTrack(message)
end


