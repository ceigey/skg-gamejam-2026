local Controls = {}

---@param input Usagi.Input
function Controls.normalized_keypad_direction(input)
  ---@type Usagi.Vec2
  local raw = { x = 0, y = 0 }
  if input.held(input.UP) then
    raw.y -= 1
  end
  if input.held(input.DOWN) then
    raw.y += 1
  end
  if input.held(input.LEFT) then
    raw.x -= 1
  end
  if input.held(input.RIGHT) then
    raw.x += 1
  end

  return util.vec_normalize(raw)
end

return Controls
