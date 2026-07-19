--- Utility module for dealing with vectors.
--- Originally from an earlier gamejam,
--- it keeps evolving each time I need it.
--- Should probably be open sourced + vendored separately.
local Vector = {}

---@param v Usagi.Vec2
---@param min Usagi.Vec2
---@param max Usagi.Vec2
---@return Usagi.Vec2
function Vector.clamped(v, min, max)
  ---@type Usagi.Vec2
  return {
    x = util.clamp(v.x, min.x, max.x),
    y = util.clamp(v.y, min.y, max.y)
  }
end

---@param v Usagi.Vec2
---@param scalar number
---@return Usagi.Vec2
function Vector.multiplied(v, scalar)
  ---@type Usagi.Vec2
  return {
    x = v.x * scalar,
    y = v.y * scalar,
  }
end

---@param v1 Usagi.Vec2
---@param v2 Usagi.Vec2
---@return Usagi.Vec2
function Vector.add(v1, v2)
  ---@type Usagi.Vec2
  return {
    x = v1.x + v2.x,
    y = v1.y + v2.y,
  }
end

return Vector
