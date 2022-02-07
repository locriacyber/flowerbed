import nimraylib_now
import geometry

proc drawPort*(center: Vector2, rotation: Angle) =
  let polygon = PortPolygon.transform(8, rotation, center)
  # because polygon is convex, triangle fan is same as polygon
  drawTriangleFan(polygon[0].unsafeAddr, polygon.len, Raywhite)
  for i in 0..<polygon.len:
    drawLineEx(polygon[i], polygon[(i+1).mod polygon.len], 1, Blue)

type
  Alignment* = object
    ## (0, 0) means `pos` is at label center
    ## (-1, 0) means `pos` is at label center right
    shift*: Vector2

proc newAlignment*(x: float, y: float): Alignment =
  Alignment(shift: Vector2(x: x, y: y))

const Alignment_Center* = newAlignment(0.0, 0.0)
const Alignment_Left*   = newAlignment(1.0, 0.0)
const Alignment_Right*  = newAlignment(-1.0, 0.0)
const Alignment_Top*    = newAlignment(0.0, 1.0)
const Alignment_Bottom* = newAlignment(0.0, -1.0)

type Label* = object
  aabb*: Rectangle
  text: string
  font: Font
  font_size: float
  font_spacing: float
  padding: float

proc newLabel*(font: Font, font_size: float, text: string, pos: Vector2, spacing: float = font_size * 0.1, padding: float = 4.0, alignment: Alignment = Alignment_Center): Label =
  if text.len == 0: return
  let text_size = measureTextEx(font, text, font_size, spacing)
  let topleft = pos - (text_size / 2) + text_size.dotProduct(alignment.shift)
  let rect = Rectangle(topleft, text_size)
  Label(
    aabb: rect,
    text: text,
    font: font,
    font_size: font_size,
    font_spacing: spacing,
    padding: padding,
  )

proc draw*(label: Label, fg: Color = Black, bg: Color = fade(Raywhite, 0.6), border_size: float = 1.0) =
  let bg_rect = label.aabb.grow(label.padding)
  drawRectangleRec(bg_rect, bg)
  drawTextEx(label.font, label.text.cstring, label.aabb.topleft, label.font_size, label.font_spacing, fg)
  drawRectangleLinesEx(bg_rect, border_size, fg)


proc drawCircleThickLines*(center: Vector2, innerRadius, outerRadius: float, color: Color) =
  drawRing(center, innerRadius, outerRadius, 0, 360, 0, color)
