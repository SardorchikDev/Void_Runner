-- Basic color class, in order to cut down on verbosity.
local Color = class('Color')

function Color:initialize(r, g, b, a)
  assert(type(r) == "number", "'r' must be a number.")
  assert(type(g) == "number", "'g' must be a number.")
  assert(type(b) == "number", "'b' must be a number.")

  self.r = r
  self.g = g
  self.b = b
  self.a = a or 1
end

-- Unpack color.
function Color:rgb() return self.r, self.g, self.b end
function Color:rgba() return self.r, self.g, self.b, self.a end

-- Clone the color so that it can be modified.
function Color:clone() return Color(self.r, self.g, self.b, self.a) end

-- Use this color globally.
function Color:use() love.graphics.setColor(self.r, self.g, self.b, self.a) end

Color.static.WHITE = Color(1, 1, 1, 1)
Color.static.BLACK = Color(0, 0, 0, 1)

Color.static.GREY = Color(0.5, 0.5, 0.5, 1)
Color.static.GRAY = Color.static.GREY

Color.static.TRANSPARENT = Color(1, 1, 1, 0)

Color.static.RED = Color(1, 0.2, 0.2, 1)
Color.static.GREEN = Color(0.2, 1, 0.2, 1)
Color.static.BLUE = Color(0.2, 0.5, 1, 1)

Color.static.YELLOW = Color(1, 1, 0.2, 1)
Color.static.PURPLE = Color(0.8, 0.2, 1, 1)
Color.static.CYAN = Color(0.2, 1, 1, 1)

Color.static.ORANGE = Color(1, 0.5, 0.1, 1)
Color.static.PINK = Color(1, 0.2, 0.6, 1)

Color.static.DARK = Color(0.05, 0.05, 0.1, 1)
Color.static.DARKER = Color(0.02, 0.02, 0.05, 1)
Color.static.GLOW = Color(0.3, 0.6, 1, 1)

return Color
