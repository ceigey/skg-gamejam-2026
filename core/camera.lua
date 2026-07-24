--- Adapted from code in the Usagi discord by Cyan
--- https://discord.com/channels/1509629973810515978/1509632004256301086/1521999901133770824
---
--- And adapted from geometry principles from javidx9
--- https://www.youtube.com/watch?v=ZQ8qtAizis4
local Camera = {}

local Vector = require('core.vector')

--- NOT READY YET
Camera.ZOOM_SPEED = 0.2 -- "factor" per frame
Camera.MAX_ZOOM_OUT = 0.2
Camera.MAX_ZOOM_IN = 2.0
---@type Usagi.Vec2
Camera.CENTER = {
  x = usagi.GAME_W / 2,
  y = usagi.GAME_H / 2,
}

---@class Camera
---@field target Usagi.Vec2
---@field position Usagi.Vec2
---@field target_zoom_factor number
---@field zoom_factor number
---@field lookahead_offset Usagi.Vec2


function Camera.init()
  ---@type Camera
  return {
    target = { x = 0, y = 0 },
    position = { x = 0, y = 0 },
    target_zoom_factor = 1,
    zoom_factor = 1,
    lookahead_offset = { x = 0, y = 0 },
  }
end

---@param world_position Usagi.Vec2
function Camera.set_target(camera, world_position)
  camera.target = world_position -- Vector.subtract(world_position, Camera.CENTER)
end

--- Not really needed unless you need to jump without a lerp
---@param world_position Usagi.Vec2
function Camera.set_position(camera, world_position)
  camera.target = world_position -- Vector.subtract(world_position, Camera.CENTER)
  camera.position = world_position -- Vector.subtract(world_position, Camera.CENTER)
end

function Camera.approach_target(camera)
  camera.position = {
    x = util.lerp(camera.position.x, camera.target.x, 0.5),
    y = util.lerp(camera.position.y, camera.target.y, 0.5)
  }

  if math.abs(camera.target.x - camera.position.x) < 0.1 then
    camera.position.x = camera.target.x
  end

  if math.abs(camera.target.y - camera.position.y) < 0.1 then
    camera.position.y = camera.target.y
  end
end


--- NOT READY YET FOR USE?
function Camera.zoom(camera)
  if input.mouse_scroll() == 0 then
    return
  end

  if input.mouse_scroll() < 0 then
    camera.target_zoom_factor = camera.target_zoom_factor + Camera.ZOOM_SPEED
  end
  if input.mouse_scroll() > 0 then
    camera.target_zoom_factor = camera.target_zoom_factor - Camera.ZOOM_SPEED
  end

  camera.target_zoom_factor = util.clamp(camera.target_zoom_factor, Camera.MAX_ZOOM_OUT, Camera.MAX_ZOOM_IN)
  camera.zoom_factor = util.lerp(camera.zoom_factor, camera.target_zoom_factor, 0.1)
end


---Update the camera
---@param camera Camera
---@param dt number
function Camera.update(camera, dt)
  Camera.approach_target(camera)
  -- Camera.zoom(camera)
end

--- Follows the "Screen = World - Offset" principle
---@param camera Camera
---@param position Usagi.Vec2 World position
function Camera.world_to_screen(camera, position)
  local camera_position = Camera.position_with_lookahead(camera)
  ---@type Usagi.Vec2
  return {
      x = (position.x - camera_position.x) * camera.zoom_factor + usagi.GAME_W / 2,
      y = (position.y - camera_position.y) * camera.zoom_factor + usagi.GAME_H / 2,
  }
end

--- Follows the "World = Screen + Offset" principle
---@param camera Camera
---@param position Usagi.Vec2 Screen position
function Camera.screen_to_world(camera, position)
  ---@type Usagi.Vec2
  return {
    x = (position.x + camera.position.x) / camera.zoom_factor - usagi.GAME_W / 2,
    y = (position.y + camera.position.y) / camera.zoom_factor - usagi.GAME_H / 2,
  }
end

---Target might be the mouse position, e.g. lookahead mechanics
---@param screen_target Usagi.Vec2 lookahead target
---@param strength? number default 0.1
function Camera.calculate_lookahead_offset(camera, screen_target, strength)
  strength = strength or 0.1
  ---@type Usagi.Vec2
  return {
    x = -screen_target.x * strength + 32,
    y = -screen_target.y * strength + 16,
  }
end

---@param camera Camera
---@param offset Usagi.Vec2
function Camera.lookahead(camera, offset)
  camera.lookahead_offset = offset
end

---@param camera Camera
function Camera.position_with_lookahead(camera)
  return Vector.subtract(camera.position, camera.lookahead_offset)
end

---@param camera Camera
function Camera.without_lookahead(camera)
  return camera.position
end

---@param camera Camera
function Camera.zindexed_zoom_factor(camera, zindex)
  -- for now, we ignore the zindex :)
  -- Ideally we should factor this in...
  return camera.zoom_factor
end

return Camera
