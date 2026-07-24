local Vector = require('core.vector')

local Geometry = {}

--- TODO Get a better name!
---@param satellite Usagi.Vec2 our point / offset / "satellite", *relative to an anchor!*
---@param reference_rotation number in radians, e.g. our anchor in the rotation we calculated the offset from
---@param target_rotation number in radians, how far "around" we wanna "orbit"
---@return Usagi.Vec2
function Geometry.orbit(satellite, reference_rotation, target_rotation)
  local angle_of_offset = Vector.radians(satellite)
  local magnitude = Vector.magnitude(satellite)
  local new_angle = target_rotation + angle_of_offset + reference_rotation -- I think...
  return util.vec_from_angle(new_angle, magnitude)
end

return Geometry
