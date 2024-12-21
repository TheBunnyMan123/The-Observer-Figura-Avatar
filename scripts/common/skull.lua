local tasks = {}
local cache = {}
local signlib = require("libs.TheKillerBunny.BunnySignLib")

local function deepCopy(model, name)
  local part = model:copy(name)

  for _, v in pairs(part:getChildren()) do
    part:removeChild(v)
    part:addChild(deepCopy(v, v:getName()))
  end

  return part
end

local model = deepCopy(models.model.root, "Skull"):setParentType("SKULL"):setScale(0.3):setPos(0, -3, 0)

local function setParentTypeRec(model, tpe)
  for _, v in pairs(model:getChildren()) do
    setParentTypeRec(v, tpe)
  end

  model:setParentType(tpe)
end
setParentTypeRec(model, "NONE")
model:setParentType("SKULL")

model.LeftLeg:setRot(90, 13, 0)
model.RightLeg:setRot(90, -13, 0)
model.LeftArm:setRot(13, 0)
model.RightArm:setRot(13, 0)

models:addChild(model)

local taskHolder = models:newPart("TKBunny$TaskHolderModels", "SKULL")

local function compileVec(str)
  local x, y, z = str:match("^[0-9.]+,[0-9.]+,[0-9.]+$")

  return vectors.vec3(tonumber(x), tonumber(y), tonumber(z))
end

local function rotateBlockTaskCenterOffset(rot, pos)
  pos=pos-8
  pos = vectors.rotateAroundAxis(rot.x, pos, vec(1, 0, 0))
  pos = vectors.rotateAroundAxis(rot.y, pos, vec(0, 1, 0))
  pos = vectors.rotateAroundAxis(rot.z, pos, vec(0, 0, 1))
  return pos
end

local tick = 0
function events.WORLD_TICK()
  tick = tick + 1
  for k, v in pairs(cache) do
    if not world.getBlockState(compileVec(k)):getID():match("head") then
      cache[k] = nil
    end
  end
end

local oldEatTick = 0
local ate = {}
local function eat(pos)
  ate[tostring(pos)] = (ate[tostring(pos)] or 0) + 1
  if ate[tostring(pos)] % 7 == 0 then
    sounds:playSound("entity.player.burp", pos, 10)
  else
    sounds:playSound("entity.generic.eat", pos)
  end
end

local pianoLib = world.avatarVars()["943218fd-5bbc-4015-bf7f-9da4f37bac59"]

