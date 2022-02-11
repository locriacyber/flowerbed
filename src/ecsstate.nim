import nimraylib_now, ecs
import ecs / components
import core

type
  Rotation* = object
    angle*: Angle # rotation on fragment
  
  Position* = object
    coords*: Vector2

type
  ## entity representing T (it has a component of T)
  EntityOf[T] = Entity

  ## direction of flow of data
  FlowDirection* {.pure.} = enum
    Input
    Output
  
  Port* = object
    fragment*: EntityOf[Fragment]
    ## is this input or output?
    direction*: FlowDirection
    ## 0 means first input/output
    ordinal*: uint
  
  Cord* = object
    src*: EntityOf[Port] 
    dst*: EntityOf[Port]

  Fragment* = object
    algorithm*: Algorithm
  
  ScrollHandle* = object
    ## input means this scroll handle has input ports
    direction: FlowDirection
    other: EntityOf[ScrollHandle]

type
  ECSState* {.requires_init.} = object
    w: World

proc init*(_: typedesc[ECSState]): ECSState =
  ECSState(w: newWorld())

proc load*(s: var ECSState, f: File) =
  raise newException(IOError, "not implemented")

proc save*(s: ECSState, f: File) =
  discard

proc update*(s: var ECSState, dt: float) =
  discard

proc draw_fragment(f: Fragment, pos: Position) =
  let pos = pos.coords
  drawCircleV(pos, 32, Black)

    # ## This proc is basically the System
    # res.multiplicationResult = c.x * c.y
    # inc processedEntities

proc draw*(s: ECSState) =
  s.w.forEveryMatchingEntity(draw_fragment)

proc addScrollHandle*(s: var ECSState, a: Algorithm, pos_start: Vector2, pos_end: Vector2): (EntityOf[ScrollHandle], EntityOf[ScrollHandle]) =
  discard

proc addFragment*(s: var ECSState, a: Algorithm, pos: Vector2): EntityOf[Fragment] =
  let eid = s.w.newEntity()
  eid.addComponent(Fragment(algorithm: a))
  eid.addComponent(Position(coords: pos))
  eid.addComponent(a.metadata)

  template spawn_ports(dir, port_types: untyped) =
    for i in 0..<port_types.len:
      let (valuetype, metadata) = port_types[i]
      let port = s.w.newEntity()
      port.addComponent(Port(fragment: eid, direction: dir, ordinal: i.uint))  
      port.addComponent(valuetype)  
      port.addComponent(metadata)
      port.addComponent(Rotation(angle: i.float * 0.1))

  spawn_ports(Input, a.inputs)
  spawn_ports(Output, a.outputs)
  
  eid

proc addCord*(s: var ECSState; src, dst: EntityOf[Port]): EntityOf[Cord] =
  let eid = s.w.newEntity()
  eid.addComponent(Cord(src: src, dst: dst))
  eid

proc get_port*(s: ECSState, f: EntityOf[Fragment], direction: FlowDirection, ordinal: uint): EntityOf[Port] =
  for (eid, port) in s.w.getComponentCollection(Port).items:
    if port.fragment == f and port.direction == direction and port.ordinal == ordinal:
      return s.w.entities[eid]
  raise newException(KeyError, "No such port")
