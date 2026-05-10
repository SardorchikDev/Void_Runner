PlayArea = class('PlayArea', Entity)
PlayArea.static.SIZE = 200

function PlayArea:initialize()
  Entity.initialize(self, 'playarea', 0, vector(0, 0))
  self.time = 0
end

function PlayArea:draw()
  Entity.draw(self)

  local pulse = math.sin(self.time * 2) * 0.15 + 0.85

  love.graphics.setLineStyle('smooth')

  love.graphics.setColor(0.1, 0.3, 0.5, 0.15)
  love.graphics.setLineWidth(20)
  love.graphics.rectangle('line', -PlayArea.SIZE/2 - 8, -PlayArea.SIZE/2 - 8,
    PlayArea.SIZE + 16, PlayArea.SIZE + 16)

  love.graphics.setColor(0.15, 0.4, 0.6, 0.3)
  love.graphics.setLineWidth(10)
  love.graphics.rectangle('line', -PlayArea.SIZE/2 - 4, -PlayArea.SIZE/2 - 4,
    PlayArea.SIZE + 8, PlayArea.SIZE + 8)

  love.graphics.setColor(0.3, 0.7, 1.0, 0.6 * pulse)
  love.graphics.setLineWidth(2)
  love.graphics.rectangle('line', -PlayArea.SIZE/2, -PlayArea.SIZE/2, PlayArea.SIZE, PlayArea.SIZE)

  love.graphics.setColor(0.3, 0.8, 1.0, 0.8 * pulse)
  love.graphics.setLineWidth(1)
  love.graphics.rectangle('line', -PlayArea.SIZE/2 + 2, -PlayArea.SIZE/2 + 2,
    PlayArea.SIZE - 4, PlayArea.SIZE - 4)

  local cornerSize = 15
  local inset = 5

  love.graphics.setColor(0.4, 0.9, 1.0, 1.0 * pulse)
  love.graphics.setLineWidth(3)

  love.graphics.line(-PlayArea.SIZE/2, -PlayArea.SIZE/2 + cornerSize, -PlayArea.SIZE/2, -PlayArea.SIZE/2)
  love.graphics.line(-PlayArea.SIZE/2, -PlayArea.SIZE/2, -PlayArea.SIZE/2 + cornerSize, -PlayArea.SIZE/2)

  love.graphics.line(PlayArea.SIZE/2 - cornerSize, -PlayArea.SIZE/2, PlayArea.SIZE/2, -PlayArea.SIZE/2)
  love.graphics.line(PlayArea.SIZE/2, -PlayArea.SIZE/2, PlayArea.SIZE/2, -PlayArea.SIZE/2 + cornerSize)

  love.graphics.line(PlayArea.SIZE/2, PlayArea.SIZE/2 - cornerSize, PlayArea.SIZE/2, PlayArea.SIZE/2)
  love.graphics.line(PlayArea.SIZE/2, PlayArea.SIZE/2, PlayArea.SIZE/2 - cornerSize, PlayArea.SIZE/2)

  love.graphics.line(-PlayArea.SIZE/2 + cornerSize, PlayArea.SIZE/2, -PlayArea.SIZE/2, PlayArea.SIZE/2)
  love.graphics.line(-PlayArea.SIZE/2, PlayArea.SIZE/2, -PlayArea.SIZE/2, PlayArea.SIZE/2 - cornerSize)
end

function PlayArea:update(dt)
  self.time = self.time + dt
end
