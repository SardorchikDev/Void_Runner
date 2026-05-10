PlayState = class('PlayState', GameState)
PlayState:include(Stateful)
PlayState.static.NEWRECORD_SOUND = love.audio.newSource( 'assets/sound/newrecord.wav', 'static' )
PlayState.static.NEWRECORD_SOUND:setVolume(0.2)

PlayState.static.MUSIC = love.audio.newSource('assets/sound/music.mp3', 'static')
PlayState.MUSIC:setLooping(true)
PlayState.MUSIC:setVolume(0.3)
PlayState.static.MUSIC_STARTS = {0, 52.18}


PlayState.static.VMARGIN = 20

function PlayState:initialize()
  self.buttons = {}

  self.signin_button = MenuButton(MenuButton.CONTROLLER, 1.5, function()
    love.system.googlePlayConnect()
  end, false)

  self.leaderboard_button = MenuButton(MenuButton.LEADERBOARDS, 1.5, function()
    love.system.showLeaderboard(IDS.LEAD_SURVIVAL_TIME)
  end, false)

  self.practice_mode_button = MenuButton(MenuButton.MORE, 1.5, function()
    GameState.switchTo(ModeMenu())
  end, false)

  self.achievements_button = MenuButton(MenuButton.ACHIEVEMENTS, 1.5, function()
    love.system.showAchievements()
  end, false)

  if ANDROID then
    table.insert(self.buttons, self.signin_button)
    table.insert(self.buttons, self.leaderboard_button)
    table.insert(self.buttons, self.achievements_button)
  end

  if IOS then
    table.insert(self.buttons, self.leaderboard_button)
    self.leaderboard_button.enabled = true
    table.insert(self.buttons, self.achievements_button)
    self.achievements_button.enabled = true
  end

  GameState.initialize(self)
  self:reset()
  self.cam:lookAt(0, 0)
  self:calculateScale()
  self:gotoState('Initial')

  self.screenEffects = ScreenEffects()

  local saveFileInfo = love.filesystem.getInfo("bestscore")
  if saveFileInfo and saveFileInfo.type == "file" then
    local contents, size = love.filesystem.read("bestscore")
    self.bestscore = tonumber(contents)
  else
    self.bestscore = nil
  end

  self.white_fader = { time = 1.0, duration = 1.0 }

  self.attempts = 0

  -- A table of touches that should be ignored.
  self.ignore_touch = {}
end

function PlayState:flashWhite(duration)
    self.white_fader = { time = 0, duration = duration }
end

function PlayState:reset()
  self.timer:clear()
  self.entities = {}
  self.arena = self:addEntity(PlayArea())
  self.arenashadow = self:addEntity(PlayAreaShadow())
  self.player = self:addEntity(Player())
  self.score = 0.0
  self.newrecord = false

  if CREATE_RECORDING then
    RECORDING = assert(io.open('recording.txt', "w"))

    local seed = os.time()
    math.randomseed(seed)
    RECORDING:write(seed .. "\n")
  end

  if PLAY_RECORDING then
    local rec = love.filesystem.lines('recording.txt')
    RECORDING = function()
      local val = rec()
      return tonumber(val)
    end

    local seed = RECORDING()
    CURRENT_CHECKPOINT = RECORDING()
    math.randomseed(seed)
  end
end

function PlayState:calculateScale()
  local hmargin = 40
  local hscale = love.graphics.getWidth() / (PlayArea.SIZE + 2 * hmargin)

  local vmargin = 100
  local vscale = love.graphics.getHeight() / (PlayArea.SIZE + 2 * vmargin)

  self.scale = math.max(math.min(hscale, vscale), 1)
  self.cam:zoomTo(self.scale)

  self.time_font = love.graphics.newFont("assets/roboto.ttf", 20*self.scale)
  self.time_font:setFilter('nearest', 'nearest', 0)

  self.best_font = love.graphics.newFont("assets/roboto.ttf", 20*self.scale)
  self.best_font:setFilter('nearest', 'nearest', 0)

  self.new_record_font = love.graphics.newFont("assets/roboto.ttf", 20*self.scale)
  self.new_record_font:setFilter('nearest', 'nearest', 0)

  self.instruction_font = love.graphics.newFont("assets/roboto.ttf", 15*self.scale)
  self.instruction_font:setFilter('nearest', 'nearest', 0)

  self.endless_font = love.graphics.newFont("assets/roboto.ttf", 20*self.scale)
  self.endless_font:setFilter('nearest', 'nearest', 0)

  local button_top = 0
  if IOS then
    local left, top, right, bottom = love.window.getSafeAreaInsets()
    button_top = top * love.window.getPixelScale()
  end

  for i, button in ipairs(self.buttons) do
    button.pos.x = love.graphics.getWidth()
    button.pos.y = button_top + 40 * self.scale * i
  end
