-- character table string
local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

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

if myDebug then system.print('Vehicle received: "'..message..'" on channel: "'..channel..'"') end

local function splitMsgAssembly(msgPart)
  --mess = string.gsub(msgPart, "|", '\\"')
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
