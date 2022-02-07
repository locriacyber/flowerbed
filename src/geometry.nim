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

proc unitVector2WithAngle*(angle: Angle): Vector2 =
  Vector2(
    x: cos(angle),
    y: sin(angle),
  )

proc angle*(v: Vector2): Angle =
  arctan2(v.y, v.x)

proc seperate*(a: Vector2, b: var Vector2, seperation_distance: float) =
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

proc drawPort*(center: Vector2, rotation: Angle) =
  let polygon = PortPolygon.transform(8, rotation, center)
  # because polygon is convex, triangle fan is same as polygon
  drawTriangleFan(polygon[0].unsafeAddr, polygon.len, Raywhite)
  for i in 0..<polygon.len:
    drawLineEx(polygon[i], polygon[(i+1).mod polygon.len], 1, Blue)
