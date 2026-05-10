MainMenu = class('MainMenu', GameState)

function MainMenu:initialize()
  GameState.initialize(self)
  self.time = 0

  self:resize(love.graphics.getWidth(), love.graphics.getHeight())
end

function MainMenu:resize(w, h)
  self.w = w
  self.h = h
  self.scale = math.min(w / 1280, h / 720)

  self.title_font = love.graphics.newFont("assets/roboto.ttf", 72 * self.scale)
  self.title_font:setFilter('linear', 'linear', 0)

  self.btn_font = love.graphics.newFont("assets/roboto.ttf", 36 * self.scale)
  self.btn_font:setFilter('linear', 'linear', 0)

  self.small_font = love.graphics.newFont("assets/roboto.ttf", 18 * self.scale)
  self.small_font:setFilter('linear', 'linear', 0)
end

function MainMenu:update(dt)
  GameState.update(self, dt)
  self.time = self.time + dt
end

function MainMenu:keypressed(key)
  if key == 'return' or key == 'space' then
    GameState.switchTo(PlayState())
  elseif key == 'escape' then
    love.event.quit()
  end
end

function MainMenu:overlay()
  local w, h = self.w, self.h
  local cx, cy = w / 2, h / 2
  local s = self.scale

  for y = 0, h, 6 do
    local t = y / h
    love.graphics.setColor(0.02 + t * 0.04, 0.02 + t * 0.04, 0.06 + t * 0.12)
    love.graphics.rectangle('fill', 0, y, w, 6)
  end

  for i = 1, 80 do
    local a = (i / 80) * math.pi * 2 + self.time * 0.08
    local r = 120 * s + math.sin(self.time + i) * 25 * s
    local sx = cx + math.cos(a) * r
    local sy = cy - 40 * s + math.sin(a * 2) * r * 0.4
    local sz = 0.8 + math.sin(self.time * 3 + i * 0.7) * 0.4

    if i % 4 == 0 then
      love.graphics.setColor(0.35, 0.65, 1.0, 0.35)
    elseif i % 4 == 1 then
      love.graphics.setColor(0.25, 0.45, 0.85, 0.25)
    elseif i % 4 == 2 then
      love.graphics.setColor(0.45, 0.75, 0.55, 0.2)
    else
      love.graphics.setColor(0.5, 0.85, 1.0, 0.15)
    end
    love.graphics.circle('fill', sx, sy, sz * s * 1.5)
  end

  local pulse = math.sin(self.time * 2.5) * 0.08 + 0.92

  love.graphics.setColor(0.15, 0.45, 1.0, 0.2 * pulse)
  love.graphics.setFont(self.title_font)
  love.graphics.printf("RETURN BY DEATH", 0, cy - 120 * s, w, "center")

  love.graphics.setColor(0.3, 0.65, 1.0, 1)
  love.graphics.printf("RETURN BY DEATH", 0, cy - 120 * s, w, "center")

  love.graphics.setColor(0.4, 0.7, 1.0, 0.6)
  love.graphics.setLineWidth(2 * s)
  local lw = 140 * s
  love.graphics.line(cx - lw, cy - 70 * s, cx + lw, cy - 70 * s)

  local btnW = 260 * s
  local btnH = 56 * s
  local btnGap = 18 * s
  local startY = cy + 10 * s

  local function drawButton(text, bx, by, bw, bh, isHovered)
    love.graphics.setColor(0.06, 0.06, 0.14, 0.85)
    love.graphics.rectangle('fill', bx, by, bw, bh)

    love.graphics.setColor(0.15, 0.35, 0.7, 0.6)
    love.graphics.setLineWidth(2 * s)
    love.graphics.rectangle('line', bx, by, bw, bh)

    if isHovered then
      love.graphics.setColor(0.18, 0.45, 0.95, 0.3)
      love.graphics.rectangle('fill', bx + 2, by + 2, bw - 4, bh - 4)
    end

    local glow = isHovered and pulse or 0.8
    love.graphics.setColor(0.25, 0.7, 1.0, glow)
    love.graphics.setFont(self.btn_font)
    love.graphics.printf(text, bx, by + bh / 2 - 14 * s, bw, "center")
  end

  local bx = cx - btnW / 2
  local playBy = startY
  local exitBy = startY + btnH + btnGap

  drawButton("PLAY", bx, playBy, btnW, btnH, self.hovered == 1 or not self.hovered)
  drawButton("EXIT", bx, exitBy, btnW, btnH, self.hovered == 2)

  love.graphics.setColor(0.3, 0.5, 0.7, 0.4)
  love.graphics.setFont(self.small_font)
  love.graphics.printf("ARROW KEYS / ENTER / ESC", 0, h - 25 * s, w, "center")
end

function MainMenu:mousemoved(x, y)
  local s = self.scale
  local btnW = 260 * s
  local btnH = 56 * s
  local btnGap = 18 * s
  local cx = self.w / 2
  local startY = self.h / 2 + 10 * s
  local bx = cx - btnW / 2

  self.hovered = nil
  if x >= bx and x <= bx + btnW then
    if y >= startY and y <= startY + btnH then
      self.hovered = 1
    elseif y >= startY + btnH + btnGap and y <= startY + btnH * 2 + btnGap then
      self.hovered = 2
    end
  end
end

function MainMenu:mousepressed(x, y, button)
  if button ~= 1 then return end
  local s = self.scale
  local btnW = 260 * s
  local btnH = 56 * s
  local btnGap = 18 * s
  local cx = self.w / 2
  local startY = self.h / 2 + 10 * s
  local bx = cx - btnW / 2

  if x >= bx and x <= bx + btnW then
    if y >= startY and y <= startY + btnH then
      GameState.switchTo(PlayState())
    elseif y >= startY + btnH + btnGap and y <= startY + btnH * 2 + btnGap then
      love.event.quit()
    end
  end
end

function MainMenu:touchpressed(id, x, y)
  self:mousepressed(x, y, 1)
end

return MainMenu