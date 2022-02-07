import nimraylib_now, options, sequtils, math
import consts, geometry, core

type
  Node = object
    center: Vector2
    radius: float

  DragHandle = object
    drag: proc (cursor_moved: Vector2): void
    drop: proc (cursor_pos: Vector2): void

  DragDropObject = object
    check_collision: proc (cursor_pos: Vector2): bool
    start_drag: proc (cursor_pos: Vector2): DragHandle

  DragDropManager = object
    candidates: seq[DragDropObject]
    dragging: Option[DragHandle]
  
  Port = object
    cord: ref Cord
    angle: Angle
  
  Fragment = object
    algorithm: Algorithm
    node: ref Node
    inputs: seq[Port]
    outputs: seq[Port]

  CordEnd = object
    fragment: ref Fragment
    port_id: uint
  
  Cord = object
    src: CordEnd # output of src
    dst: CordEnd # input of dst

let algorithm_dummy = Algorithm(
  name: "2 in 2 out",
  inputs: @[
    ValueType(),
    ValueType(),
  ],
  outputs: @[
    ValueType(),
    ValueType(),
  ],
)

let algorithm_1out = Algorithm(
  name: "1 out",
  inputs: @[],
  outputs: @[ValueType()],
)

let algorithm_1in = Algorithm(
  name: "1 in",
  inputs: @[ValueType()],
  outputs: @[],
)

const PORT_MINIMUM_DISTANCE = 0.5
const PORT_SEPERATION_SPEED = 0.5

proc drawCircleThickLines(center: Vector2, innerRadius, outerRadius: float, color: Color) =
  drawRing(center, innerRadius, outerRadius, 0, 360, 0, color)

