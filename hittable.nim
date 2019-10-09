type Hittable* = ref object of RootObj
  material*: Material

type Sphere = ref object of Hittable
  center*: Vec3
  radius*: float

method hit*(hittable: Hittable, ray: Ray, tMin, tMax: float, rec: var HitRecord): bool {.base.} =
  quit "generic Hittable.hit should never be called"

method hit*(sphere: Sphere, ray: Ray, tMin, tMax: float, rec: var HitRecord): bool =
  #[
    a 3d sphere is denoted by all points (x,y,z) where
    x² + y² + z² = r² (r being the radius)
    which after some (magic) becomes
    t² * dot(dir, dir) + 2t * dot(dir, origin − center) + dot(origin - center, origin - center) − r² = 0
    which as a quadratic equation basically means:
      a = dot(dir, dir)
      b = 2 * dot(dir, origin - center)
      c = dot(origin - center, origin - center) - r²
  ]#
  var oc = ray.ori - sphere.center
  var a = dot(ray.dir)
  var b = 2.0 * dot(oc, ray.dir)
  var c = dot(oc) - sphere.radius * sphere.radius
  #[
    ray hits sphere if the equation at² + bt + c = 0 (where a, b and c are defined above) has any roots
    for the hit point we just use the quadratic formula (t = (-b ± √delta) / 2a)
  ]#
  var delta = b*b - 4*a*c
  if delta < 0.0: return false
  else:
    var deltaSqrt = sqrt(delta)
    var pos = (-b + deltaSqrt) / (2.0 * a)
    var neg = (-b - deltaSqrt) / (2.0 * a)
    if (pos < tMax and pos > tMin) or (neg < tMax and neg > tMin):
      rec.t = if neg < tMax and neg > tMin: neg
                                      else: pos
      rec.p = ray.at(rec.t)
      rec.normal = (rec.p - sphere.center) / sphere.radius
      rec.material = sphere.material
      return true
    return false

proc hit*(toHit: openArray[Hittable], ray: Ray, tMin, tMax: float, rec: var HitRecord): bool =
  var tempRec: HitRecord
  var hitAnything = false
  var closest: float64 = tMax
  for hittable in items(toHit):
    if hittable.hit(ray, tMin, closest, tempRec):
      hitAnything = true
      closest = tempRec.t
      rec = tempRec
  return hitAnything