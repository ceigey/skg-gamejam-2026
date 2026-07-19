local Util = require('core.util')


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
    player = {
      rotation = 3.14 / 4
    },
    mouse = {
      position = {
        x = 0,
        y = 0,
      },
      distance_from_player = 0,
    }
  }
end

---@param dt number
function _update(dt)
  State.time = State.time + dt
  local mouse_x, mouse_y = input.mouse()

  State.player.position = {
    x = usagi.GAME_W / 2 - usagi.SPRITE_SIZE / 2,
    y = usagi.GAME_H / 2 - usagi.SPRITE_SIZE / 2
  }

  State.mouse = State.mouse or {}
  State.mouse.position = {
    x = mouse_x,
    y = mouse_y
  }

  State.mouse.distance_from_player = util.vec_dist(State.player.position, State.mouse.position)

  -- because I'm forgetful
  -- https://gamedev.stackexchange.com/questions/14602/what-are-atan-and-atan2-used-for-in-games
  local target_rotation = math.atan(
    State.mouse.position.y - State.player.position.y,
    State.mouse.position.x - State.player.position.x
  )
  State.player.rotation = Util.clamp_radians(target_rotation, State.player.rotation, math.pi / 16)

  -- How to angle: https://stackoverflow.com/a/839931
  -- Whatever I have below actually works well for projecting beneath
  local sightline_start_radius = 32                                -- I want a bit of distance between the player and the sight start to declutter the player
  local sightline_end_radius = usagi.GAME_W / 2 + usagi.GAME_H / 2 -- drawing offscreen effectively (good? bad?)
  local sightline_spread = math.pi / 32                            -- how much spread (doubles for start)
  State.sightlines = State.sightlines or {}
  State.sightlines.left = {
    startpoint = {
      x = State.player.position.x + sightline_start_radius * math.cos(State.player.rotation - sightline_spread * 2),
      y = State.player.position.y + sightline_start_radius * math.sin(State.player.rotation - sightline_spread * 2),
    },
    endpoint = {
      x = State.player.position.x + sightline_end_radius * math.cos(State.player.rotation - sightline_spread),
      y = State.player.position.y + sightline_end_radius * math.sin(State.player.rotation - sightline_spread),
    },
  }
  State.sightlines.right = {
    startpoint = {
      x = State.player.position.x + sightline_start_radius * math.cos(State.player.rotation + sightline_spread * 2),
      y = State.player.position.y + sightline_start_radius * math.sin(State.player.rotation + sightline_spread * 2),
    },
    endpoint = {
      x = State.player.position.x + sightline_end_radius * math.cos(State.player.rotation + sightline_spread),
      y = State.player.position.y + sightline_end_radius * math.sin(State.player.rotation + sightline_spread),
    },
  }
end

---@param dt number
function _draw(dt)
  -- gfx.shader_uniform("u_time", usagi.elapsed)

  -- Drawing the background
  gfx.clear(gfx.COLOR_WHITE)

  -- Shader stuff
  -- gfx.shader_uniform('u_time', State.time * 0.25)
  gfx.shader_uniform('u_scanline', 0.5)
  gfx.shader_uniform('u_resolution', { usagi.GAME_W, usagi.GAME_H })
  gfx.shader_uniform('u_flat', 1)


  -- I used to draw a main targeting line here but it's superfluous
  -- gfx.line_ex(
  --   State.player.position.x,
  --   State.player.position.y,
  --   State.mouse.position.x,
  --   State.mouse.position.y,
  --   1,
  --   gfx.COLOR_RED, 0.25
  -- )

  -- Rotating player sprite, not sure about camera lag yet...
  -- (the maths will suck)
  gfx.spr_ex(
    1,
    State.player.position.x - usagi.SPRITE_SIZE / 2,
    State.player.position.y - usagi.SPRITE_SIZE / 2,
    false,
    false,
    State.player.rotation + math.pi / 2,
    gfx.COLOR_TRUE_WHITE, 1.0
  )

  -- Drawing the sight lines (visual guide only)
  gfx.line_ex(
    State.sightlines.left.startpoint.x,
    State.sightlines.left.startpoint.y,
    State.sightlines.left.endpoint.x,
    State.sightlines.left.endpoint.y,
    1,
    gfx.COLOR_RED, 0.25
  )
  gfx.line_ex(
    State.sightlines.right.startpoint.x,
    State.sightlines.right.startpoint.y,
    State.sightlines.right.endpoint.x,
    State.sightlines.right.endpoint.y,
    1,
    gfx.COLOR_RED, 0.25
  )

  -- Drawing the mouse cursor
  -- gfx.circ_fill(State.mouse.position.x, State.mouse.position.y, 4, gfx.COLOR_RED, 0.5)
  gfx.circ(State.mouse.position.x, State.mouse.position.y,
    -- TODO: consider making this a constant and sharing with the sightline endpoint radius?
    util.lerp(16, 64, State.mouse.distance_from_player / (usagi.GAME_W / 2)),
    gfx.COLOR_RED,
    0.25)

  -- gfx.circ_fill(State.mouse.position.x, State.mouse.position.y,
  --   -- TODO: consider making this a constant and sharing with the sightline endpoint radius?
  --   util.lerp(16, 64, State.mouse.distance_from_player / (usagi.GAME_W / 2)),
  --   gfx.COLOR_RED,
  --   0.025)

  gfx.text("Hello, Usagi! " .. State.player.rotation, 10, 10, gfx.COLOR_BLACK)
end
