import nimraylib_now
import mainstate
import consts

proc main() =
  #  Initialization
  # --------------------------------------------------------------------------------------
  

  initWindow screenWidth, screenHeight, "raylib [shapes] example - draw ring"

  setTargetFPS 60 #  Set our game to run at 60 frames-per-second
  # --------------------------------------------------------------------------------------

  var state = init[State]()
  
  discard getFrameTime() # clear dt

  #  Main game loop
  while not windowShouldClose(): #  Detect window close button or ESC key
    #  Update
    # ----------------------------------------------------------------------------------
    #  NOTE: All variables update happens inside GUI control functions
    # ----------------------------------------------------------------------------------

    #  Draw
    # ----------------------------------------------------------------------------------
    beginDrawing()

    clearBackground RAYWHITE

    drawFPS 10, 10
    let dt = getFrameTime()
    state.update_n_draw(dt)
    endDrawing()
    # ----------------------------------------------------------------------------------

  #  De-Initialization
  # --------------------------------------------------------------------------------------
  closeWindow() #  Close window and OpenGL context
  # --------------------------------------------------------------------------------------

when isMainModule:
  main()
