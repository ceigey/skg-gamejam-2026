local Vector = require('core.vector')
local Camera = require('core.camera')
local Shadow = require('core.shadow')
local Util = require('core.util')


local Enemy = {}

Enemy.DRAW_ROTATION_OFFSET =  math.pi / 2

---@enum (key) Enemy.Type
Enemy.Type = {
  SCOUT = "SCOUT",
  ARROWHEAD = "ARROWHEAD",
  RESUPPLIER = "RESUPPLIER",
  SNIPER = "SNIPER",
  BUNKER = "BUNKER",
  TOMBSTONE = "TOMBSTONE",
}

---@enum Enemy.DefaultSprite
Enemy.DefaultSprite = {
  SCOUT = 41,
  ARROWHEAD = 42,
  RESUPPLIER = 43,
  SNIPER = 44,
  BUNKER = 45,
  TOMBSTONE = 46,
}

---@class Enemy.Definition.Cannon
---@field fire_type? "ORB" | "CANNON_VOLLEY" | "BEAM_CANNON"
---@field warn_on_fire? boolean -- true if BEAM_CANNON or a sustained volley (>=30x?)
---@field volley_size? number -- 1 by default. Default: 10x
---@field volley_fire_delay? number -- seconds. Default: 0.2s (similar to player)
---@field fire_charge_delay? number -- seconds. Default: 0s
---@field fire_delay? number -- seconds


---@class Enemy.Definition.AOE
---@field radius number -- e.g. 64px radius
---@field procs_per_second number
---@field player_damage_per_proc number
---@field ally_heal_per_proc number
---@field player_speed_modifier number
---@field ally_speed_modifier number

---@class Enemy.Definition
---@field sprite_index Enemy.DefaultSprite
---@field normal_hitboxes Hitbox.Definition[] -- modifiers can take effect
---@field initial_max_thrust number -- px/s
---@field normal_drag number -- probably x0.8 (80% loss) per tick to drift around player
---@field base_hp number -- starting hp, can be reinforced in later waves
--- And of course, all the firing stuff:
---@field cannon? Enemy.Definition.Cannon
---@field aoes? Enemy.Definition.AOE[]
---@field max_rotation_per_tick? number


---@type table<Enemy.Type, Enemy.Definition>
Enemy.Definitions = {
  ---@type Enemy.Definition
  SCOUT = {
    sprite_index = Enemy.DefaultSprite.SCOUT,
    base_hp = 10,
    initial_max_thrust = 15,
    normal_drag = 0.97,
    normal_hitboxes = {
      {
        bounds = { x = 0, y = 0, r = 8 }
      },
    },
    cannon = {
      fire_type = "ORB",
      fire_delay = 5.0, -- seconds
    }
  },
  ---@type Enemy.Definition
  ARROWHEAD = {
    sprite_index = Enemy.DefaultSprite.ARROWHEAD,
    base_hp = 5,
    initial_max_thrust = 25,
    normal_drag = 0.95,
    normal_hitboxes = {
      {
        bounds = { x = 0, y = 0, r = 6 }
      },
    },
    cannon = {
      fire_type = "CANNON_VOLLEY",
      volley_size = 5,
      fire_delay = 5.0,
      volley_fire_delay = 1.0,
    }
  },
  ---@type Enemy.Definition
  RESUPPLIER = {
    sprite_index = Enemy.DefaultSprite.RESUPPLIER,
    base_hp = 100,
    initial_max_thrust = 10,
    normal_drag = 0.97,
    max_rotation_per_tick = math.pi / 64,
    normal_hitboxes = {
      {
        bounds = { x = -10, y = -12, w = 8, h = 8 },
        damage_multiplier = 0, -- invincible
      },
      {
        bounds = { x = 2, y = -12, w = 8, h = 8 },
        damage_multiplier = 0, -- invincible
      },
      {
        bounds = { x = 0, y = 0, r = 6 },
        damage_multiplier = 1.5, -- weakspot
      },
    },
  },
  ---@type Enemy.Definition
  SNIPER = {
    sprite_index = Enemy.DefaultSprite.SNIPER,
    base_hp = 50,
    initial_max_thrust = 25,
    normal_drag = 0.9,
    normal_hitboxes = {
      {
        bounds = { x = 0, y = 0, r = 8 },
      }
    },
    cannon = {
      fire_type = "CANNON_VOLLEY",
      volley_size = 5,
      fire_delay = 5.0,
      volley_fire_delay = 1.0,
    }
  },
  ---@type Enemy.Definition
  BUNKER = {
    sprite_index = Enemy.DefaultSprite.BUNKER,
    base_hp = 2000,
    initial_max_thrust = 15,
    normal_drag = 0.9,
    normal_hitboxes = {
      {
        -- TODO
        bounds = { x = -11, y = 12, w = 22, h = 26 },
      }
    }
  },
  ---@type Enemy.Definition
  TOMBSTONE = {
    sprite_index = Enemy.DefaultSprite.TOMBSTONE,
    base_hp = 4000,
    initial_max_thrust = 15,
    normal_drag = 0.9,
    normal_hitboxes = {
      {
        -- TODO
        bounds = { x = -11, y = 12, w = 22, h = 26 },
      }
    }
  },
}

