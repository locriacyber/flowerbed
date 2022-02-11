import std/[sequtils, strformat, random, tables, sets]
import nimraylib_now
import core, skeuomorph, dragdrop, geometry, graphics


type
  DraggedKind* {.pure.} = enum
    Fragment
    Port

  Dragged* = object
    case kind: DraggedKind
    of DraggedKind.Fragment: frag_id: Index[Fragment]
    of DraggedKind.Port: port_id: PortId

  MainState* = object
    id_issuer: IdIssuer
    nodes: Table[Id, Node]
    fragments: Table[Id, Fragment]
    cords: Table[Id, Cord]
    dragging*: HashSet[Dragged]

template `==`*(a, b: Dragged): bool =
  a.kind == b.kind and (
    case a.kind
    of DraggedKind.Fragment: a.frag_id == b.frag_id
    of DraggedKind.Port: a.port_id == b.port_id
  )

const PORT_MINIMUM_DISTANCE = 0.5 # 1 is unit circle radius
const PORT_SEPERATION_SPEED = 0.5

template `[]`*(s: MainState, id: Index[Fragment]): untyped =
  s.fragments[id]

template `[]`*(s: MainState, id: Index[Node]): untyped =
  s.nodes[id]

template `[]`*(s: MainState, id: Index[Cord]): untyped =
  s.cords[id]

template `[]`*(s: MainState, port_id: PortId): Port =
  case port_id.type:
  of Input: s[port_id.fragment].inputs[port_id.ordinal]
  of Output: s[port_id.fragment].outputs[port_id.ordinal]

template `[]`*[T](s: ptr MainState, id: Index[T]): untyped =
  s[][id]

template `[]`*(s: ptr MainState, id: PortId): untyped =
  s[][id]

template lookup*(x: typed, s: var MainState): untyped =
  s[x]

proc port_pos*(s: MainState, port_id: PortId): Vector2 =
  let frag = s[port_id.fragment]
  let node = s[frag.node]
  let port = s[port_id]
  getPortPos(node, port.angle)

proc registerNodeDragDrop*(s: var MainState, dnd: var DragDropManager, id: Id): DragDropObjectHandle =
  let s = s.unsafeAddr
  let drag_id = Dragged(
    kind: DraggedKind.Fragment,
    frag_id: id,
  )
  dnd.add(DragDropObject(
    check_collision: proc (cursor_pos: Vector2): bool =
      let node = s.nodes[id].unsafeAddr
      checkCollisionPointCircle(cursor_pos, node.center, node.radius)
    ,
    start_drag: proc (_: Vector2): DragHandle =
      s.dragging.incl(drag_id)
      DragHandle(
        drag: proc (cursor_moved: Vector2): void =
          let node = s.nodes[id].unsafeAddr
          node.center += cursor_moved
        ,
        drop: proc (_: Vector2): void =
          s.dragging.excl(drag_id)
      )
    ,
    debug_draw: proc () =
      let
        node = s.nodes[id].unsafeAddr
      drawCross(node.center, Yellow)
  ))

proc addNode*(s: var MainState, dnd: var DragDropManager, pos: Vector2, radius: float): Index[Node] =
  var node = Node(
    center: pos,
    radius: radius,
  )
  let id = s.id_issuer.next()
  node.dnd_id = s.registerNodeDragDrop(dnd, id)
  s.nodes[id] = node
  id

proc removeNode*(s: var MainState, dnd: var DragDropManager, i: Index[Node]) =
  dnd.remove(i.lookup(s).dnd_id)
  s.nodes.del(i)

proc check_collision_port*(s: MainState, cursor_pos: Vector2, port_id: PortId): bool =
  let
    port = s[port_id]
    frag = s[port_id.fragment]
    node: Node = s[frag.node]
    polygon: seq[Vector2] = port.polygon(node)
  checkCollisionPointPolygon(cursor_pos, polygon)

