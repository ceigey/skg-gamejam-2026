local Particle = require('core.particle')
local Collision = {}


---comment
---@param player_bullets PlayerBullet.State[]
---@param enemies Enemy.State[]
---@param particles Particle.State[]
function Collision.player_bullets_vs_enemies(player_bullets, enemies, particles)
  for b, bullet in ipairs(player_bullets) do
    for e, enemy in ipairs(enemies) do
      for h, hitbox in ipairs(enemy.hitboxes) do
        local collided = false
        local bounds = hitbox.bounds
        if hitbox.bounds.r then
          ---@cast bounds Usagi.Circ
          collided = util.point_in_circ(bullet.position, bounds)
        else
          ---@cast bounds Usagi.Rect
          collided = util.point_in_rect(bullet.position, bounds)
        end
        if collided then
          sfx.play("collision")
          bullet.hp = bullet.hp - 1
          enemy.hp = enemy.hp - 1 * (hitbox.damage_multiplier or 1.0)
          table.insert(particles, Particle.init({
            {
              shape = { x = bullet.position.x, y = bullet.position.y, r = 4 },
              alpha = 0.5,
              color = gfx.COLOR_PINK,
            },
            {
              shape = { x = bullet.position.x, y = bullet.position.y, r = 4 },
              alpha = 0.5,
              color = gfx.COLOR_PINK,
            },
            {
              shape = { x = bullet.position.x, y = bullet.position.y, r = 4 },
              alpha = 0.25,
              color = gfx.COLOR_PINK,
            },
            {
              shape = { x = bullet.position.x, y = bullet.position.y, r = 4 },
              alpha = 0.25,
              color = gfx.COLOR_PINK,
            }
          }))
          if enemy.hp <= 0 then
            table.insert(particles, Particle.init({
              {
                shape = { x = enemy.position.x, y = enemy.position.y, r = 24 },
                alpha = 0.75,
                color = gfx.COLOR_ORANGE,
              },
              {
                shape = { x = enemy.position.x, y = enemy.position.y, r = 24 },
                alpha = 0.75,
                color = gfx.COLOR_ORANGE,
              },
              {
                shape = { x = enemy.position.x, y = enemy.position.y, r = 24 },
                alpha = 0.5,
                color = gfx.COLOR_RED,
              },
              {
                shape = { x = enemy.position.x, y = enemy.position.y, r = 24 },
                alpha = 0.5,
                color = gfx.COLOR_RED,
              }
            }))
            table.insert(particles, Particle.init({
              {
                shape = { x = bullet.position.x, y = bullet.position.y, r = hitbox.bounds.r },
                alpha = 0.75,
                color = gfx.COLOR_PINK,
              },
              {
                shape = { x = bullet.position.x, y = bullet.position.y, r = hitbox.bounds.r },
                alpha = 0.75,
                color = gfx.COLOR_PINK,
              },
              {
                shape = { x = bullet.position.x, y = bullet.position.y, r = hitbox.bounds.r },
                alpha = 0.5,
                color = gfx.COLOR_PINK,
              },
              {
                shape = { x = bullet.position.x, y = bullet.position.y, r = hitbox.bounds.r },
                alpha = 0.5,
                color = gfx.COLOR_PINK,
              }
            }))
          end
        end
      end
    end
  end
end

return Collision