---@class Enemy.State.Cannon
---@field volley_remaining number
---@field volley_fire_timer number
---@field fire_charge_timer number
---@field fire_timer number


---@class Enemy.State.AOE
---@field delay_since_last_proc number

---@class Enemy.State
---@field type Enemy.Type
---@field max_hp number -- maximum HP accruable
---@field hp number -- remaining HP
---@field is_chasing_offscreen boolean -- if we're chasing the player off screen aka speed boost
--- All of the following are shared with player
--- Reuse opportunity?
---@field rotation number
---@field position Usagi.Vec2
---@field direction Usagi.Vec2
---@field velocity Usagi.Vec2
---@field delta Usagi.Vec2
---@field camera Entity.Camera
--- /end shared with player...
---@field max_thrust number
---@field aoes Enemy.State.AOE[]
---@field cannon Enemy.State.Cannon
--- some randomness
---@field random_direction_bias number
---@field random_direction_bias_timer number
---@field timer number

---Get the enemy definition based on either the state
---or the type identifier
---@param enemy Enemy.State | Enemy.Type
---@return Enemy.Definition
function Enemy.definition(enemy)
  if type(enemy) == "string" then
    return Enemy.Definitions[enemy]
  end
  return Enemy.Definitions[enemy.type]
end

---comment
---@param enemy_type Enemy.Type
function Enemy.init(enemy_type)
  local definition = Enemy.Definitions[enemy_type]
  local cannon = definition.cannon or {}
  ---@type Enemy.State
  return {
    hp = definition.base_hp,
    max_hp = definition.base_hp,
    max_thrust = definition.initial_max_thrust,
    aoes = {
      {
        delay_since_last_proc = 0,
      }
    },
    is_chasing_offscreen = false,
    cannon = {
      fire_charge_timer = cannon.fire_charge_delay,
      fire_timer = cannon.fire_delay,
      volley_fire_timer = cannon.volley_fire_delay,
      volley_remaining = cannon.volley_size,
    },
    delta = { x = 0, y = 0 },
    direction = { x = 0, y = 0 },
    position = { x = 0, y = 0 },
    rotation = math.pi / 2,
    type = enemy_type,
    velocity = { x = 0, y = 0},
    camera = {
      position = { x = 0, y = 0 },
      zoom_factor = 1.0,
    },
    random_direction_bias = 0,
    random_direction_bias_timer = 0,
    timer = 0,
  }
end

---For when you just need the enemy to appear somewhere
---@param enemy Enemy.State
---@param position Usagi.Vec2
function Enemy.teleport(enemy, position)
  enemy.position = position
end


---comment
---@param enemy Enemy.State
---@param player Player.State
---@param dt number
function Enemy.update_aim(enemy, player, dt)
  local definition = Enemy.definition(enemy)
  local max_rotation_per_tick = definition.max_rotation_per_tick or math.pi / 32
  local target_rotation = math.atan(
    player.position.y - enemy.position.y,
    player.position.x - enemy.position.x
  )
  enemy.rotation = Util.clamp_radians(target_rotation, enemy.rotation, max_rotation_per_tick)
  enemy.random_direction_bias_timer = enemy.random_direction_bias_timer + dt
  if enemy.random_direction_bias_timer > 0.5 + math.random(-10, 10) / 100 then
    enemy.random_direction_bias = math.pi / 8 * math.random(-10, 10) / 10
    enemy.random_direction_bias_timer = 0
  end
