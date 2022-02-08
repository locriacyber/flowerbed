import nimraylib_now
import core, dragdrop


type
  Id* = int64

  IdIssuer* = object
    next_id: Id

  Index*[T] = Id

proc next*(issuer: var IdIssuer): Id =
  let id = issuer.next_id
  issuer.next_id += 1
  id

type
  Node* = object
    center*: Vector2
    radius*: float
    dnd_id*: DragDropObjectHandle

  PortType* {.pure.} = enum
    Input
    Output

  Port* = object
    cord*: Index[Cord]
    angle*: Angle
    dnd_id*: DragDropObjectHandle
    `type`*: PortType
  
  Fragment* = object
    algorithm*: Algorithm
    node*: Index[Node]
    inputs*: seq[Port]
    outputs*: seq[Port]

  CordEnd* = object
    fragment*: Index[Fragment]
    port_id*: uint
  
  Cord* = object
    src*: CordEnd # output of src
    dst*: CordEnd # input of dst
