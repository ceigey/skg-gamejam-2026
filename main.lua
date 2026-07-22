local Util = require('core.util')
local CloudParallax = require('core.cloud_parallax')
local Player = require('core.player')
local PlayerBullet = require('core.player_bullet')
local Camera = require('core.camera')

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
    },
    camera = Camera.init()
  }

  Camera.set_position(State.camera, State.player.position)
end

---@param dt number
function _update(dt)
  Player.update_entity_camera(State.player, State.camera)
  Player.update(State.player, dt)

  -- Camera work!
  Camera.set_target(
    State.camera,
    State.player.position
  )
  local lookahead = Camera.calculate_lookahead_offset(State.camera, State.player.mouse.position)
  Camera.lookahead(State.camera, lookahead)
  Camera.update(State.camera, dt)

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
  gfx.text_ex("Hello, Usagi! " .. usagi.dump(State.player.position), 8, 8, 1.0, 0, gfx.COLOR_BLACK, 0.25)
  gfx.text_ex("Camera: " .. usagi.dump(State.camera), 8, 64 + 16, 1.0, 0, gfx.COLOR_BLACK, 0.25)


  -- local side_hud_color = gfx.COLOR_LIGHT_GRAY
  -- gfx.rect_fill(
  --   0,
  --   0,
  --   usagi.SPRITE_SIZE * 2,
  --   usagi.GAME_H,
  --   side_hud_color,
  --   0.1
  -- )
  -- gfx.rect_fill(
  --   usagi.GAME_W - usagi.SPRITE_SIZE * 2,
  --   0,
  --   usagi.SPRITE_SIZE * 2,
  --   usagi.GAME_H,
  --   side_hud_color,
  --   0.1
  -- )
  -- gfx.line_ex(
  --   usagi.SPRITE_SIZE * 2,
  --   0,
  --   usagi.SPRITE_SIZE * 2,
  --   usagi.GAME_H,
  --   1,
  --   side_hud_color,
  --   0.25
  -- )
  -- gfx.line_ex(
  --   usagi.GAME_W - usagi.SPRITE_SIZE * 2,
  --   0,
  --   usagi.GAME_W - usagi.SPRITE_SIZE * 2,
  --   usagi.GAME_H,
  --   1,
  --   side_hud_color,
  --   0.25
  -- )
end
