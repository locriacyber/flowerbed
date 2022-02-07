import options, nimraylib_now

type
  DragHandle* = object
    drag*: proc (cursor_moved: Vector2): void
    drop*: proc (cursor_pos: Vector2): void

  DragDropObject* = object
    check_collision*: proc (cursor_pos: Vector2): bool
    start_drag*: proc (cursor_pos: Vector2): DragHandle

  DragDropManager* = object
    candidates*: seq[DragDropObject]
    dragging*: Option[DragHandle]

proc try_drag*(dnd: var DragDropManager, start_pos: Vector2) =
  for i in 0..<dnd.candidates.len:
    let draggable_object = dnd.candidates[i]
    if draggable_object.check_collision(start_pos):
      dnd.dragging = some(draggable_object.start_drag(start_pos))
      break

proc try_drop*(dnd: var DragDropManager, end_pos: Vector2) =
  if dnd.dragging.isSome:
    dnd.dragging.get.drop(end_pos)
    dnd.dragging = none(DragHandle)

proc move*(dnd: var DragDropManager, displacement: Vector2) =
  if dnd.dragging.isSome:
    dnd.dragging.get.drag(displacement)
