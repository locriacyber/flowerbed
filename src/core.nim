type
  ValueType* = object # TODO
    metadata*: Metadata
  
  Effect* = object # TODO
    metadata*: Metadata

  Metadata* = object
    name*: string

  Algorithm* = object # TODO
    metadata*: Metadata
    inputs*: seq[(ValueType, Metadata)]
    outputs*: seq[(ValueType, Metadata)]
    effects*: seq[(Effect, Metadata)]

proc type*(xx: (ValueType, Metadata)): ValueType = xx[0]
proc metadata*(xx: (ValueType, Metadata)): Metadata = xx[1]

proc name*(a: Algorithm): string = a.metadata.name
proc withName*(name: string): Metadata =
  Metadata(
    name: name,
  )

### Dummy values section

const ValueType_Integer* = ValueType(
  metadata: withName("int"),
)
