import std/[strformat, sets]
import nimraylib_now
import consts, core, dragdrop, mainstate, skeuomorph

let algorithm_dummy = Algorithm(
  metadata: withName("2 in 2 out"),
  inputs: @[
    (ValueType_Integer, withName("a")),
    (ValueType_Integer, withName("b")),
    (ValueType_Integer, withName("e")),
  ],
  outputs: @[
    (ValueType_Integer, withName("c")),
    (ValueType_Integer, withName("d")),
    (ValueType_Integer, withName("f")),
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

import options

proc main() =
  var dnd: DragDropManager
  var state: MainState

  var font: Font
  proc init(s: var MainState) =
    font = getFontDefault()
    let trunk = s.addNode(dnd, Vector2(x: screenWidth/2.0, y: screenHeight/2.0), 32)
    let frag_center = s.addFragment(dnd, algorithm_dummy, trunk)
    let input = s.addNode(dnd, Vector2(x: screenWidth/2.0 - 200, y: screenHeight/2.0), 20)
    let frag_input = s.addFragment(dnd, algorithm_1out, input)
    let output = s.addNode(dnd, Vector2(x: screenWidth/2.0 + 200, y: screenHeight/2.0), 20)
    let frag_output = s.addFragment(dnd, algorithm_1in, output)
    discard s.addCord(frag_input, frag_center, 0, 0)
    discard s.addCord(frag_center, frag_output, 0, 0)

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
      dnd.draw()
      drawFPS(10, 10)
      var text_dragging = "Dragging:"
      for dragged in state.dragging.items:
        text_dragging.add "\n"
        text_dragging.add fmt"  {dragged}"
      drawText(text_dragging.cstring, 10, 36, 10, Black)

  block:
    let f = open(save_filename, fmWrite)
    defer: f.close()
    state.save(f)


when isMainModule:
  main()
