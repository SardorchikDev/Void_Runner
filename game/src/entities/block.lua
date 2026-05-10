Block = class('Block', Entity)

function Block:initialize(center, angle, size, velocity, color)
    Entity.initialize(self, 'obstacle', -1, center)
    self.angle = angle
    self.size = size
    self.velocity = velocity
    self.color = color

    self.collision_shape = collision.newPolygonShape(-size.x/2, -size.y/2,
      -size.x/2, size.y/2, size.x/2, size.y/2, size.x/2, -size.y/2)

    self:updateCollisionShape()

    self.life = 0
end

function Block:draw()
  local r, g, b = self.color.r, self.color.g, self.color.b
  local edgeDist = math.min(self.size.x, self.size.y) * 0.15
  local lifeFactor = math.min(1, self.life / 5)
  local flash = lifeFactor < 0.3 and (math.sin(self.life * 20) * 0.5 + 0.5) or 0

  love.graphics.setLineStyle('smooth')

  love.graphics.setColor(r * 0.2, g * 0.2, b * 0.2, 0.3)
  love.graphics.push()
  love.graphics.translate(self.pos:unpack())
  love.graphics.rotate(self.angle)
  love.graphics.setLineWidth(12)
  love.graphics.rectangle('line', -self.size.x/2 - 4, -self.size.y/2 - 4, self.size.x + 8, self.size.y + 8)
  love.graphics.pop()

  love.graphics.setColor(r * 0.4, g * 0.4, b * 0.4, 0.5)
  love.graphics.push()
  love.graphics.translate(self.pos:unpack())
  love.graphics.rotate(self.angle)
  love.graphics.setLineWidth(6)
  love.graphics.rectangle('line', -self.size.x/2 - 2, -self.size.y/2 - 2, self.size.x + 4, self.size.y + 4)
  love.graphics.pop()

  love.graphics.setColor(r * 0.6 + flash * 0.4, g * 0.6 + flash * 0.4, b * 0.6 + flash * 0.4, 0.9)
  love.graphics.push()
  love.graphics.translate(self.pos:unpack())
  love.graphics.rotate(self.angle)
  love.graphics.setLineWidth(2)
  love.graphics.rectangle('line', -self.size.x/2, -self.size.y/2, self.size:unpack())
  love.graphics.pop()

  love.graphics.setColor(r, g, b, 0.4)
  love.graphics.push()
  love.graphics.translate(self.pos:unpack())
  love.graphics.rotate(self.angle)
  love.graphics.rectangle('fill', -self.size.x/2 + edgeDist, -self.size.y/2 + edgeDist,
    self.size.x - edgeDist*2, self.size.y - edgeDist*2)
  love.graphics.pop()

  love.graphics.setColor(r, g, b, 1)
  love.graphics.push()
  love.graphics.translate(self.pos:unpack())
  love.graphics.rotate(self.angle)
  love.graphics.rectangle('fill', -self.size.x/2 + edgeDist*2, -self.size.y/2 + edgeDist*2,
    self.size.x - edgeDist*4, self.size.y - edgeDist*4)
  love.graphics.pop()
end

function Block:update(dt)
  self.pos = self.pos + self.velocity*dt
  self:updateCollisionShape()

  self.life = self.life + dt
  if self.life > 30 then
    self:destroy()
  end
end

function Block:updateCollisionShape()
  self.collision_shape:moveTo(self.pos:unpack())
  self.collision_shape:setRotation(self.angle)
end

function Block:collidesWith(player_shape)
  return self.collision_shape:collidesWith(player_shape)
end
