import std/[sequtils, math, strformat, random, tables]
import nimraylib_now
import core, skeuomorph, dragdrop, geometry, graphics


type
  MainState* = object
    id_issuer: IdIssuer
    nodes: Table[Id, Node]
    fragments: Table[Id, Fragment]
    cords: Table[Id, Cord]

const PORT_MINIMUM_DISTANCE = 0.5 # 1 is unit circle radius
const PORT_SEPERATION_SPEED = 0.5

proc get*(s: var MainState, id: Index[Fragment]): ptr Fragment =
  s.fragments[id].unsafeAddr

proc get*(s: var MainState, id: Index[Node]): ptr Node =
  s.nodes[id].unsafeAddr

proc get*(s: var MainState, id: Index[Cord]): ptr Cord =
  s.cords[id].unsafeAddr

template lookup*(x: typed, s: var MainState): untyped =
  s.get(x)

proc registerNodeDragDrop*(s: var MainState, dnd: var DragDropManager, id: Id) =
  let s = s.unsafeAddr
  dnd.candidates.add(DragDropObject(
    check_collision: proc (cursor_pos: Vector2): bool =
      let node = s.nodes[id].unsafeAddr
      checkCollisionPointCircle(cursor_pos, node.center, node.radius)
    ,
    start_drag: proc (_: Vector2): DragHandle =
      DragHandle(
        drag: proc (cursor_moved: Vector2): void =
          let node = s.nodes[id].unsafeAddr
          node.center += cursor_moved
        ,
        drop: proc (_: Vector2): void = discard
      )
  ))

proc addNode*(s: var MainState, dnd: var DragDropManager, pos: Vector2, radius: float): Index[Node] =
  let node = Node(
    center: pos,
    radius: radius,
  )
  let id = s.id_issuer.next()
  s.nodes[id] = node
  s.registerNodeDragDrop(dnd, id)
  id

proc addFragment*(s: var MainState, a: Algorithm, node_id: Index[Node]): Index[Fragment] =
  let frag = Fragment(
    algorithm: a,
    node: node_id,
    inputs: repeat(Port(cord: -1, angle: 0.0), a.inputs.len),
    outputs: repeat(Port(cord: -1, angle: 0.0), a.outputs.len),
  )
  let id = s.id_issuer.next()
  s.fragments[id] = frag
  id
  
proc addCord*(s: var MainState; src, dst: Index[Fragment]; src_i, dst_i: uint): Index[Cord]=
  let
    f_src = src.lookup(s)
    f_dst = dst.lookup(s)

  assert src_i < f_src.outputs.len.uint
  assert dst_i < f_dst.inputs.len.uint
  let id = s.id_issuer.next()
  let cord = Cord(
    src: CordEnd(
      fragment: src,
      port_id: src_i,
    ),
    dst: CordEnd(
      fragment: dst,
      port_id: dst_i,
    ),
  )
  f_src.outputs[src_i].cord = id
  f_dst.inputs[dst_i].cord = id
  s.cords[id] = cord
  id


proc separate_ports*(s: var MainState, dt: float) =
  # separate ports
  for fi in s.fragments.keys:
    let f = s.fragments[fi].unsafeAddr
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
          separate(angles[i], angles[j], f.node.lookup(s).radius * dt * PORT_SEPERATION_SPEED)
    # map back to radians
    for i in 0..<input_len:
      try:
        let cord = f.inputs[i].cord.lookup(s)
        f.inputs[i].angle = angle(cord.src.fragment.lookup(s).node.lookup(s).center - cord.dst.fragment.lookup(s).node.lookup(s).center)
      except KeyError:
        f.inputs[i].angle = angle(angles[i])
    for j in 0..<output_len:
      try:
        let cord =  f.outputs[j].cord.lookup(s)
        f.outputs[j].angle = angle(cord.dst.fragment.lookup(s).node.lookup(s).center - cord.src.fragment.lookup(s).node.lookup(s).center)
      except KeyError:
        f.outputs[j].angle = angle(angles[input_len + j])

proc draw*(s: var MainState, font: Font) =  
  # draw touch nodes
  for n in s.nodes.values:
    drawCircleThickLines(n.center, n.radius-1, n.radius+1, fade(Black, 0.3))

  # draw cords
  for c in s.cords.values:
    let
      s_frag = c.src.fragment.lookup(s)
      s_i = c.src.port_id
      d_frag = c.dst.fragment.lookup(s)
      d_i = c.dst.port_id
    
    drawLineEx(
      getPortPos(s_frag.node.lookup(s)[], s_frag.outputs[s_i].angle),
      getPortPos(d_frag.node.lookup(s)[], d_frag.inputs[d_i].angle),
      8,
      Blue,
    )

  # draw ports
  for f in s.fragments.values:
    for port in f.inputs:
      drawPort(center=getPortPos(f.node.lookup(s)[], port.angle), rotation=port.angle + Pi)
    for port in f.outputs:
      drawPort(center=getPortPos(f.node.lookup(s)[], port.angle), rotation=port.angle)
  
  # draw fragment info when hovered
  let mousepos = getMousePosition()
  for f in s.fragments.values:
    let node = f.node.lookup(s)
    if checkCollisionPointCircle(mousepos, node.center, node.radius):
      ## bottom
      # var main_label = newLabel(font, font_size=20.0, text=f.algorithm.name, node.center + vec2(0, node.radius), alignment=Alignment_Top)
      ## top
      # var main_label = newLabel(font, font_size=20.0, text=f.algorithm.name, node.center + vec2(0, -node.radius), alignment=Alignment_Bottom)
      var main_label = newLabel(font, font_size=20.0, text=f.algorithm.name, node.center)
      var labels: seq[Label]

      proc label_port(port: Port, text: string) =
        let port_pos = getPortPos(node[], port.angle)
        labels.add newLabel(font, font_size=10.0.float, text, port_pos)

      # add lables
      for i in 0..<f.inputs.len:
        let parameter = f.algorithm.inputs[i]
        label_port(port=f.inputs[i], text=
          fmt"{parameter.metadata.name}: {parameter.type.metadata.name}")
      for i in 0..<f.outputs.len:
        let parameter = f.algorithm.outputs[i]
        label_port(port=f.outputs[i], text=
          fmt"{parameter.metadata.name}: {parameter.type.metadata.name}")

      var rand: Rand = initRand(cast[int64](f.unsafeAddr))
      block seperate_port_labels:
        var fuel = 32
        var any_overlap = true
        while any_overlap and fuel > 0:
          any_overlap = false
          rand.shuffle(labels)
          block outer:
            fuel -= 1
            for i in 0..<labels.len:
              for j in i+1..<labels.len:
                any_overlap = any_overlap or separate(labels[i].aabb, labels[j].aabb)
                if any_overlap: break outer
      
      block move_main_label_to_side:
        var fuel = 64
        var any_overlap = true
        var multiple = 1.0
        while any_overlap and fuel > 0:
          any_overlap = false
          rand.shuffle(labels)
          block outer:
            fuel -= 1
            for i in 0..<labels.len:
              any_overlap = any_overlap or separate(main_label.aabb, labels[i].aabb, multiple)
              # any_overlap = any_overlap or separate(main_bottom.aabb, labels[i].aabb)
              if any_overlap: break outer
          multiple += 0.1
      

      main_label.draw()
      # main_bottom.draw()
      for label in labels:
        label.draw()

      break


proc load*(s: var MainState, f: File) =
  raise newException(IOError, "not implemented")

proc save*(s: MainState, f: File) =
  discard
