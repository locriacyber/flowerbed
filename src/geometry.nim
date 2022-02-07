import nimraylib_now, math, algorithm, sequtils, sugar

type 
  Angle* = float

const PORT_POLYGON*: seq[Vector2] = block:
  const lowerhalf = @[
    Vector2(x: -1, y: 1),
    Vector2(x: 0.2, y: 1),
    Vector2(x: 1, y: 0.3),
  ]
  concat(
    lowerhalf,
    lowerhalf.reversed.mapIt(Vector2(
      x: it.x,
      y: -it.y,
    ))
  )

proc newVec2*(x, y: float): Vector2 =
  Vector2(
    x: x,
    y: y,
  )

proc unitVector2WithAngle*(angle: Angle): Vector2 =
  Vector2(
    x: cos(angle),
    y: sin(angle),
  )

proc angle*(v: Vector2): Angle =
  arctan2(v.y, v.x)

proc separate*(a: Vector2, b: var Vector2, seperation_distance: float) =
  b += unitVector2WithAngle(angle(b - a)) * seperation_distance

proc rotateAroundOrigin*(v: Vector2, a: Angle): Vector2 =
  let p = unitVector2WithAngle(a)
  Vector2(
    x: p.x*v.x-p.y*v.y,
    y: p.x*v.y+p.y*v.x,
  )

proc transform*(polygon: openArray[Vector2], scale: float, rotation: Angle, translation: Vector2): seq[Vector2] =
  collect(newSeq):
    for v in polygon:
      v.rotateAroundOrigin(rotation) * scale + translation

proc Rectangle*(topleft: Vector2, size: Vector2): Rectangle =
  Rectangle(
    x      : topleft.x,
    y      : topleft.y,
    width  : size.x,
    height : size.y,
  )


## Inflate a Rectangle by `padding`
proc grow*(r: Rectangle, padding: float): Rectangle =
  Rectangle(
    x      : r.x - padding,
    y      : r.y - padding,
    width  : r.width + padding * 2,
    height : r.height + padding * 2,
  )

proc topleft*(r: Rectangle): Vector2 =
  Vector2(
    x: r.x,
    y: r.y,
  )

proc size*(r: Rectangle): Vector2 =
  Vector2(
    x: r.width,
    y: r.height,
  )

proc `topleft=`*(r: var Rectangle, value: Vector2) =
  r.x = value.x
  r.y = value.y

proc center*(r: Rectangle): Vector2 =
  r.topleft + r.size / 2.0

proc top*(r: Rectangle): float =
  r.y
proc bottom*(r: Rectangle): float =
  r.y + r.height
proc left*(r: Rectangle): float =
  r.x
proc right*(r: Rectangle): float =
  r.x + r.width

import options

## the least effort direction of how to move b from a
proc easiestSeperationDirection(a: Rectangle, b: Rectangle): Option[Vector2] =
  let
    # distance between the rects
    dx = a.x - b.x
    dy = a.y - b.y
    adx = abs(dx)
    ady = abs(dy)
    # sum of the extents
    shw = a.width + b.width
    shh = a.height + b.height
    # shortest separation
  var
    sx = shw - adx
    sy = shh - ady

  if adx >= shw or ady >= shh:
    # no intersection
    return none(Vector2)

  # ignore longer axis
  if sx < sy:
    if sx > 0:
      sy = 0
  else:
    if sy > 0:
      sx = 0
  # correct sign
  if dx < 0:
    sx = -sx
  if dy < 0:
    sy = -sy
  return some(newVec2(sx, sy))


proc solveCollision(a: var Rectangle, b: Rectangle, easiestDirection: Vector2) =
  # find the collision normal
  # let
  #   sx = easiestSeperationDirection.x
  #   sy = easiestSeperationDirection.y
  #   d = math.sqrt(sx*sx + sy*sy)
  #   nx = sx/d
  #   ny = sy/d    
  a.topleft = a.topleft + easiestDirection
  


proc separate*(a: var Rectangle, b: Rectangle, seperation_distance: float): bool =
  let v = easiestSeperationDirection(a, b)
  if v.isSome:
    solveCollision(a, b, v.get)
    true
  else:
    false
