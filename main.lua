local Util = require('core.util')
local Player = require('core.player')

PARALLAX_FACTORS =  { 0.2, 0.4, 0.6, 0.8 }

function _config()
  ---@type Usagi.Config
  return {
    name = "Game",
    game_id = "com.usagiengine.YOURGAMENAME",
    game_height = 180 * 2,
    game_width = 320 * 2,
    sprite_size = 32,
  }
end

function _init()
  gfx.shader_set("crt")
  -- Live reload preserves globals across saved edits but resets locals.
  -- Stash mutable game state in a capitalized global like `State` so it
  -- survives reloads; F5 calls _init again to reset.
  State = {
    time = 0,
    player = Player.init(),
  }
end

---@param dt number
function _update(dt)
  Player.update(State.player, dt)
end

---@param dt number
function _draw(dt)
  -- gfx.shader_uniform("u_time", usagi.elapsed)

  -- Drawing the background
  gfx.clear(gfx.COLOR_WHITE)


  local grid_width = usagi.SPRITE_SIZE * 4
  local grid_offset_x = util.round(State.player.position.x) % grid_width
  local grid_offset_y = util.round(State.player.position.y) % grid_width

  for i, parallax_factor in ipairs(PARALLAX_FACTORS) do
    for x = 0 - grid_offset_x * 2, (usagi.GAME_W + grid_offset_x * 2) / parallax_factor, grid_width do
      for y = 0 - grid_offset_y * 2, (usagi.GAME_H + grid_offset_y * 2) / parallax_factor, grid_width do
        local particle_position = {
          x = (x * parallax_factor + State.player.camera.offset.x * parallax_factor),
          y = (y * parallax_factor + State.player.camera.offset.y * parallax_factor),
        }
        local distance_from_player = util.vec_dist(State.player.camera.position, particle_position)
        gfx.circ_fill(
          particle_position.x,
          particle_position.y,
          12 / parallax_factor, -- 12 / parallax_factor + (distance_from_player / 10) ,
          gfx.COLOR_TRUE_WHITE,
          parallax_factor - 0.1
        )
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

  -- Shader stuff
  -- gfx.shader_uniform('u_time', State.time * 0.25)
  gfx.shader_uniform('u_scanline', 0.5)
  gfx.shader_uniform('u_resolution', { usagi.GAME_W, usagi.GAME_H })
  gfx.shader_uniform('u_flat', 1)
  gfx.shader_uniform('u_ca', 0.0010)
  gfx.shader_uniform('u_scanline_strength', 0.1)
  -- gfx.shader_uniform('u_vertical_scanlines', 1)


  Player.draw(State.player, dt)
  gfx.text("Hello, Usagi! " .. usagi.dump(State.player.position), 10, 10, gfx.COLOR_BLACK)
end
