import nimraylib_now
import consts, core, dragdrop, mainstate

let algorithm_dummy = Algorithm(
  metadata: withName("2 in 2 out"),
  inputs: @[
    (ValueType_Integer, withName("a")),
    (ValueType_Integer, withName("b")),
  ],
  outputs: @[
    (ValueType_Integer, withName("c")),
    (ValueType_Integer, withName("d")),
  ],
)

let algorithm_1out = Algorithm(
  metadata: withName("1 out"),
  inputs: @[],
  outputs: @[
    (ValueType_Integer, withName("output"))
  ],
)

let algorithm_1in = Algorithm(
  metadata: withName("1 in"),
  inputs: @[
    (ValueType_Integer, withName("input"))
  ],
  outputs: @[],
)

proc main() =
  var dnd: DragDropManager
  var state: MainState

  var font: Font
  proc init(s: var MainState) =
    font = getFontDefault()
    let trunk = s.addNode(dnd, Vector2(x: screenWidth/2.0, y: screenHeight/2.0), 32)
    let frag_center = s.addFragment(algorithm_dummy, trunk)
    let input = s.addNode(dnd, Vector2(x: screenWidth/2.0 - 200, y: screenHeight/2.0), 20)
    let frag_input = s.addFragment(algorithm_1out, input)
    let output = s.addNode(dnd, Vector2(x: screenWidth/2.0 + 200, y: screenHeight/2.0), 20)
    let frag_output = s.addFragment(algorithm_1in, output)
    discard s.addCord((frag_input, 0.uint), (frag_center, 0.uint))
    discard s.addCord((frag_center, 0.uint), (frag_output, 0.uint))

  proc handle_drag_and_drop() =
    let mousepos = getMousePosition()
    let mousedelta = getMouseDelta()
    if isMouseButtonPressed(MouseButton.LEFT):
      dnd.try_drag(mousepos)
    dnd.move(mousedelta)
    if isMouseButtonReleased(MouseButton.LEFT):
      dnd.try_drop(mousepos)
  
  const save_filename = "/tmp/flowerbed.save"
  
  initWindow screenWidth, screenHeight, "node test"
  defer: closeWindow()

  setTargetFPS 60

  try:
    let f = open(save_filename, fmRead)
    defer: f.close()
    state.load(f)
  except IOError:
    init(state)
    
  discard getFrameTime()
  
  while not windowShouldClose():
    let dt = getFrameTime()
    handle_drag_and_drop()
    state.separate_ports(dt)  
  
    block:
      beginDrawing()
      defer: endDrawing()
      clearBackground Raywhite
      state.draw(font=font)
      drawFPS(10, 10)

  block:
    let f = open(save_filename, fmWrite)
    defer: f.close()
    state.save(f)


when isMainModule:
  main()
