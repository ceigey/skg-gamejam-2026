local Util = require('core.util')
local CloudParallax = require('core.cloud_parallax')
local Player = require('core.player')
local PlayerBullet = require('core.player_bullet')

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
    ---@type CloudParallax.State
    cloud_parallax = {
      particles = {}
    }
  }
end

---@param dt number
function _update(dt)
  Player.update(State.player, dt)
  CloudParallax.update(State.cloud_parallax, State.player)
  PlayerBullet.update_all(State.player.bullets, State.player, dt)
end

---@param dt number
function _draw(dt)
  -- Drawing the background
  gfx.clear(gfx.COLOR_WHITE)

  -- Shader stuff
  -- gfx.shader_uniform('u_time', State.time * 0.25)
  gfx.shader_uniform('u_scanline', 0.5)
  gfx.shader_uniform('u_resolution', { usagi.GAME_W, usagi.GAME_H })
  gfx.shader_uniform('u_flat', 1)
  gfx.shader_uniform('u_ca', 0.0010)
  gfx.shader_uniform('u_scanline_strength', 0.1)
  -- gfx.shader_uniform('u_vertical_scanlines', 1)


  CloudParallax.draw(State.cloud_parallax)

  Player.draw_player_shadow(State.player, nil, nil)
  PlayerBullet.draw_all(State.player.bullets, State.player, dt)
  Player.draw(State.player, dt)
  gfx.text("Hello, Usagi! " .. usagi.dump(State.player.position), 10, 10, gfx.COLOR_BLACK)
end
