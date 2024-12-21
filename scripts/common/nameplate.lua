BunnyPlate = require("libs.TheKillerBunny.BunnyPlate")
if client:getDate().month == 10 then
  BunnyPlate = BunnyPlate(20, vec(225, 134, 64), vec(235, 97, 35))
elseif client:getDate().month == 12 then
  BunnyPlate = BunnyPlate(20, vec(255, 54, 54), vec(54, 255, 54), vec(255, 255, 255))
else
  BunnyPlate = BunnyPlate(20, vec(150, 255, 100), vec(50, 255, 150))
end

BunnyPlate.setText("The Observer")

local smallText = {
  a = "ᴀ",
  b = "ʙ",
  c = "ᴄ",
  d = "ᴅ",
  e = "ᴇ",
  f = "ғ",
  g = "ɢ",
  h = "ʜ",
  i = "ɪ",
  j = "ᴊ",
  k = "ᴋ",
  l = "ʟ",
  m = "ᴍ",
  n = "ɴ",
  o = "ᴏ",
  p = "ᴘ",
  q = "ǫ",
  r = "ʀ",
  s = "s",
  t = "ᴛ",
  u = "ᴜ",
  v = "ᴠ",
  w = "ᴡ",
  x = "x",
  y = "ʏ",
  z = "ᴢ",
  ["1"] = "₁",
  ["2"] = "₂",
  ["3"] = "₃",
  ["4"] = "₄",
  ["5"] = "₅",
  ["6"] = "₆",
  ["7"] = "₇",
  ["8"] = "₈",
  ["9"] = "₉",
  ["0"] = "₀"
}

local function splitStr(str, on)
    on = on or " "
    local result = {}
    local delimiter = on:gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1")
    for match in (str .. on):gmatch("(.-)" .. delimiter) do
        result[#result+1] = match
    end
    return result
end

local function short(...)
  local compose = {}

  local width = client.getTextWidth
  local maxWidth = 0

  for _, v in pairs({...}) do
    local split = splitStr(v, "|")
    local key, value = split[1], split[2]

    value = string.lower(value):gsub("[a-z0-9]", smallText)
    maxWidth = (width(value) > maxWidth) and width(value) or maxWidth
  end

  local title = ("information or smthn idk"):gsub("[a-z0-9]", smallText)
  local totalMaxWidth = 100 + maxWidth
  local beginnerSpaces = ((totalMaxWidth / 2) / width(" ")) - (width(title) / width(" ") / 2)
  local extraPixels = (beginnerSpaces - math.floor(beginnerSpaces))

  table.insert(compose, {
    text = (" "):rep(math.floor(beginnerSpaces))
  })
  table.insert(compose, {
    text = ("|"):rep(math.clamp(math.floor(extraPixels), 0, 10)),
    font = "uniform"
  })
  table.insert(compose, {
    text = title,
    color = "green"
  })
  table.insert(compose, {
    text = ("|"):rep(math.clamp(math.floor(extraPixels), 0, 10)),
    font = "uniform"
  })
  table.insert(compose, {
    text = (" "):rep(math.floor(beginnerSpaces))
  })

  for _, text in pairs({...}) do
    local split = splitStr(text, "|")
    local key, value = split[1], split[2]

    key = "\n" .. string.lower(key):gsub("[a-z0-9]", smallText)
    value = string.lower(value):gsub("[a-z0-9]", smallText)

    local neededWidth = ((100 - width(key)) + (maxWidth - width(value))) / width(" ")
    local spaceCount = math.floor(neededWidth)
    local extraWidth = (neededWidth - spaceCount) * width(" ")

    table.insert(compose, {
      text = key,
      color = "gray"
    })
    table.insert(compose, {
      text = (" "):rep(spaceCount),
    })
    table.insert(compose, {
      text = ("|"):rep(extraWidth),
      font = "uniform",
      color = "black"
    })
    table.insert(compose, {
      text = value,
      color = "gold"
    })
  end

  return compose
end

BunnyPlate.setHoverJson(short(
"Skull Docs|tkbunny.net/skulldocs",
"Pronouns|he/him",
"Discord|@thekillerbunny"
))

nameplate.ENTITY
  :setOutline(true)
  :setOutlineColor(0, 0, 0)
  :setBackgroundColor(0, 0, 0, 0)