end

function PlayState:resize(w, h) self:calculateScale() end

function PlayState:keypressed(key, scancode, isrepeat)
  if key == 'escape' then
    if self.paused then
      self.paused = false
      PlayState.MUSIC:play()
      love.mouse.setVisible(false)
      love.mouse.setGrabbed(true)
    else
      self.paused = true
      self.paused_time = 0
      self.paused_selected = 1
      self.paused_buttons = {
        { text = "RESUME", action = function()
            self.paused = false
            PlayState.MUSIC:play()
            love.mouse.setVisible(false)
            love.mouse.setGrabbed(true)
        end },
        { text = "QUIT", action = function() GameState.switchTo(MainMenu()) end }
      }
      PlayState.MUSIC:pause()
      love.mouse.setVisible(true)
      love.mouse.setGrabbed(false)
    end
  end

  if self.paused then
    if key == 'up' or key == 'w' then
      self.paused_selected = math.max(1, self.paused_selected - 1)
    elseif key == 'down' or key == 's' then
      self.paused_selected = math.min(#self.paused_buttons, self.paused_selected + 1)
    elseif key == 'return' or key == 'space' then
      self.paused_buttons[self.paused_selected].action()
    end
  end
end

function PlayState:startGame()
  self:reset()
  self:gotoState('FallingBlocks')
  PlayState.MUSIC:play()

  PlayState.MUSIC:seek(PlayState.MUSIC_STARTS[math.floor(self.attempts / 5) % #PlayState.MUSIC_STARTS + 1])
  self.attempts = self.attempts + 1

  love.mouse.setVisible(false)
  love.mouse.setGrabbed(true)

  self:hideButtons()
end

function PlayState:hideButtons()
  for _, button in ipairs(self.buttons) do
    button.hidden = true
  end
end

function PlayState:updateButtons(dt)
  for _, button in ipairs(self.buttons) do
    button:update(dt)
  end

  if ANDROID then
    local connected = love.system.isGooglePlayConnected()
    self.signin_button.enabled = not connected
    self.leaderboard_button.enabled = connected
    self.achievements_button.enabled = connected
  end
end

function PlayState:showButtons()
  for _, button in ipairs(self.buttons) do
    button.hidden = false
  end
end


function PlayState:update(dt)
  if self.paused then
    self.paused_time = self.paused_time + dt
    if self.screenEffects then self.screenEffects:update(dt) end
    return
  end

  GameState.update(self, dt)
  self.score = self.score + dt

  if self.screenEffects then
      self.screenEffects:update(dt)
  end

  if self.newrecord == false and (self.bestscore == nil or self.score > self.bestscore) then
    self.newrecord = true
    self.newrecord_visible = true

    if self.bestscore ~= nil then
      PlayState.NEWRECORD_SOUND:play()

      if ANDROID or IOS then
        love.system.unlockAchievement(IDS.ACH_BEAT_YOUR_PERSONAL_BEST)
      end
    end
  end

  if CREATE_RECORDING then
    RECORDING:write(self.score .. "\n")
    RECORDING:write(self.player.pos.x .. "\n")
    RECORDING:write(self.player.pos.y .. "\n")
  end

  if PLAY_RECORDING then
    if CURRENT_CHECKPOINT and self.score >= CURRENT_CHECKPOINT - (1.0/60) then
      local x, y = RECORDING(), RECORDING()
      self.player.pos = vector(x, y)
      CURRENT_CHECKPOINT = RECORDING()
    end
  end

  self:updateButtons(dt)
  self.white_fader.time = self.white_fader.time + dt

  if not self.paused then
    local KEYBOARD_MOVE_SPEED = 300
    if love.keyboard.isDown("left") then
      self.player:move(-KEYBOARD_MOVE_SPEED * dt, 0)
    end
    if love.keyboard.isDown("right") then
      self.player:move(KEYBOARD_MOVE_SPEED * dt, 0)
    end
    if love.keyboard.isDown("up") then
      self.player:move(0, -KEYBOARD_MOVE_SPEED * dt)
    end
    if love.keyboard.isDown("down") then
      self.player:move(0, KEYBOARD_MOVE_SPEED * dt)
    end
  end
end

function PlayState:overlay()
  if self.screenEffects then
      self.screenEffects:draw()
  end

  local trap_width = 60 * self.scale
  local trap_bottom_width = 40 * self.scale
  local trap_height = 30 * self.scale

  local score_top = 0
  if IOS then
    local left, top, right, bottom = love.window.getSafeAreaInsets()
    score_top = 0.65 * top * love.window.getPixelScale()
  end

  Color.BLACK:use()
  love.graphics.polygon('fill',
    love.graphics.getWidth()/2 - trap_width/2, score_top,
    love.graphics.getWidth()/2 + trap_width/2, score_top,
    love.graphics.getWidth()/2 + trap_bottom_width / 2, score_top + trap_height,
    love.graphics.getWidth()/2 - trap_bottom_width/2, score_top + trap_height)

  Color.WHITE:use()
  love.graphics.setFont(self.time_font)
  love.graphics.printf(string.format("%.1f", self.score),
    love.graphics.getWidth()/2 - trap_width/2, score_top + self.scale*3.5, trap_width, "center")

  if self.bestscore ~= nil and self.newrecord and self.newrecord_visible then
    Color.BLACK:use()
    love.graphics.setFont(self.new_record_font)
    love.graphics.printf("NEW RECORD",
      love.graphics.getWidth()/2 - love.graphics.getWidth()/2,
      (love.graphics.getHeight()/2 - self.scale*PlayArea.SIZE/2)/2,
      love.graphics.getWidth(), "center")
  end

  for _, button in ipairs(self.buttons) do
    button:overlay(self.scale)
  end

  if self.paused then
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    local s = self.scale
    local cx, cy = w / 2, h / 2

    love.graphics.setColor(0, 0, 0, 0.75)
    love.graphics.rectangle('fill', 0, 0, w, h)

    love.graphics.setFont(self.instruction_font)
    love.graphics.setColor(0.3, 0.7, 1.0, 0.9)
    love.graphics.printf("PAUSED", 0, cy - 50 * s, w, "center")

    local btnW = 200 * s
    local btnH = 44 * s
    local btnGap = 12 * s
    local startY = cy + 5 * s
    local bx = cx - btnW / 2

    for i, btn in ipairs(self.paused_buttons) do
      local by = startY + (i - 1) * (btnH + btnGap)
      local sel = i == self.paused_selected
      local r, g, b = 0.25, 0.65, 1.0
      local pulse = math.sin(self.paused_time * 3) * 0.12 + 0.88

      love.graphics.setColor(0.05, 0.05, 0.12, 0.9)
      love.graphics.rectangle('fill', bx, by, btnW, btnH)
      love.graphics.setColor(r * 0.3, g * 0.3, b * 0.3, 0.5)
      love.graphics.setLineWidth(2 * s)
      love.graphics.rectangle('line', bx, by, btnW, btnH)

      if sel then
        love.graphics.setColor(r, g, b, pulse * 0.2)
        love.graphics.rectangle('fill', bx + 2, by + 2, btnW - 4, btnH - 4)
        love.graphics.setColor(r, g, b, pulse)
        love.graphics.setLineWidth(2 * s)
        love.graphics.rectangle('line', bx - 1, by - 1, btnW + 2, btnH + 2)
      end

      love.graphics.setFont(self.best_font)
      love.graphics.setColor(r, g, b, sel and pulse or 0.7)
      love.graphics.printf(btn.text, bx, by + btnH / 2 - 12 * s, btnW, "center")
    end

    love.graphics.setFont(self.instruction_font)
    love.graphics.setColor(0.3, 0.5, 0.7, 0.4)
    love.graphics.printf("ESC TO RESUME", 0, h - 15 * s, w, "center")
  end

  if self.white_fader.time < self.white_fader.duration then
    love.graphics.setColor(0, 0, 0,
      1 * (1 - (self.white_fader.time / self.white_fader.duration)))
    love.graphics.rectangle('fill', 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
  end
end

function PlayState:touchpressed(id, x, y, dx, dy, pressure)
  GameState.touchpressed(self, id, x, y, dx, dy, pressure)

  if self.paused then
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    local s = self.scale
    local btnW = 200 * s
    local btnH = 44 * s
    local btnGap = 12 * s
    local cx = w / 2
    local startY = h / 2 + 5 * s
    local bx = cx - btnW / 2
    for i, btn in ipairs(self.paused_buttons) do
      local by = startY + (i - 1) * (btnH + btnGap)
      if x > bx and x < bx + btnW and y > by and y < by + btnH then
        self.paused_selected = i
        btn.action()
        return
      end
    end
    return
  end

  for _, button in ipairs(self.buttons) do
    if button:containsPoint(x, y) then
      self.ignore_touch[id] = true
      button.action()
      break
    end
  end

  if y < PlayState.VMARGIN or y > love.graphics.getHeight() - PlayState.VMARGIN then
    self.ignore_touch[id] = true
  end
end

function PlayState:touchreleased(id, x, y, dx, dy, pressure)
  self.ignore_touch[id] = false
end

function PlayState:touchmoved(id, x, y, dx, dy, pressure)
  GameState.touchmoved(self, id, x, y, dx, dy, pressure)
  if self.paused or self.ignore_touch[id] then return end
  self.player:move(dx / self.scale, dy / self.scale)
end

require_dir "src/phases"