proc registerPortDragDrop*(s: var MainState, dnd: var DragDropManager, port_id: PortId): DragDropObjectHandle =
  let s = s.unsafeAddr
  let drag_id = Dragged(
    kind: DraggedKind.Port,
    port_id: port_id,
  )
  let o =
    DragDropObject(
      check_collision: proc (cursor_pos: Vector2): bool = check_collision_port(s[], cursor_pos, port_id),
      start_drag: proc (_: Vector2): DragHandle =
        # let
          # frag = s[id][]
          # node: Node = s[frag.node][]
          # port = s[port_id][]
          # frag = s[port_id.frag][]
        s.dragging.incl(drag_id)
        DragHandle(
          drag: proc (cursor_moved: Vector2): void =
            discard
            # let node = s.nodes[id].unsafeAddr
            # node.center += cursor_moved
          ,
          drop: proc (_: Vector2): void =
            s.dragging.excl(drag_id)
        )
      ,
      debug_draw: proc () =
        let
          port = s[port_id]
          frag = s[port_id.fragment]
          node: Node = s[frag.node]
        let pos = getPortPos(node, port.angle)
        drawCross(pos, Red)
    )
  dnd.add(o, priority=10)

proc addFragment*(s: var MainState, dnd: var DragDropManager, a: Algorithm, node_id: Index[Node]): Index[Fragment] =
  var frag = Fragment(
    algorithm: a,
    node: node_id,
    inputs: repeat(Port(cord: -1, angle: 0.0, type: Input), a.inputs.len),
    outputs: repeat(Port(cord: -1, angle: 0.0, type: Output), a.outputs.len),
  )
  let id = s.id_issuer.next()
  for i in 0..<frag.inputs.len:
    let port_id = PortId(
      fragment: id,
      type: Input,
      ordinal: i.uint,
    )
    frag.inputs[i].dnd_id = registerPortDragDrop(s, dnd, port_id)
  for i in 0..<frag.outputs.len:
    let port_id = PortId(
      fragment: id,
      type: Output,
      ordinal: i.uint,
    )
    frag.outputs[i].dnd_id = registerPortDragDrop(s, dnd, port_id)
  s.fragments[id] = frag
  id

proc removeFragment*(s: var MainState, i: Index[Fragment]) =
  discard ## TODO

proc addCord*(s: var MainState; src, dst: Index[Fragment]; src_i, dst_i: uint): Index[Cord] =
  template f_src: untyped = s[src]
  template f_dst: untyped = s[dst]

  assert src_i < f_src.outputs.len.uint
  assert dst_i < f_dst.inputs.len.uint
  let id = s.id_issuer.next()
  let cord = Cord(
    src: PortId(
      fragment: src,
      ordinal: src_i,
      type: Output,
    ),
    dst: PortId(
      fragment: dst,
      ordinal: dst_i,
      type: Input,
    ),
  )
  f_src.outputs[src_i].cord = id
  f_dst.inputs[dst_i].cord = id
  s.cords[id] = cord
  id


proc separate_ports*(s: var MainState, dt: float) =
  # separate ports
  for fi in s.fragments.keys:
    var f = s.fragments[fi].unsafeAddr
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
          separate(angles[i], angles[j], s[f.node].radius * dt * PORT_SEPERATION_SPEED)
    # map back to radians
    # for connected ports, point to connected fragment
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
      except KeyError as e:
        f.outputs[j].angle = angle(angles[input_len + j])

proc draw*(s: var MainState, font: Font) =  
  # draw touch nodes
  for n in s.nodes.values:
    drawCircleThickLines(n.center, n.radius-1, n.radius+1, fade(Black, 0.3))

  # draw cords
  for c in s.cords.values:    
    drawLineEx(
      portpos(s, c.src),
      portpos(s, c.dst),
      8,
      Blue,
    )

  # draw ports
  for f in s.fragments.values:
    let node = f.node.lookup(s)
    for port in f.inputs:
      port.draw(node)
    for port in f.outputs:
      port.draw(node)
      
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
        let port_pos = getPortPos(node, port.angle)
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
