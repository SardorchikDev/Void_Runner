-- MODIFIED: Boots the Void Runner conversion instead of the original arena menu.
require 'utils'

ANDROID = love.system.getOS() == "Android"
IOS = love.system.getOS() == "iOS"
MOBILE = ANDROID or IOS

IDS = require 'src.ids'

inspect = require 'external.inspect'
class = require 'external.middleclass'
Stateful = require 'external.stateful'

vector = require 'external.vector'
collision = require 'external.hc.shapes'
lume = require 'external.lume'

Timer = require 'external.timer'
Camera = require 'external.camera'
Signal = require 'external.signal'

Color = require 'src.color'
ScreenEffects = require 'src.screeneffect'
AudioManager = require 'src.audiomanager'

require "src.gamestate"
require "src.entity"

CREATE_RECORDING = lume.any(arg, function(x) return x == "--create-recording" end)
PLAY_RECORDING = lume.any(arg, function(x) return x == "--play-recording" end)

if ANDROID or IOS then love.window.setFullscreen(true) end
if IOS then love.system.authenticateLocalPlayer() end

function love.load(arg)
    if arg[2] == 'debug' then DEBUG = true end
    if PLAY_RECORDING then
        GameState.switchTo(VoidRunnerPlayState())
    else
        GameState.switchTo(LoadingScreen())
    end
end

MAX_DELTA_TIME = 1 / 30
function love.update(dt)
    if dt > MAX_DELTA_TIME then dt = MAX_DELTA_TIME end
    if arg[2] == 'debug' and love.keyboard.isDown('space') then dt = dt * 0.5 end
    Timer.update(dt)
    if GameState.currentState ~= nil then GameState.currentState:update(dt) end
    if DEBUG then require("external.lurker").update() end
end

function love.draw()
    if GameState.currentState ~= nil then GameState.currentState:draw() end
end
