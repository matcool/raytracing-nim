type Ray* = object
  ori*, dir*: Vec3

proc at* (ray: Ray, t: float): Vec3 =
  return ray.ori + ray.dir * t