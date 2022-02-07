type
  ValueType* = object # TODO
  
  Effect* = object # TODO

  Algorithm* = object # TODO
    name*: string
    inputs*: seq[ValueType]
    outputs*: seq[ValueType]
    effects*: seq[Effect]
