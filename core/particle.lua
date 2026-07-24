local Camera = require('core.camera')
local Particle = {}

---@class Particle.Frame
---@field shape Usagi.Circ
---@field alpha number
---@field color integer

---@class Particle.State
---@field frames Particle.Frame[]
---@field frame_index integer

---@param frames Particle.Frame[]
---@return Particle.State
function Particle.init(frames)
  ---@type Particle.State
  return {
    frames = frames,
    frame_index = 1,
  }
end

---@param particle Particle.State
function Particle.update(particle)
  particle.frame_index = particle.frame_index + 1
end

---@param particles Particle.State[]
function Particle.update_all(particles)
  for i = #particles, 1, -1 do
    local particle = particles[i]
    Particle.update(particle)
    -- clean up remainders
    if particle.frame_index > #particle.frames then
      table.remove(particles, i)
    end
  end
end

---comment
---@param particle Particle.State
---@param camera Camera
function Particle.draw(particle, camera)
  local frame = particle.frames[particle.frame_index]
  local position = {
    x = frame.shape.x,
    y = frame.shape.y
  }
  local camera_position = Camera.world_to_screen(camera, position)
  gfx.circ_fill(
    camera_position.x,
    camera_position.y,
    frame.shape.r,
    frame.color,
    frame.alpha
  )
end

---@param particles Particle.State[]
---@param camera Camera
function Particle.draw_all(particles, camera)
  for i, particle in ipairs(particles) do
    Particle.draw(particle, camera)
  end
end



return Particle
