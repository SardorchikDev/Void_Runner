local Dead = PlayState:addState('Dead')

function Dead:enteredState()
  self.dead_time = 0

  if ANDROID or IOS then
    love.system.unlockAchievement(IDS.ACH_PLAY_A_GAME)
    love.system.submitScore(IDS.LEAD_SURVIVAL_TIME, self.score * 100)
  end

  PlayState.MUSIC:stop()
  if self.newrecord then
    love.filesystem.write("bestscore", tostring(self.score))
    self.bestscore = self.score
  end

  if PLAY_RECORDING then
    Timer.after(3, function() love.event.quit(0) end)
  end

  love.mouse.setVisible(true)
  love.mouse.setGrabbed(false)
  self:showButtons()
end

function Dead:update(dt)
  self.time = self.time + dt
  self.dead_time = self.dead_time + dt

  self.newrecord_visible = (self.time % 1) < 0.5
  self.player:update(dt)

  self.white_fader.time = self.white_fader.time + dt
  self:updateButtons(dt)
end

function Dead:overlay()
  PlayState.overlay(self)

  local w, h = love.graphics.getWidth(), love.graphics.getHeight()
  local s = self.scale
  local cx, cy = w / 2, h / 2

  love.graphics.setColor(0, 0, 0, 0.55)
  love.graphics.rectangle('fill', 0, 0, w, h)

  if not self.newrecord then
    DrawBestScore(self)
  end

  love.graphics.setFont(self.instruction_font)
  love.graphics.setColor(1, 0.2, 0.3, 0.9)
  love.graphics.printf("YOU DIED", 0, cy - 45 * s, w, "center")

  love.graphics.setColor(1, 1, 1, 0.9)
  love.graphics.setFont(self.time_font)
  love.graphics.printf(string.format("%.1fs", self.score), 0, cy - 10 * s, w, "center")

  local pulse = math.sin(self.dead_time * 3) * 0.12 + 0.88
  local btnW = 260 * s
  local btnH = 50 * s
  local bx = cx - btnW / 2
  local by = cy + 25 * s

  love.graphics.setColor(0.05, 0.05, 0.12, 0.9)
  love.graphics.rectangle('fill', bx, by, btnW, btnH)
  love.graphics.setColor(0.15, 0.5, 0.8, 0.6)
  love.graphics.setLineWidth(2 * s)
  love.graphics.rectangle('line', bx, by, btnW, btnH)

  love.graphics.setColor(0.3, 0.7, 1.0, pulse)
  love.graphics.setFont(self.best_font)
  love.graphics.printf("TAP TO RETRY", bx, by + btnH / 2 - 14 * s, btnW, "center")

  love.graphics.setFont(self.instruction_font)
  love.graphics.setColor(0.3, 0.5, 0.7, 0.4)
  love.graphics.printf("ESC FOR MENU", 0, h - 15 * s, w, "center")
end

function Dead:touchpressed(id, x, y, dx, dy, pressure)
  PlayState.touchpressed(self, id, x, y, dx, dy, pressure)
  if self.ignore_touch[id] then return end
  self:startGame()
end

function Dead:keypressed(key, scancode, isrepeat)
  if key == 'escape' then
    GameState.switchTo(MainMenu())
    return
  end
  if key == "space" or key == "return" then
    self:startGame()
  end
end