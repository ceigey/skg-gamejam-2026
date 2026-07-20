local CloudParallax = {}
local Player = require('core.player')

---@class CloudParallax.State
---@field particles CloudParallax.Particle.State[]

---@class CloudParallax.Particle.State
---@field position Usagi.Vec2
---@field radius number
---@field color integer
---@field opacity number

---@param player Player.State
---
function CloudParallax.calculate_particles(player)
  ---@type CloudParallax.Particle.State[]
  local particles = {}
  local grid_width = usagi.SPRITE_SIZE * 4
  local grid_offset_x = util.round(State.player.position.x) % grid_width
  local grid_offset_y = util.round(State.player.position.y) % grid_width
  local player_shadow_position = Player.calculate_shadow_position(State.player)
  local player_shadow_opacity = Player.SHADOW_BASE_OPACITY

  for i, parallax_factor in ipairs(PARALLAX_FACTORS) do
    for x = 0 - grid_offset_x * 2, (usagi.GAME_W + grid_offset_x * 2) / parallax_factor, grid_width do
      for y = 0 - grid_offset_y * 2, (usagi.GAME_H + grid_offset_y * 2) / parallax_factor, grid_width do
        local particle_position = {
          x = (x * parallax_factor + State.player.camera.offset.x * parallax_factor),
          y = (y * parallax_factor + State.player.camera.offset.y * parallax_factor),
        }
        ---@type CloudParallax.Particle.State
        local particle = {
          position = particle_position,
          radius = 12 / parallax_factor,
          color = gfx.COLOR_TRUE_WHITE,
          opacity = parallax_factor - 0.1
        }
        table.insert(particles, particle)

        -- local distance_from_shadow = util.vec_dist(player_shadow_position, particle_position)
        -- local distance_from_player = util.vec_dist(State.player.camera.position, particle_position)

        -- Didn't really work out well
        -- if distance_from_shadow <= 16 then
        --   local distance_factor = distance_from_shadow / 16
        --   player_shadow_opacity = player_shadow_opacity + parallax_factor * distance_factor / 50
        -- end

        -- gfx.rect_fill(
        --   (x * parallax_factor + State.player.camera.offset.x * parallax_factor),
        --   (y * parallax_factor + State.player.camera.offset.y * parallax_factor),
        --   100 * parallax_factor,
        --   100 * parallax_factor,
        --   gfx.COLOR_WHITE,
        --   parallax_factor - 0.1
        -- )
      end
    end
  end
  return particles
end


---@param clouds CloudParallax.State
---@param player Player.State
function CloudParallax.update(clouds, player)
  clouds.particles = CloudParallax.calculate_particles(player)
end

---@param clouds CloudParallax.State
function CloudParallax.draw(clouds)
  for i, particle in ipairs(clouds.particles) do
    gfx.circ_fill(
      particle.position.x,
      particle.position.y,
      particle.radius, -- 12 / parallax_factor + (distance_from_player / 10) ,
      particle.color,
      particle.opacity
    )
  end
end

return CloudParallax