end


---comment
---@param enemy Enemy.State
---@param dt number
function Enemy.draw_main_sprite(enemy, dt)
  local definition = Enemy.definition(enemy)
  gfx.spr_ex(
    definition.sprite_index,
    (enemy.camera.position.x - usagi.SPRITE_SIZE / 2),
    (enemy.camera.position.y - usagi.SPRITE_SIZE / 2),
    false,
    false,
    enemy.rotation + Enemy.DRAW_ROTATION_OFFSET,
    gfx.COLOR_TRUE_WHITE,
    1.0
  )
end

---TODO: reuse across player and enemies?
---Perfect case for --@cast x Movable maybe
---@param enemy Enemy.State
---@param camera any
function Enemy.update_entity_camera(enemy, camera)
  enemy.camera.position = Camera.world_to_screen(camera, enemy.position)
  enemy.camera.zoom_factor = Camera.zindexed_zoom_factor(camera, 1.0) -- TODO: zindex
  enemy.camera.offset = camera.lookahead_offset
end

-- TODO share with player
---@param enemy Enemy.State
---@param dt number
function Enemy.apply_drag_to_velocity(enemy, dt)
  local definition = Enemy.definition(enemy)
  enemy.velocity = Vector.multiplied(enemy.velocity, definition.normal_drag)
  if math.abs(enemy.velocity.x) < 0.1 then
    enemy.velocity.x = 0
  end
  if math.abs(enemy.velocity.y) < 0.1 then
    enemy.velocity.y = 0
  end
end
---comment
---@param enemy Enemy.State
---@param player Player.State
---@param dt number
function Enemy.update_movement(enemy, player, dt)
  local definition = Enemy.definition(enemy)
  enemy.direction = util.vec_from_angle(enemy.rotation + enemy.random_direction_bias) -- NOT SHARED WITH PLAYER!
  enemy.delta = Vector.multiplied(enemy.direction, enemy.max_thrust * dt)
  enemy.velocity = Vector.add(enemy.velocity, enemy.delta)

  -- Decay velocity
  Enemy.apply_drag_to_velocity(enemy, dt)
  enemy.position = Vector.add(enemy.position, enemy.velocity)

end



---comment
---@param enemy Enemy.State
---@param player Player.State
---@param dt number
function Enemy.update(enemy, player, dt)
  enemy.timer = enemy.timer + dt
  Enemy.update_aim(enemy, player, dt)
  Enemy.update_movement(enemy, player, dt)
end

---@param enemy Enemy.State
---@param zindex? number default 64
function Enemy.calculate_shadow_position(enemy, zindex)
  zindex = zindex or Shadow.RIGHT_ANGLE_OFFSET
  ---@type Usagi.Vec2
  return {
    x = enemy.camera.position.x + (Shadow.X_DIRECTION * zindex) - usagi.SPRITE_SIZE / 2,
    y = enemy.camera.position.y + (Shadow.Y_DIRECTION * zindex) - usagi.SPRITE_SIZE / 2,
  }
end


---@param enemy Enemy.State
---@param zindex? number default 64
---@param opacity? number default 0.1
function Enemy.draw_shadow(enemy, zindex, opacity)
  local definition = Enemy.definition(enemy)
  zindex = zindex or Shadow.RIGHT_ANGLE_OFFSET -- TODO: no zindex
  opacity = opacity or Shadow.OPACITY
  local shadow_position = Enemy.calculate_shadow_position(enemy, zindex)
  gfx.spr_ex(
    definition.sprite_index,
    shadow_position.x,
    shadow_position.y,
    false,
    false,
    enemy.rotation + Enemy.DRAW_ROTATION_OFFSET,
    gfx.COLOR_BLACK,
    opacity
  )
end

---comment
---@param enemy Enemy.State
---@param dt number
function Enemy.draw(enemy, dt)
  Enemy.draw_main_sprite(enemy, dt)
end

return Enemy
