function love.conf(t)
  t.identity = "singularity"
  t.window.title = "SINGULARITY"
  t.window.resizable = true
  t.window.highdpi = true
  t.externalstorage = true

  t.window.width = 1280
  t.window.height = 720
  t.window.minwidth = 100
  t.window.minheight = 100
  t.window.fullscreen = true
  t.window.fullscreenType = "desktop"
  t.window.vsync = true
  t.version = "11.3"
end
