local Vector = require('core.vector')

local PlayerBullet = {}

--- Pixels per second... 480px/s, 640px/s or 720px/s is probably good
--- 480px/s is 8px/frame which helps prevent tunnelling
PlayerBullet.SPEED = 600       -- I think?? previously tried (420px / 30) per frame

PlayerBullet.SPRITE_INDEX = 12 --49 * 12 + 13
PlayerBullet.DRAW_ROTATION_OFFSET = math.pi / 2
PlayerBullet.NORMAL_DRAG = 0.95

---@class PlayerBullet.State
---@field position Usagi.Vec2
---@field hp number
---@field direction Usagi.Vec2
---@field speed number
---@field velocity Usagi.Vec2
---@field player_momentum Usagi.Vec2 -- from player
---@field rotation number -- should correlate to direction! But not necessarily...?
---@field time_elapsed number -- bullet speed will increase over time


---Create a player bullet
---@param position Usagi.Vec2
---@param hp number
---@param rotation number
---@param player_momentum Usagi.Vec2
---@param speed? number
---@param direction? Usagi.Vec2 -- based on rotation if missing
---@return PlayerBullet.State
function PlayerBullet.new(position, hp, rotation, player_momentum, speed, direction)
  direction = direction or util.vec_from_angle(rotation)
  speed = speed or PlayerBullet.SPEED
  return {
    position = position,
    hp = hp,
    rotation = rotation,
    player_momentum = player_momentum,
    direction = direction,
    speed = speed,
    velocity = { x = 0, y = 0 },
    time_elapsed = 0,
  }
end


function PlayerBullet.bounding_box(player)
  ---@type Usagi.Rect
  return {
    x = player.position.x - usagi.GAME_W / 2 - 64,
    y = player.position.y - usagi.GAME_H / 2 - 64,
    w = usagi.GAME_W + 128,
    h = usagi.GAME_H + 128,
  }
end

---@param bullet PlayerBullet.State
---@param player Player.State
function PlayerBullet.in_bounds(bullet, player)
  return util.rect_overlap(
    { x = bullet.position.x, y = bullet.position.y, h = 16, w = 4 },
    PlayerBullet.bounding_box(player)
  )
end

---@param bullet PlayerBullet.State
---@param player Player.State
---@param dt number delta time
function PlayerBullet.update(bullet, player, dt)
  -- bullet.velocity = Vector.multiplied(bullet.direction, PlayerBullet.SPEED * dt)
  if bullet.time_elapsed > 0 then
    bullet.position = Vector.add(bullet.position, bullet.player_momentum)
  end
  bullet.player_momentum = Vector.multiplied(bullet.player_momentum, PlayerBullet.NORMAL_DRAG)
  bullet.time_elapsed = bullet.time_elapsed + dt
  bullet.velocity = Vector.multiplied(bullet.direction, bullet.speed * dt)
  bullet.velocity = Vector.multiplied(bullet.velocity, 1 + bullet.time_elapsed)
  bullet.position = Vector.add(bullet.position, bullet.velocity)
  if not PlayerBullet.in_bounds(bullet, player) then
    print('BULLET CULLED')
    bullet.hp = 0 -- culled
  end
end

---@param bullets PlayerBullet.State[]
---@param player Player.State
---@param dt number delta time
function PlayerBullet.update_all(bullets, player, dt)
  for i = #bullets, 1, -1 do
    local bullet = bullets[i]
    if bullet.hp <= 0 then
      -- remove from game space, collisions and damage will happen elsewhere
      table.remove(bullets, i)
    end
    PlayerBullet.update(bullet, player, dt)
  end
end

---@param bullet PlayerBullet.State
---@param player Player.State
---@param dt number delta time
function PlayerBullet.draw(bullet, player, dt)
  -- https://youtu.be/ZQ8qtAizis4?si=XI_gChcVyF2YBROa&t=234
  -- Sx = Wx - Ox
  local player_bullet_offset = Vector.subtract(bullet.position, player.position)
  --local offset_from_player = Vector.subtract(player.position, bullet.position)
  local camera_position = Vector.add(player_bullet_offset, player.camera.position)
  -- THIS WAS TOO HARD - have to adjust geometry too much aroudn sprite offsets
  -- gfx.spr_ex(
  --   PlayerBullet.SPRITE_INDEX,
  --   camera_position.x - usagi.SPRITE_SIZE/2,
  --   camera_position.y - usagi.SPRITE_SIZE/2,
  --   -- bullet.position.x,
  --   -- bullet.position.y,
  --   false,
  --   false,
  --   bullet.rotation + PlayerBullet.DRAW_ROTATION_OFFSET,
  --   gfx.COLOR_TRUE_WHITE,
  --   1.0
  -- )
  local camera_start = Vector.subtract(camera_position, bullet.velocity)
  gfx.line_ex(
    camera_start.x,
    camera_start.y,
    camera_position.x,
    camera_position.y,
    2,
    gfx.COLOR_ORANGE
  )
  -- gfx.circ_fill(
  --   camera_position.x,
  --   camera_position.y,
  --   1,
  --   gfx.COLOR_YELLOW,
  --   0.5
  -- )
end

---@param bullets PlayerBullet.State[]
---@param player Player.State
---@param dt number delta time
function PlayerBullet.draw_all(bullets, player, dt)
  for i, bullet in ipairs(bullets) do
    PlayerBullet.draw(bullet, player, dt)
  end
  gfx.text("Bullets: " .. usagi.dump(#bullets), 8, 64, gfx.COLOR_BLACK)
end

return PlayerBullet
