local Util = require('core.util')
local Controls = require('core.controls')
local Vector = require('core.vector')

local Player = {}

Player.INITIAL_MAX_THRUST = 30 -- px/s
Player.NORMAL_DRAG = 0.95
Player.SHADOW_BASE_OPACITY = 0.1
Player.SHADOW_ZINDEX = 64

---@class Player.Mouse
---@field position Usagi.Vec2
---@field distance_from_player number

---@class Player.Sightline
---@field startpoint Usagi.Vec2
---@field endpoint Usagi.Vec2

---@class Player.Sightlines
---@field left Player.Sightline
---@field right Player.Sightline

---@class Player.Camera
---@field position Usagi.Vec2
---@field offset Usagi.Vec2

---@class Player.State
---@field rotation number
---@field position Usagi.Vec2
---@field direction Usagi.Vec2
---@field velocity Usagi.Vec2
---@field delta Usagi.Vec2
---@field mouse Player.Mouse
---@field sightlines? Player.Sightlines
---@field camera Player.Camera
---@field max_thrust number


function Player.init()
  ---@type Player.State
  return {
    position = { x = 0, y = 0 },
    direction = { x = 0, y = 0 },
    velocity = { x = 0, y = 0 },
    delta = { x = 0, y = 0 },
    rotation = 3.14 / 4,
    max_thrust = Player.INITIAL_MAX_THRUST,
    camera = {
      position = {
        x = usagi.GAME_W / 2 - usagi.SPRITE_SIZE / 2,
        y = usagi.GAME_H / 2 - usagi.SPRITE_SIZE / 2
      },
      offset = {
        x = 0,
        y = 0,
      }
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

---@param player Player.State
---@param dt number
function Player.update_from_mouse_input(player, dt)
  local mouse_x, mouse_y = input.mouse()


  local default_camera_x = usagi.GAME_W / 2 - usagi.SPRITE_SIZE / 2
  local default_camera_y = usagi.GAME_H / 2 - usagi.SPRITE_SIZE / 2

  player.camera.offset = {
    x = (default_camera_x - mouse_x) * 0.1,
    y = (default_camera_y - mouse_y) * 0.1,
  }

  -- TODO: This should probably be camera.offset
  -- with camera.position handled by something else
  player.camera.position = {
    x = usagi.GAME_W / 2 - usagi.SPRITE_SIZE / 2 + player.camera.offset.x,
    y = usagi.GAME_H / 2 - usagi.SPRITE_SIZE / 2 + player.camera.offset.y
  }


  player.mouse = player.mouse or {}
  player.mouse.position = {
    x = mouse_x,
    y = mouse_y
  }

  player.mouse.distance_from_player = util.vec_dist(player.camera.position, player.mouse.position)
end

---@param player Player.State
---@param dt number
function Player.update_rotation(player, dt)
  local target_rotation = math.atan(
    player.mouse.position.y - player.camera.position.y,
    player.mouse.position.x - player.camera.position.x
  )
  player.rotation = Util.clamp_radians(target_rotation, State.player.rotation, math.pi / 16)
end

---@param player Player.State
---@param dt number
function Player.update_sightlines(player, dt)
  local sightline_start_radius = 32                                -- I want a bit of distance between the player and the sight start to declutter the player
  local sightline_end_radius = usagi.GAME_W / 2 + usagi.GAME_H / 2 -- drawing offscreen effectively (good? bad?)
  local sightline_spread = math.pi / 32

  player.sightlines = player.sightlines or {}
  player.sightlines.left = {
    startpoint = {
      x = player.camera.position.x + sightline_start_radius * math.cos(player.rotation - sightline_spread * 2),
      y = player.camera.position.y + sightline_start_radius * math.sin(player.rotation - sightline_spread * 2),
    },
    endpoint = {
      x = player.camera.position.x + sightline_end_radius * math.cos(player.rotation - sightline_spread),
      y = player.camera.position.y + sightline_end_radius * math.sin(player.rotation - sightline_spread),
    },
  }
  player.sightlines.right = {
    startpoint = {
      x = player.camera.position.x + sightline_start_radius * math.cos(player.rotation + sightline_spread * 2),
      y = player.camera.position.y + sightline_start_radius * math.sin(player.rotation + sightline_spread * 2),
    },
    endpoint = {
      x = player.camera.position.x + sightline_end_radius * math.cos(player.rotation + sightline_spread),
      y = player.camera.position.y + sightline_end_radius * math.sin(player.rotation + sightline_spread),
    },
  }
end

---@param player Player.State
---@param dt number
function Player.update_from_keyboard(player, dt)
  -- Update direction (required for movement)
  player.direction = Controls.normalized_keypad_direction(input)
end

---@param player Player.State
---@param dt number
function Player.apply_drag_to_velocity(player, dt)
  player.velocity = Vector.multiplied(player.velocity, Player.NORMAL_DRAG)
  if math.abs(player.velocity.x) < 0.1 then
    player.velocity.x = 0
  end
  if math.abs(player.velocity.y) < 0.1 then
    player.velocity.y = 0
  end
end

---@param player Player.State
---@param dt number
function Player.update_movement(player, dt)
  -- Direction + Thrust -> Delta -> Velocity -> Position
  player.delta = Vector.multiplied(player.direction, player.max_thrust * dt)
  player.velocity = Vector.add(player.velocity, player.delta)

  -- Decay velocity
  Player.apply_drag_to_velocity(player, dt)

  player.position = Vector.add(player.position, player.velocity)
end

---@param player Player.State
---@param dt number
function Player.update(player, dt)
  Player.update_from_mouse_input(player, dt)
  Player.update_rotation(player, dt)
  Player.update_sightlines(player, dt)
  Player.update_from_keyboard(player, dt)
  Player.update_movement(player, dt)
end

---@param player Player.State
---@param zindex? number default 64
function Player.calculate_shadow_position(player, zindex)
  zindex = zindex or Player.SHADOW_ZINDEX
  ---@type Usagi.Vec2
  return {
    x = player.camera.position.x - zindex - usagi.SPRITE_SIZE / 2,
    y = player.camera.position.y + zindex - usagi.SPRITE_SIZE / 2,
  }
end

---@param player Player.State
---@param zindex? number default 64
---@param opacity? number default 0.1
function Player.draw_player_shadow(player, zindex, opacity)
  zindex = zindex or Player.SHADOW_ZINDEX
  opacity = opacity or Player.SHADOW_BASE_OPACITY
  local shadow_position = Player.calculate_shadow_position(player, zindex)
  gfx.spr_ex(
    1,
    shadow_position.x,
    shadow_position.y,
    false,
    false,
    player.rotation + math.pi / 2,
    gfx.COLOR_BLACK,
    opacity
  )
end




---@param player Player.State
---@param dt number
function Player.draw_player_trail(player, dt)
  -- Rotating player sprite, not sure about camera lag yet...
  -- (the maths will suck)
  local trail_color = gfx.COLOR_BLUE
  local trail_opacity = 0.1

  gfx.spr_ex(
    1,
    player.camera.position.x - player.velocity.x * 0.5 - usagi.SPRITE_SIZE / 2,
    player.camera.position.y - player.velocity.y * 0.5 - usagi.SPRITE_SIZE / 2,
    false,
    false,
    player.rotation + math.pi / 2,
    trail_color,
    trail_opacity
  )

  gfx.spr_ex(
    1,
    player.camera.position.x - player.velocity.x - usagi.SPRITE_SIZE / 2,
    player.camera.position.y - player.velocity.y - usagi.SPRITE_SIZE / 2,
    false,
    false,
    player.rotation + math.pi / 2,
    trail_color,
    trail_opacity
  )
end

---@param player Player.State
---@param dt number
function Player.draw_main_sprite(player, dt)
  -- Rotating player sprite, not sure about camera lag yet...
  -- (the maths will suck)

  gfx.spr_ex(
    1,
    player.camera.position.x - usagi.SPRITE_SIZE / 2,
    player.camera.position.y - usagi.SPRITE_SIZE / 2,
    false,
    false,
    player.rotation + math.pi / 2,
    gfx.COLOR_TRUE_WHITE, 1.0
  )
end

---@param sightlines? Player.Sightlines
---@param dt number
function Player.draw_sightlines(sightlines, dt)
  if not sightlines then
    return -- Sorry, nothing to draw!
  end

  -- Drawing the sight lines (visual guide only)
  gfx.line_ex(
    sightlines.left.startpoint.x,
    sightlines.left.startpoint.y,
    sightlines.left.endpoint.x,
    sightlines.left.endpoint.y,
    1,
    gfx.COLOR_RED, 0.25
  )
  gfx.line_ex(
    sightlines.right.startpoint.x,
    sightlines.right.startpoint.y,
    sightlines.right.endpoint.x,
    sightlines.right.endpoint.y,
    1,
    gfx.COLOR_RED, 0.25
  )
end

---@param mouse Player.Mouse
---@param dt number
function Player.draw_targeting_circle(mouse, dt)
  -- Drawing the mouse cursor
  -- gfx.circ_fill(State.mouse.position.x, State.mouse.position.y, 4, gfx.COLOR_RED, 0.5)
  gfx.circ(mouse.position.x, mouse.position.y,
    -- TODO: consider making this a constant and sharing with the sightline endpoint radius?
    util.lerp(16, 64, mouse.distance_from_player / (usagi.GAME_W / 2)),
    gfx.COLOR_RED,
    0.25)
end

---@param player Player.State
---@param dt number
function Player.draw(player, dt)
  -- Player.draw_player_trail(player, dt)
  Player.draw_main_sprite(player, dt)
  Player.draw_sightlines(player.sightlines, dt)
  Player.draw_targeting_circle(player.mouse, dt)
end

return Player
