import nimraylib_now

type Layout* = object
  y*: float64

proc next_rect*(l: var Layout): Rectangle =
  result = (x: 620.0, y: l.y, width: 120.0, height: 20.0)
  l.y += 30