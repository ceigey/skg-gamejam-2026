local Vector = require('core.vector')
local Geometry = require('core.geometry')
local Hitbox = {}

---@alias Hitbox.Bounds
---| Usagi.Circ
---| Usagi.Rect

---@class Hitbox.Definition
---@field bounds Hitbox.Bounds
---@field damage_multiplier? number -- 1.0 by default

---@param bounds Hitbox.Bounds
function Hitbox.position(bounds)
  --- @type Usagi.Vec2
  return {
    x = bounds.x,
    y = bounds.y
  }
end

---Orbit a hitbox bound around a reference point (e.g. sprite centre)
---@param bounds Hitbox.Bounds
---@param reference_rotation number
---@param target_rotation number
---@return Usagi.Circ | Usagi.Rect
function Hitbox.orbit_bounds(bounds, reference_rotation, target_rotation)
  local offset = Hitbox.position(bounds)
  local destination = Geometry.orbit(
    offset,
    reference_rotation,
    target_rotation
  )
  if bounds.r then
    ---@type Usagi.Circ
    return {
      x = destination.x,
      y = destination.y,
      r = bounds.r
    }
  end
  ---@type Usagi.Rect
  return {
    x = destination.x,
    y = destination.y,
    w = bounds.w,
    h = bounds.h,
  }
end

---@param bounds Hitbox.Bounds
---@param reference Usagi.Vec2 what you want to anchor the global position to
---@return Usagi.Vec2
function Hitbox.position_in_world(bounds, reference)
  local offset = Hitbox.position(bounds)
  return Vector.add(reference, offset)
end

---@param bounds Hitbox.Bounds but positioned in world!
function Hitbox.draw_debug(bounds)
  local color = gfx.COLOR_GREEN
  if bounds.r then
    -- print('DRAWNING CIRC', usagi.dump(bounds.r))
    ---@cast bounds Usagi.Circ
    gfx.circ_fill(
      bounds.x,
      bounds.y,
      bounds.r,
      color,
      0.25
    )
    gfx.circ_ex(
      bounds.x,
      bounds.y,
      bounds.r,
      1,
      color,
      0.5
    )
  else
    -- print('DRAWNING RECT', usagi.dump(bounds.r), usagi.dump(bounds.w))
    ---@cast bounds Usagi.Rect
    gfx.rect_fill(
      bounds.x,
      bounds.y,
      bounds.w,
      bounds.h,
      color,
      0.1
    )
    gfx.rect_ex(
      bounds.x,
      bounds.y,
      bounds.w,
      bounds.h,
      1,
      color,
      0.25
    )
  end
end

---comment
---@param definitions Hitbox.Definition[]
---@param anchor_position Usagi.Vec2
---@param reference_rotation number
---@param target_rotation number
---@return Hitbox.Definition[]
function Hitbox.bring_all_into_world(definitions, anchor_position, reference_rotation, target_rotation)
  ---@type Hitbox.Definition[]
  local reifieds = {}
  for i, def in ipairs(definitions) do
    -- print('Whats happening with bounds?', usagi.dump(def.bounds))
    local orbited = Hitbox.orbit_bounds(def.bounds, reference_rotation, target_rotation)
    -- print('Orbited?', usagi.dump(orbited))
    local world_position = Hitbox.position_in_world(orbited, anchor_position)
    orbited.x = world_position.x
    orbited.y = world_position.y
    ---@type Hitbox.Definition
    local new_definition = {
      bounds = orbited,
      damage_multiplier = def.damage_multiplier,
    }
    table.insert(reifieds, new_definition)
  end
  return reifieds
end



return Hitbox