proc main() =
  initWindow screenWidth, screenHeight, "node test"
  defer: closeWindow()

  setTargetFPS 60

  var dnd: DragDropManager

  var nodes: seq[ref Node]

  proc addNode(pos: Vector2, radius: float): ref Node =
    let node = new(Node)
    node[] = Node(
      center: pos,
      radius: radius,
    )
    nodes.add(node)
    dnd.candidates.add(DragDropObject(
      check_collision: proc (cursor_pos: Vector2): bool =
        checkCollisionPointCircle(cursor_pos, node.center, node.radius)
      ,
      start_drag: proc (_: Vector2): DragHandle =
        DragHandle(
          drag: proc (cursor_moved: Vector2): void =
            node.center += cursor_moved
          ,
          drop: proc (_: Vector2): void = discard
        )
    ))
    node

  var fragments: seq[ref Fragment]

  proc addFragment(a: Algorithm, node: ref Node): ref Fragment =
    let frag = new(Fragment)
    frag[] = Fragment(
      algorithm: a,
      node: node,
      inputs: repeat(Port(cord: nil, angle: 0.0), a.inputs.len),
      outputs: repeat(Port(cord: nil, angle: 0.0), a.outputs.len),
    )
    fragments.add(frag)
    frag
    
  var cords: seq[ref Cord]
  proc addCord(src, dst: (ref Fragment, uint)): ref Cord =
    let cord = new(Cord)
    cord[] = Cord(
      src: CordEnd(
        fragment: src[0],
        port_id: src[1],
      ),
      dst: CordEnd(
        fragment: dst[0],
        port_id: dst[1],
      ),
    )
    src[0].outputs[src[1]].cord = cord
    dst[0].inputs[dst[1]].cord = cord
    cords.add(cord)
    cord

  proc init() =
    let trunk = addNode(Vector2(x: screenWidth/2.0, y: screenHeight/2.0), 32)
    let frag_center = addFragment(algorithm_dummy, trunk)
    let input = addNode(Vector2(x: screenWidth/2.0 - 200, y: screenHeight/2.0), 20)
    let frag_input = addFragment(algorithm_1out, input)
    let output = addNode(Vector2(x: screenWidth/2.0 + 200, y: screenHeight/2.0), 20)
    let frag_output = addFragment(algorithm_1in, output)
    discard addCord((frag_input, 0.uint), (frag_center, 0.uint))
    discard addCord((frag_center, 0.uint), (frag_output, 0.uint))

  proc drag_and_drop() =
    let mousepos = getMousePosition()
    let mousedelta = getMouseDelta()

    if isMouseButtonPressed(MouseButton.LEFT):
      for i in 0..<dnd.candidates.len:
        let draggable_object = dnd.candidates[i]
        if draggable_object.check_collision(mousepos):
          dnd.dragging = some(draggable_object.start_drag(mousepos))
          break

    if dnd.dragging.isSome:
      dnd.dragging.get.drag(mousedelta)

      if isMouseButtonReleased(MouseButton.LEFT):
        dnd.dragging.get.drop(mousepos)
        dnd.dragging = none(DragHandle)

  proc seperate_ports(dt: float) =
    # seperate ports
    for f in fragments:
      let
        input_len = f.inputs.len
        output_len = f.outputs.len
      var
        # angles on a unit circle
        angles: seq[Vector2] = repeat(default(Vector2), input_len + output_len)
      # turn radians into points on unit circle
      for i in 0..<input_len:
        angles[i] = unitVector2WithAngle(f.inputs[i].angle)
      for j in 0..<output_len:
        angles[input_len + j] = unitVector2WithAngle(f.outputs[j].angle)
      # force simulation
      for i in 0..<angles.len:
        for j in 0..<angles.len:
          if i == j: continue
          if distance(angles[i], angles[j]) < PORT_MINIMUM_DISTANCE:
            seperate(angles[i], angles[j], f.node.radius * dt * PORT_SEPERATION_SPEED)
      # map back to radians
      for i in 0..<input_len:
        let cord =  f.inputs[i].cord
        if cord.isNil:
          f.inputs[i].angle = angle(angles[i])
        else:
          f.inputs[i].angle = angle(cord.src.fragment.node.center - cord.dst.fragment.node.center)
      for j in 0..<output_len:
        let cord =  f.outputs[j].cord
        if cord.isNil:
          f.outputs[j].angle = angle(angles[input_len + j])
        else:
          f.outputs[j].angle = angle(cord.dst.fragment.node.center - cord.src.fragment.node.center)

  proc update(dt: float) =
    drag_and_drop()
    seperate_ports(dt)

  let font: Font = getFontDefault()

  proc getPortPos(node: Node, angle: Angle): Vector2 =
    node.center + unitVector2WithAngle(angle) * node.radius

  proc draw() =
    clearBackground RAYWHITE

    # draw touch nodes
    for n in nodes:
      drawCircleThickLines(n.center, n.radius-1, n.radius+1, fade(Black, 0.3))

    # draw cords
    for c in cords:
      let
        s_frag = c.src.fragment
        s_i = c.src.port_id
        d_frag = c.dst.fragment
        d_i = c.dst.port_id
      
      drawLineEx(
        getPortPos(s_frag.node[], s_frag.outputs[s_i].angle),
        getPortPos(d_frag.node[], d_frag.inputs[d_i].angle),
        8,
        Blue,
      )

    # draw ports
    for f in fragments:
      for port in f.inputs:
        drawPort(center=getPortPos(f.node[], port.angle), rotation=port.angle + Pi)
      for port in f.outputs:
        drawPort(center=getPortPos(f.node[], port.angle), rotation=port.angle)
    
    let font_size = 20.0

    # draw fragment info when hovered
    let mousepos = getMousePosition()
    for f in fragments:
      if checkCollisionPointCircle(mousepos, f.node.center, f.node.radius):
        let name = f.algorithm.name.cstring
        let text_size = measureTextEx(font, f.algorithm.name.cstring, font_size, 2)
        drawTextEx(font, f.algorithm.name.cstring, f.node.center - text_size / 2, font_size, 2, Black)
        
        break

  
  init()
  discard getFrameTime()
  while not windowShouldClose():
    let dt = getFrameTime()
    update(dt)
    beginDrawing()
    defer: endDrawing()
    draw()


when isMainModule:
  main()
