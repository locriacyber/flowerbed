import std/[options, tables, sugar]
import nimraylib_now

type
  DragHandle* = object
    drag*: proc (cursor_moved: Vector2): void
    drop*: proc (cursor_pos: Vector2): void

  DragDropObject* {.requiresInit.} = object
    check_collision*: proc (cursor_pos: Vector2): bool
    start_drag*: proc (cursor_pos: Vector2): DragHandle
    debug_draw*: proc ()

  DragDropObjectHandle* = int64

  DragDropManager* = object
    next_id: DragDropObjectHandle
    candidates: OrderedTable[DragDropObjectHandle, (int, DragDropObject)]
    dragging*: Option[DragHandle]

proc add*(dnd: var DragDropManager, o: DragDropObject, priority: int = 0): DragDropObjectHandle =
  let id = dnd.next_id
  dnd.next_id += 1
  dnd.candidates[id] = (priority, o)
  dnd.candidates.sort((a, b) => b[0] - a[0]) # higher priority first
  id

proc remove*(dnd: var DragDropManager, id: DragDropObjectHandle) =
  dnd.candidates.del(id)

proc try_drag*(dnd: var DragDropManager, start_pos: Vector2) =
  for entry in dnd.candidates.values:
    let draggable_object = entry[1]
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

proc draw*(dnd: DragDropManager) =
  when defined(debug):
    for c in dnd.candidates.values:
      c[1].debug_draw()