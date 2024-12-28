--[[
Copyright 2024 TheKillerBunny

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
--]]
local Nebula = require("libs.TheKillerBunny.Nebula")
local TextComponents = require("libs.TheKillerBunny.TextComponents")

for _, v in pairs(models.models:getChildren()) do
   v:remove()
   models:addChild(v)
end

function _G.split(str, on)
    on = on or " "
    local result = {}
    local delimiter = on:gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1")
    for match in (str .. on):gmatch("(.-)" .. delimiter) do
        result[#result+1] = match
    end
    return result
end

for _, v in pairs(listFiles("tests", true)) do
   for _, w in pairs(require(v)) do
      Nebula.add(table.unpack(w))
   end
end

local testStyles = {
   white = TextComponents.newStyle(),
   red = TextComponents.newStyle():setColor("red"),
   green = TextComponents.newStyle():setColor("green")
}

local fails, successes = Nebula.run()
if host:isHost() then
   local compose = TextComponents.newComponent(tostring(#successes), testStyles.green)
   compose:append(TextComponents.newComponent(" test(s) passed; ", testStyles.white))
   compose:append(TextComponents.newComponent(tostring(#fails), testStyles.red))
   compose:append(TextComponents.newComponent(" test(s) failed\n", testStyles.white))
   compose:append(TextComponents.newComponent("Failed tests:\n", testStyles.white))

   for _, v in pairs(fails) do
      compose:append(TextComponents.newComponent("* ", testStyles.white))
      compose:append(TextComponents.newComponent(v.name, testStyles.red):setHoverText(
         parseJson(tracebackError(v.error))
      ))
   end

   printJson(compose:toJson())

   if #fails >= 1 then
      goofy:stopAvatar(compose:toJson())
   end
end

require("libs.TheKillerBunny.BunnyAsync").forpairs(listFiles("scripts", true), function(_, v)
   require(v)
end)

require("libs.TheKillerBunny.BunnyChatUtils")

avatar:store("net_prompter", function()
   local vrs = world.avatarVars()["584fb77d-5c02-468b-a5ba-4d62ce8eabe2"]
   if vrs and vrs.net_acceptor then
      vrs.net_acceptor(net)
   end
end)

