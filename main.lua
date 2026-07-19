local Util = require('core.util')
local Player = require('core.player')

PARALLAX_FACTORS = { 0.2, 0.4, 0.6, 0.8 }

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


  for x = util.round(State.player.position.x) - usagi.GAME_W, util.round(State.player.position.x) + usagi.GAME_W, 1 do
    for y = util.round(State.player.position.y) - usagi.GAME_H, util.round(State.player.position.y) + usagi.GAME_H, 1 do
      if x % 64 == 0 and y % 64 == 0 then
        for i, parallax_factor in ipairs(PARALLAX_FACTORS) do
          gfx.circ_fill(
            (x - State.player.position.x * parallax_factor + State.player.camera.position.x * parallax_factor),
            (y - State.player.position.y * parallax_factor + State.player.camera.position.y * parallax_factor),
            10 * parallax_factor,
            gfx.COLOR_LIGHT_GRAY,
            parallax_factor - 0.1
          )
        end
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
