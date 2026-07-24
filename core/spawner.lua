local Enemy = require('core.enemy')
local Player = require('core.player')

--- Currently just designed for a simple demo loop
local Spawner = {}

Spawner.SPAWN_DELAY = 10
Spawner.MAX_ENEMIES = 200

Spawner.ENEMY_RATIO = {
  SCOUT = 2,
  ARROWHEAD = 6,
  RESUPPLIER = 1,
}


---@class Spawner.State
---@field timer number seconds elapsed
---@field spawn_cooldown number seconds elapsed since last spawn
---@field iteration number


---@param spawner Spawner.State
---@param enemies Enemy.State[]
---@param player Player.State
function Spawner.update(spawner, enemies, player, dt)
  spawner.timer = spawner.timer + dt
  spawner.spawn_cooldown = spawner.spawn_cooldown - dt
  if #enemies < Spawner.MAX_ENEMIES and spawner.spawn_cooldown <= 0 then
    local x = math.floor(player.position.x)
    local y = math.floor(player.position.y)
    local spawn_multiplier = spawner.iteration / 2


    -- TODO: Figure out how to spawn outside of player reach...
    for i = 1, math.floor(Spawner.ENEMY_RATIO.SCOUT * spawn_multiplier), 1 do
      local new_enemy = Enemy.init("SCOUT")
      Enemy.teleport(new_enemy, {
        x = math.random(x - usagi.GAME_W, x + usagi.GAME_W),
        y = math.random(y - usagi.GAME_H, y + usagi.GAME_H),
      })
      table.insert(enemies, new_enemy)
    end
    for i = 1, math.floor(Spawner.ENEMY_RATIO.ARROWHEAD * spawn_multiplier), 1 do
      local new_enemy = Enemy.init("ARROWHEAD")
      Enemy.teleport(new_enemy, {
        x = math.random(x - usagi.GAME_W, x + usagi.GAME_W),
        y = math.random(y - usagi.GAME_H, y + usagi.GAME_H),
      })
      table.insert(enemies, new_enemy)
    end
    for i = 1, math.floor(Spawner.ENEMY_RATIO.RESUPPLIER * spawn_multiplier), 1 do
      local new_enemy = Enemy.init("RESUPPLIER")
      Enemy.teleport(new_enemy, {
        x = math.random(x - usagi.GAME_W, x + usagi.GAME_W),
        y = math.random(y - usagi.GAME_H, y + usagi.GAME_H),
      })
      table.insert(enemies, new_enemy)
    end

    -- finally...
    spawner.iteration = spawner.iteration + 1
    spawner.spawn_cooldown = Spawner.SPAWN_DELAY
  end
end


return Spawner
