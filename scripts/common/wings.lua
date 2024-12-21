local openWingsAnim = animations["models.model"].OpenWings
local closeWingsAnim = animations["models.model"].CloseWings

local wingRight = models.model.root.Body.WingRight
local wingLeft = models.model.root.Body.WingLeft

local jetpack = models.model.root.Body.Jetpack
local smokePivots = {
   jetpack.SmokePivotRight;
   jetpack.SmokePivotLeft;
}

local function recursivelySetRenderType(mdl, renderType)
   mdl:setPrimaryRenderType(renderType)

   for _, v in pairs(mdl:getChildren()) do
      recursivelySetRenderType(v, renderType)
   end
end

recursivelySetRenderType(wingRight, "TRANSLUCENT_CULL")
recursivelySetRenderType(wingLeft, "TRANSLUCENT_CULL")

closeWingsAnim:play()

local previousWingState
local function toggleWings(state)
   if state then
      if not previousWingState then
         closeWingsAnim:stop()
         openWingsAnim:play()

         previousWingState = state
      end
   elseif not state then
      if previousWingState then
         openWingsAnim:stop()
         closeWingsAnim:play()
         
         previousWingState = state
      end
   end
end

local jetpackOn = 0
function pings.setFlightTime(duration)
   if duration == 0 or not duration then
      return
   end

   jetpackOn = (duration + 1) * 10 + 5
end

keybinds:fromVanilla("key.use"):setGUI(false):setOnPress(function()
   if not player:isGliding() then
      return
   end

   local item = player:getHeldItem()

   if item:getID() ~= "minecraft:firework_rocket" then
      item = player:getHeldItem(true)
   end

   if item:getID() == "minecraft:firework_rocket" then
      pings.setFlightTime(item:getTag().Fireworks.Flight)
   end
end)

local steamColor = vec(1, 1, 1)
function events.TICK()
   toggleWings(player:isGliding())

   if jetpackOn > 0 then
      local velocity = jetpack:partToWorldMatrix().c2.xyz * -4
      jetpackOn = jetpackOn - 1

      for _, v in pairs(smokePivots) do
         particles:newParticle("minecraft:dust 1 1 1 2", v:partToWorldMatrix():apply(0,0,0))
            :setVelocity(velocity)
            :setScale(0.75)
            :setLifetime(40)
            :setColor(steamColor - (math.random() / 5))
      end
   end
end

