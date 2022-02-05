import nimraylib_now, layout, consts, std/options, std/strformat

type
  NodeId = int

  ValueType* = object
  
  Effect* = object

  Node* = object # a code fragment
    disabled: bool
    pos: Vector2
    inputs: seq[ValueType]
    outputs: seq[ValueType]
    rails: seq[Effect] # effects

  State* = object
    last_clicked: Vector2
    nodes: seq[Node]
    dragged: Option[NodeId]

proc shapepos(node: Node): Rectangle =
  Rectangle(
    x: node.pos.x,
    y: node.pos.y,
    width: default_node_size.x,
    height: default_node_size.y,
  )

proc init*[State](): State =
  result.last_clicked = (x: 0.0, y: 0.0)
  result.dragged = none(NodeId)

proc dotted_circle*(pos: Vector2, inner, outer: float, color: Color) =
  var i = 0.0 # angle
  while i < 360.0:
    drawRing(pos, inner, outer, i, i+15, 0, color)
    i += 30

proc draw(node: Node) =
  drawRectangleLinesEx(node.shapepos, 2, fade(Black, 0.8))

proc update_n_draw*(s: var State, dt: cfloat) =
  # update
  let mousepos = getMousePosition()
  let mosuedelta = getMouseDelta()

  if checkCollisionPointRec(mousepos, playground):
    # only allow click inside play area
    if isMouseButtonPressed(MouseButton.LEFT):
      block try_drag:
        for i in 0..<s.nodes.len:
          let rect = s.nodes[i].shapepos
          if checkCollisionPointRec(mousepos, rect):
            s.dragged = i.some
            break try_drag
        s.last_clicked = mousepos
    
    if s.dragged.isSome:
      let pos = s.nodes[s.dragged.get].pos.addr
      pos.x += mosuedelta.x
      pos.y += mosuedelta.y

    if isMouseButtonReleased(MouseButton.LEFT):
      s.dragged = none(NodeId)

  # draw shapes
  dotted_circle(s.last_clicked, cursor_circle_size, cursor_circle_size+2.0, fade(BLUE, 0.5))
  for node in s.nodes:
    draw(node)
  drawRectangleLinesEx(playground, 4, fade(BLUE, 0.8))
  
  # ui
  var layout = Layout(y: 10.0)
  if button(layout.next_rect, "Add Node"):
    let l = s.last_clicked
    var node: Node = default(Node)
    node.pos = Vector2(x: l.x, y: l.y)
    echo node
    s.nodes.add node
  label(layout.next_rect, fmt"Node count: {s.nodes.len}".cstring)
  for node in s.nodes:
    label(layout.next_rect, fmt"{node.shapepos}".cstring)