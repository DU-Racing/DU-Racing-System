-- Lua 5.1+ base64 v3.0 (c) 2009 by Alex Kloss <alexthkloss@web.de>
-- licensed under the terms of the LGPL2


--
--!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
--WITH LATEST CHANGES THE CHANNEL ISN'T DYNAMIC!  WE MUST PASS THAT INFO VIA JSON OBJ
--!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!


-- character table string
local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
local myDebug=true
-- encoding
function enc(data)
    return ((data:gsub('.', function(x) 
        local r,b='',x:byte()
        for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
        return r;
    end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
        if (#x < 6) then return '' end
        local c=0
        for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
        return b:sub(c+1,c+1)
    end)..({ '', '==', '=' })[#data%3+1])
end

-- decoding
function dec(data)
    data = string.gsub(data, '[^'..b..'=]', '')
    return (data:gsub('.', function(x)
        if (x == '=') then return '' end
        local r,f='',(b:find(x)-1)
        for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
        return r;
    end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
        if (#x ~= 8) then return '' end
        local c=0
        for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
        return string.char(c)
    end))
end


if myDebug then system.print('System received: "'..message..'" on channel: "'..channel..'"') end

if message ~= 'DUR-system-received' then --we don't want to try act on our own confirmation
  if channel == MSG.lastSendChannel and message == 'DUR-vehicle-received' then
    MSG:unqueueMessage()
    
  --elseif channel == MSG.lastReceived.channel and message == MSG.lastReceived.msg then
  --  MSG:confirmReceive(channel)

  elseif channel == "fdu-centralsplit" then
    MSG:confirmReceive(channel)

    local part = json.decode(dec(message))
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
