local Util = require('core.util')
local Player = {}


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

---@class Player.State
---@field rotation number
---@field position Usagi.Vec2
---@field direction Usagi.Vec2
---@field velocity Usagi.Vec2
---@field inertia Usagi.Vec2
---@field mouse Player.Mouse
---@field sightlines? Player.Sightlines
---@field camera Player.Camera


function Player.init()
  ---@type Player.State
  return {
    position = { x = 0, y = 0 },
    direction = { x = 0, y = 0 },
    velocity = { x = 0, y = 0 },
    inertia = { x = 0, y = 0 },
    rotation = 3.14 / 4,
    camera = {
      position = {
        x = usagi.GAME_W / 2 - usagi.SPRITE_SIZE / 2,
        y = usagi.GAME_H / 2 - usagi.SPRITE_SIZE / 2
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

  local mouse_x_offset = (default_camera_x - mouse_x) * 0.1
  local mouse_y_offset = (default_camera_y - mouse_y) * 0.1
  player.camera.position = {
    x = usagi.GAME_W / 2 - usagi.SPRITE_SIZE / 2 + mouse_x_offset,
    y = usagi.GAME_H / 2 - usagi.SPRITE_SIZE / 2 + mouse_y_offset
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
function Player.update(player, dt)
  Player.update_from_mouse_input(player, dt)
  Player.update_rotation(player, dt)
  Player.update_sightlines(player, dt)
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
  Player.draw_main_sprite(player, dt)
  Player.draw_sightlines(player.sightlines, dt)
  Player.draw_targeting_circle(player.mouse, dt)
end

return Player
