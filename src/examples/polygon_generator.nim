import pixie/paths

var path = newPath()

path.moveTo(0.2, -1)
path.lineTo(-1, -1)
path.lineTo(-1, 1)
path.moveTo(0.2, 1)
path.quadraticCurveTo(ctrl: Vec2(x: 4, y: 0), to: Vec2(x: 0.2, y: -1))
path.close()

echo path.commandsToShapes(true, 1.0)