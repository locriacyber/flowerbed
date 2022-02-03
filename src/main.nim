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

# proc example_draw_ring() =
#   drawLine 500, 0, 500, getScreenHeight(), fade(LIGHTGRAY, 0.6)
#   drawRectangle 500, 0, getScreenWidth() - 500, getScreenHeight(), fade(LIGHTGRAY, 0.3)

#   if doDrawRing:
#     drawRing(center, innerRadius, outerRadius, startAngle.float32, endAngle.float32, segments, fade(MAROON, 0.3))
#   if doDrawRingLines:
#     drawRingLines(center, innerRadius, outerRadius, startAngle.float32, endAngle.float32, segments, fade(BLACK, 0.4))
#   if doDrawCircleLines:
#     drawCircleSectorLines(center, outerRadius, startAngle.float32, endAngle.float32, segments, fade(BLACK, 0.4))

#   #  Draw GUI controls
#   # ------------------------------------------------------------------------------
#   startAngle = sliderBar((x: 600.0, y: 40.0, width: 120.0, height: 20.0), "StartAngle", "", startAngle, -450,450)
#   endAngle = sliderBar((x: 600.0, y: 70.0, width: 120.0, height: 20.0), "EndAngle", "", endAngle, -450,450)

#   innerRadius = sliderBar((x: 600.0, y: 140.0, width: 120.0, height: 20.0), "InnerRadius", "", innerRadius, 0,100)
#   outerRadius = sliderBar((x: 600.0, y: 170.0, width: 120.0, height: 20.0), "OuterRadius", "", outerRadius, 0,200)

#   segments = sliderBar((x: 600.0, y: 240.0, width: 120.0, height: 20.0), "Segments", "", segments.float, 0,100).int32

#   doDrawRing = checkBox((x: 600.0, y: 320.0, width: 20.0, height: 20.0), "Draw Ring", doDrawRing)
#   doDrawRingLines = checkBox((x: 600.0, y: 350.0, width: 20.0, height: 20.0), "Draw RingLines", doDrawRingLines)
#   doDrawCircleLines = checkBox((x: 600.0, y: 380.0, width: 20.0, height: 20.0), "Draw CircleLines", doDrawCircleLines)
