import std/[algorithm, sequtils, options, math, strformat]
import nimraylib_now
import core, skeuomorph, dragdrop, geometry, graphics, dragdrop


type
  MainState* = object
    nodes: seq[ref Node]
    fragments: seq[ref Fragment]
    cords: seq[ref Cord]
    dnd*: ref DragDropManager

const PORT_MINIMUM_DISTANCE = 0.5
const PORT_SEPERATION_SPEED = 0.5


proc addNode*(s: var MainState, dnd: var DragDropManager, pos: Vector2, radius: float): ref Node =
  let node = new(Node)
  node[] = Node(
    center: pos,
    radius: radius,
  )
  s.nodes.add(node)
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


proc addFragment*(s: var MainState, a: Algorithm, node: ref Node): ref Fragment =
  let frag = new(Fragment)
  frag[] = Fragment(
    algorithm: a,
    node: node,
    inputs: repeat(Port(cord: nil, angle: 0.0), a.inputs.len),
    outputs: repeat(Port(cord: nil, angle: 0.0), a.outputs.len),
  )
  s.fragments.add(frag)
  frag
  
proc addCord*(s: var MainState, src, dst: (ref Fragment, uint)): ref Cord =
  assert src[1] < src[0].outputs.len.uint
  assert dst[1] < dst[0].inputs.len.uint
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
  s.cords.add(cord)
  cord


proc separate_ports*(s: var MainState, dt: float) =
  # separate ports
  for f in s.fragments:
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
          separate(angles[i], angles[j], f.node.radius * dt * PORT_SEPERATION_SPEED)
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

proc draw*(s: MainState, font: Font) =  
  # draw touch nodes
  for n in s.nodes:
    drawCircleThickLines(n.center, n.radius-1, n.radius+1, fade(Black, 0.3))

  # draw cords
  for c in s.cords:
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
  for f in s.fragments:
    for port in f.inputs:
      drawPort(center=getPortPos(f.node[], port.angle), rotation=port.angle + Pi)
    for port in f.outputs:
      drawPort(center=getPortPos(f.node[], port.angle), rotation=port.angle)
  
  # draw fragment info when hovered
  let mousepos = getMousePosition()
  for f in s.fragments:
    if checkCollisionPointCircle(mousepos, f.node.center, f.node.radius):
      var labels: seq[Label]

      let f = f
      proc labelPort(port: Port, text: string) =
        let port_pos = getPortPos(f.node[], port.angle)
        labels.add newLabel(font, font_size=10.0.float, text, port_pos)

      # add lables
      labels.add newLabel(font, font_size=20.0, text=f.algorithm.name, f.node.center)
      for i in 0..<f.inputs.len:
        let parameter = f.algorithm.inputs[i]
        labelPort(port=f.inputs[i], text=
          fmt"{parameter.metadata.name}: {parameter.type.metadata.name}")
      for i in 0..<f.outputs.len:
        let parameter = f.algorithm.outputs[i]
        labelPort(port=f.outputs[i], text=
          fmt"{parameter.metadata.name}: {parameter.type.metadata.name}")


      var any_overlap = true
      var fuel = 32
      while any_overlap and fuel > 0:
        fuel -= 1
        any_overlap = false
        for i in 0..<labels.len:
          for j in i+1..<labels.len:
            any_overlap = separate(labels[i].aabb, labels[j].aabb, 2 * PORT_SEPERATION_SPEED)
      
      for label in labels:
        label.draw()
      
      break


proc load*(s: var MainState, f: File) =
  discard

proc save*(s: MainState, f: File) =
  discard
