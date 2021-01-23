if channel == "fdu-centralsplit" then
    mess = string.gsub(message, "|", '\\"')
    local part = json.decode(mess)
    if part == nil then
        system.print("Invalid message: " .. mess)
        return false
    end
    table.insert(messageParts, {index = part["i"], content = part["content"]})
    if part["i"] == part["len"] then
        local fullMessage = getCompleteMessage()

        if part["action"] == "save-track" then
            createTrack(fullMessage)
        end
    end
end

if channel == "fdu-register" then
    registerRacer(message)
end

if channel == "fdu-finish" then
    setTime(message)
end

if channel == "fdu-addtrack" then
    createTrack(message)
end
