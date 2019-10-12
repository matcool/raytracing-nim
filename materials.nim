proc reflect* (vec: Vec3, normal: Vec3): Vec3 =
  return vec - normal * (2.0 * dot(vec, normal))
    
proc refract* (vec: Vec3, normal: Vec3, ior: float, refracted: var Vec3): bool =
  var uv = normalize(vec)
  var dt = dot(uv, normal)
  var discriminant = 1.0 - ior * ior * (1.0 - dt*dt)
  if discriminant > 0:
      refracted = (normal * dt * -1 + uv) * ior - normal * sqrt(discriminant)
      return true
  else:
      return false

proc schlick* (cosine, ior: float): float =
  var r0 = (1 - ior) / (1 + ior)
  r0 = r0 * r0
  return r0 + (1 - r0) * pow((1 - cosine), 5)

type Material* = ref object of RootObj

type HitRecord* = object
  t*: float
  p*, normal*: Vec3
  material*: Material

type Lambertian* = ref object of Material
  albedo*: Vec3

type Metal* = ref object of Material
  albedo*: Vec3
  roughness*: float

type Dieletric* = ref object of Material
  ior*: float

method scatter* (material: Material, ray: Ray, rec: var HitRecord, attenuation: var Vec3, scattered: var Ray): bool {.base.} =
  quit "generic scatter shouldnt be called"

method scatter* (material: Lambertian, ray: Ray, rec: var HitRecord, attenuation: var Vec3, scattered: var Ray): bool =
  var target = rec.p + rec.normal + randomSpherePoint()
  scattered = Ray(ori: rec.p, dir: target - rec.p)
  attenuation = material.albedo
  return true

method scatter* (material: Metal, ray: Ray, rec: var HitRecord, attenuation: var Vec3, scattered: var Ray): bool =
  var reflected = reflect(normalize(ray.dir), rec.normal)
  scattered = Ray(ori: rec.p, dir: reflected + randomSpherePoint() * material.roughness)
  attenuation = material.albedo
  return dot(scattered.dir, rec.normal) > 0.0

method scatter* (material: Dieletric, ray: Ray, rec: var HitRecord, attenuation: var Vec3, scattered: var Ray): bool =
  var outNormal: Vec3
  var reflected = reflect(ray.dir, rec.normal)
  var refIndex: float
  attenuation = (1.0, 1.0, 1.0)
  var refracted: Vec3

  var reflectProb, cosine: float

  if dot(ray.dir, rec.normal) > 0:
    outNormal = rec.normal * -1
    refIndex = material.ior
    cosine = material.ior * dot(ray.dir, rec.normal) / ray.dir.length()
  else:
    outNormal = rec.normal
    refIndex = 1.0 / material.ior
    cosine = -dot(ray.dir, rec.normal) / ray.dir.length()

  
  reflectProb = if refract(ray.dir, outNormal, refIndex, refracted): schlick(cosine, material.ior)
                                                               else: 1.0
  
  scattered = Ray(ori: rec.p, dir: if rand() < reflectProb: reflected
                                                      else: refracted)

  return true