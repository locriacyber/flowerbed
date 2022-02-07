import nimraylib_now
import geometry, core


type
  Node* = object
    center*: Vector2
    radius*: float

  Port* = object
    cord*: ref Cord
    angle*: Angle
  
  Fragment* = object
    algorithm*: Algorithm
    node*: ref Node
    inputs*: seq[Port]
    outputs*: seq[Port]

  CordEnd* = object
    fragment*: ref Fragment
    port_id*: uint
  
  Cord* = object
    src*: CordEnd # output of src
    dst*: CordEnd # input of dst
