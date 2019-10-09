randomize()

proc randomSpherePoint* (): Vec3 =
  # result = (10.0, 0.0, 0.0)
  # while result.lengthSq() >= 1.0:
  #   # this turns it from 0..<1 to -1..1
  #   result = ((rand(), rand(), rand()) * 2.0) - 1.0
  var a = rand(PI * 2.0)
  var z = rand(2.0) - 1.0
  var r = sqrt(1.0 - z * z)
  return (r * cos(a), r * sin(a), z)

proc rand* (): float =
  # use 0.999999 so its from 0 <= x < 1
  return rand(1.0 - 1e-10)

proc randomCirclePoint* (): Vec3 =
  # Generates a random point on a circle using polar coordinates
  var angle = rand(PI * 2.0)
  var radius = rand(1.0)
  result.x = cos(angle) * radius
  result.y = sin(angle) * radius