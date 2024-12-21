local lex = require("libs.BlueMoonJune.lex")
local function split(str, on)
  on = on or " "
  local result = {}
  local delimiter = on:gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1")
  for match in (str .. on):gmatch("(.-)" .. delimiter) do
    result[#result+1] = match
  end
  return result
end

return {
  guestTransform = function(p)
    for k in p.scripts:entries() do
      if k:match("^scripts.host") or k:match("GNUI") or k:match("^tools") then
        p.scripts[k] = nil
      end
    end
    
    return p
  end,
  hostTransform = function(p)
    for k in p.scripts:entries() do
      if k:match("^scripts.guest") then
        p.scripts[k] = nil
      end
    end
    
    return p
  end,
}

