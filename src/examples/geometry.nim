import nimraylib_now, math

type 
  Angle* = float

proc unitVector2WithAngle*(angle: Angle): Vector2 =
  Vector2(
    x: cos(angle),
    y: sin(angle),
  )

proc angle*(v: Vector2): Angle =
  arctan2(v.y, v.x)

proc seperate*(a: Vector2, b: var Vector2, seperation_distance: float) =
  b += unitVector2WithAngle(angle(b - a)) * seperation_distance
