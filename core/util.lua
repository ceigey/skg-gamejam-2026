local Util = {}

--- https://stackoverflow.com/a/28037434
---@param target number in radians
---@param current number in radians
function Util.angular_difference(target, current)
  -- local difference = (target - current + math.pi) % math.pi * 2 - math.pi

  -- if difference < -math.pi then
  --   return difference + math.pi * 2
  -- else
  --   return difference
  -- end

  return math.atan(math.sin(target - current), math.cos(target - current))
end

---comment
---@param n number
---@return number
function Util.normalize_radians(n)
  return math.atan(math.sin(n), math.cos(n))
end

---@param target number in radians
---@param current number in radians
---@param max number in radians
function Util.clamp_radians(target, current, max)
  local difference = Util.angular_difference(target, current)
  difference = Util.normalize_radians(difference)


  if math.abs(difference) <= max then
    return target
  elseif difference > 0 then
    return current + max
  else
    return current - max
  end
end

return Util
