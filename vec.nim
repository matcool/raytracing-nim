import math

type Vec3* = tuple[x, y, z: float]

proc `+`* (v1, v2: Vec3): Vec3 =
  result.x = v1.x + v2.x
  result.y = v1.y + v2.y
  result.z = v1.z + v2.z

proc `+`* (v1: Vec3, i: float): Vec3 =
  result.x = v1.x + i
  result.y = v1.y + i
  result.z = v1.z + i

proc `+=`* (v1: var Vec3, v2: any) = v1 = v1 + v2

proc `-`* (v1, v2: Vec3): Vec3 =
  result.x = v1.x - v2.x
  result.y = v1.y - v2.y
  result.z = v1.z - v2.z

proc `-`* (v1: Vec3, i: float): Vec3 =
  result.x = v1.x - i
  result.y = v1.y - i
  result.z = v1.z - i

proc `-=`* (v1: var Vec3, v2: any) = v1 = v1 - v2

proc `*`* (v1, v2: Vec3): Vec3 =
  result.x = v1.x * v2.x
  result.y = v1.y * v2.y
  result.z = v1.z * v2.z

proc `*`* (v1: Vec3, i: float): Vec3 =
  result.x = v1.x * i
  result.y = v1.y * i
  result.z = v1.z * i

proc `*=`* (v1: var Vec3, v2: any) = v1 = v1 * v2
    
proc `/`* (v1, v2: Vec3): Vec3 =
  result.x = v1.x / v2.x
  result.y = v1.y / v2.y
  result.z = v1.z / v2.z

proc `/`* (vec: Vec3, i: float): Vec3 =
  result.x = vec.x / i
  result.y = vec.y / i
  result.z = vec.z / i

proc `/=`* (v1: var Vec3, v2: any) = v1 = v1 / v2

proc lengthSq* (vec: Vec3): float =
  return vec.x*vec.x + vec.y*vec.y + vec.z*vec.z
    
proc length* (vec: Vec3): float =
  return sqrt(vec.lengthSq())

proc normalize* (vec: Vec3): Vec3 =
  return vec / vec.length()

proc dot* (v1, v2: Vec3): float =
  return v1.x*v2.x + v1.y*v2.y + v1.z*v2.z

proc `|`* (v1, v2: Vec3): float = return dot(v1, v2)
  
proc dot* (vec: Vec3): float = return dot(vec, vec)

proc cross* (v1, v2: Vec3): Vec3 =
  return (v1.y * v2.z - v1.z * v2.y,
          v1.z * v2.x - v1.x * v2.z,
          v1.x * v2.y - v1.y * v2.x)

proc sqrt* (vec: Vec3): Vec3 =
  return (sqrt(vec.x), sqrt(vec.y), sqrt(vec.z))