local modes = {
  ["minecraft:loom"] = {
    interact = function() end,
    func = function(block, data)
      if not pianoLib or not pianoLib.playNote then
        pianoLib = world.avatarVars()["943218fd-5bbc-4015-bf7f-9da4f37bac59"]
        return
      end

      local pianoPos = block:getPos() + vec(0, 3, 0)

      if world.getBlockState(pianoPos):getID() ~= "minecraft:player_head" then
        return
      end

      local cacheIndex = string.format("%i,%i,%i", block:getPos():unpack())

      if not cache[cacheIndex] or not cache[cacheIndex].tick then
        cache[cacheIndex].tick = 0
        cache[cacheIndex].oldTick = 0
        cache[cacheIndex].song = {}

        local midi = data:gsub("[^A-G0-9;,]", "")

        for _, v in pairs(string.split(midi, ";")) do
          table.insert(cache[cacheIndex].song, {
            string.split(v, ",")
          })
        end
      end

      if cache[cacheIndex].oldTick ~= tick then
        cache[cacheIndex].oldTick = tick
        cache[cacheIndex].tick = ((cache[cacheIndex].tick + 1) % (#cache[cacheIndex].song + 1))

        local songTick = cache[cacheIndex].song[cache[cacheIndex].tick] or {}

        for _, tbl in pairs(songTick) do
          for _, v in pairs(tbl) do
            if v == "" then
              goto continue
            end
            pianoLib.playNote(tostring(pianoPos), v, true)
            ::continue::
          end
        end
      end
    end
  },
  ["minecraft:hay_block"] = {
    interact = function(side, pos)
      ate(pos)
    end,
    func = function(block)
      for _, v in pairs(world.getPlayers()) do
        if v:getSwingTime() == 1 and oldEatTick ~= tick and v:getTargetedBlock() == block then
          eat(block:getPos())
          oldEatTick = tick
        end
      end
    end
  },
  ["minecraft:oak_log"] = {
    func = function(block, signdata, delta)
      if signdata == "" then return end
      signdata = string.split(signdata, ";")

      if signdata[1] =="I" then
        local displayItem = signdata[2]
        local autorot = (signdata[5] or "true") ~= "false"
        local pos = compileVec(signdata[3] or "0,0,0") + vec(0, autorot and math.sin(math.lerp((tick - 1) / 6, tick / 6, delta)) or 0, 0)
        local scale = compileVec(signdata[4] or "1,1,1")
        local rot = compileVec(signdata[6] or "0,0,0")

        table.insert(tasks, taskHolder:newItem("item")
          :setItem(displayItem)
          :setPos(pos + vec(0, 32, 0))
          :setScale(scale)
          :setRot(autorot and vec(0, math.lerpAngle((tick - 1) * 2, tick * 2, delta) or 0, 0) or rot))
      elseif signdata[1] == "B" then
        local displayBlock = signdata[2]
        local autorot = (signdata[5] or "true") ~= "false"
        local scale = compileVec(signdata[4] or "1,1,1")
        local rot = compileVec(signdata[6] or "0,0,0")
        local pos = compileVec(signdata[3] or "0,0,0")
        + vec(0, autorot and math.sin(math.lerp((tick - 1) / 6, tick / 6, delta)) or 0, 0)
        + rotateBlockTaskCenterOffset(autorot and vec(0, math.lerpAngle((tick - 1) * 2, tick * 2, delta) or 0, 0) or rot,vec(0,0,0))

        table.insert(tasks, taskHolder:newBlock("block")
          :setBlock(displayBlock)
          :setPos(pos + vec(0, 32, 0))
          :setScale(scale)
          :setRot(autorot and vec(0, math.lerpAngle((tick - 1) * 2, tick * 2, delta) or 0, 0) or rot))
      else
        table.insert(tasks, taskHolder.camera:newText("help")
          :setText("TYPE (B|I|INV);BLOCK/ITEM/RENDERTYPE;POS (x,y,z);SCALE (x,y,z);AUTOROT (any|false);ROT (x,y,z)")
          :setAlignment("CENTER")
          :setPos(0, 13, 0)
          :setScale(0.25)
          :setOutline(true))
      end
    end,
    interact = function(side)
    end
  },
  ["minecraft:dead_brain_coral_block"] = {
    func = function(block, signdata, _, backText)
      local cacheIndex = tostring(block:getPos()):gsub("[%s{}]", "")
      if not cache[cacheIndex] then cache[cacheIndex] = {} end

      if cache[cacheIndex].bfout then
        local dims = client.getTextDimensions(cache[cacheIndex].bfout, 500, true)

        table.insert(tasks, taskHolder.camera:newText("bfout")
          :setWrap(true)
          :setText(cache[cacheIndex].bfout)
          :setAlignment("CENTER")
          :setPos(dims._y_ / 4 + vec(0, 9, 0))
          :setScale(0.25)
          :setWidth(500)
          :setOutline(true))

        return
      end
      local bytes = {}
      if backText:gsub("[%d;]", "") == "" then
        bytes = string.split(backText, ";")
        for k in pairs(bytes) do
          bytes[k] = tonumber(bytes[k])
        end
      else
        bytes = {string.byte(backText, 1, #backText)}
      end
      local realOut, codePointer, tokens, tape, tapePointer, out, input
      if not cache[cacheIndex].bfenv then
        realOut, codePointer, tokens, tape, tapePointer, out, input, loopPointers = require("libs.TheKillerBunny.brainfuck").runLimited(signdata, 20000, bytes)
      else
        realOut, codePointer, tokens, tape, tapePointer, out, input, loopPointers = require("libs.TheKillerBunny.brainfuck").runLimited(signdata, 20000, bytes, table.unpack(cache[cacheIndex].bfenv))
      end
      cache[cacheIndex].bfout = realOut
      if not realOut then
        cache[cacheIndex].bfenv = {
          codePointer,
          tokens,
          tape,
          tapePointer,
          out,
          input,
          loopPointers
        }
      end
    end,
    interact = function(side) end
  },
  ["minecraft:bamboo_block"] = {
    func = function(_, signdata, _, backText)
      local opts = string.split(backText, ";")
      
      if opts[1] == "HELP" then
        table.insert(tasks, taskHolder:newText("text")
          :setPos(0, 12, 0)
          :setScale(0.5)
          :setOutline(true)
          :setText("POS (VEC3);ROT (VEC3);SCALE (VEC3);OUTLINE (BOOL);ALIGNMENT"))
        return
      end

      local pos = compileVec(opts[1] or "0,0,0")
      local rot = compileVec(opts[2] or "0,0,0")
      local scale = compileVec(opts[3] or "1,1,1") * 0.5
      local outline = (opts[4] ~= "false")
      local alignment = opts[5] or "CENTER"

      local dims = client.getTextDimensions(signdata)

      table.insert(tasks, taskHolder:newText("text")
          :setPos(pos + vec(0, 9, 0) + (dims._y_ * scale))
          :setRot(rot)
          :setScale(scale)
          :setOutline(outline)
          :setAlignment(alignment)
          :setText(signdata))
    end,
    interact = function(side) end
  },
}

function events.SKULL_RENDER(delta, block, item, entity)
  model:setVisible(true)
  
  model:setPos(0, -3, 0)

  for _, v in pairs(tasks) do v:remove() end
  tasks = {}
  if not block then return end

  local blockBelow = world.getBlockState(block:getPos():sub(0, 1))
  if modes[blockBelow:getID()] then
    local cacheIndex = tostring(block:getPos()):gsub("[%s{}]", "")
    cache[cacheIndex] = cache[cacheIndex] or {}
    if cache[cacheIndex].error then
      table.insert(tasks, taskHolder:newText("error-"..tostring(block:getPos()))
        :setText(cache[cacheIndex].error)
        :setOutline(true)
        :setScale(0.25)
        :setPos(vec(0, 9, 0) + (client.getTextDimensions(cache[cacheIndex].error)._y_ / vec(8, 4, 1))))
      
      return
    end

    local signdata = ""
    local signOffset = vec(0, 0, 0)

    local rot = math.round((block:getProperties().rotation or 0)/4)
    if rot == 4 then rot = 0 end
    
    if rot == 0 then
      signOffset = vec(0, 0, -1)
    elseif rot == 1 then
      signOffset = vec(1, 0, 0)
    elseif rot == 2 then
      signOffset = vec(0, 0, 1)
    else
      signOffset = vec(-1, 0, 0)
    end

    local keepCheckingSigns = true
    local signCount = 0
    local backText = ""
    local backOffset = signOffset:copy() * -1
    while (signCount < 50) and keepCheckingSigns do
      local sign = world.getBlockState(blockBelow:getPos():add(signOffset))
      if sign:getID():match("sign") then
        for _, v in pairs(signlib.read(sign).front) do
          signdata = signdata .. v:gsub("\\(.)", "%1"):gsub('^"', ""):gsub('"$', "")
        end

        signCount = signCount + 1
        signOffset.y = signOffset.y - 1
      else
        keepCheckingSigns = false
      end
    end
    signCount = 0
    keepCheckingSigns = true
    while (signCount < 50) and keepCheckingSigns do
      local sign = world.getBlockState(blockBelow:getPos():add(backOffset))
      if sign:getID():match("sign") then
        for _, v in pairs(signlib.read(sign).front) do
          backText = backText .. v:gsub("\\(.)", "%1"):gsub('^"', ""):gsub('"$', "")
        end

        signCount = signCount + 1
        backOffset.y = backOffset.y - 1
      else
        keepCheckingSigns = false
      end
    end

    local success, error = pcall(modes[blockBelow:getID()].func, block, signdata, delta, backText)

    if not success then
       print(_G, _G.tracebackError)
      local formatted = toJson(
         tracebackError(error)
      )
      cache[cacheIndex].error = formatted
      table.insert(tasks, taskHolder:newText("error-"..tostring(block:getPos()))
        :setText(formatted)
        :setOutline(true)
        :setScale(0.25)
        :setPos(vec(0, 9, 0) + (client.getTextDimensions(formatted)._y_ / vec(8, 4, 1))))
    end
  end
end

