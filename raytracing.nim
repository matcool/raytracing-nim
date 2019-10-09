{.optimization: speed.}

import streams
import strformat
import vec
import math
from strutils import parseInt
import random

include ray
include rand
include materials
include hittable

type Camera = object
  lowerLeftCorner: Vec3
  horizontal: Vec3
  vertical: Vec3
  origin: Vec3
  u, v, w: Vec3
  lensRadius: float

proc newCamera* (lookFrom, lookAt, vUp: Vec3, vFov, aspect, aperture, focusDist: float): Camera =
  result.lensRadius = aperture * 0.5
  var theta = vFov * PI / 180;
  var hHeight = tan(theta * 0.5);
  var hWidth = aspect * hHeight;
  result.origin = lookFrom
  result.w = normalize(lookFrom - lookAt)
  result.u = normalize(cross(vUp, result.w))
  result.v = cross(result.w, result.u)
  result.lowerLeftCorner = result.origin -
                           result.u * hWidth * focusDist -
                           result.v * hHeight * focusDist -
                           result.w * focusDist
  result.horizontal = result.u * 2 * hWidth * focusDist
  result.vertical = result.v * 2 * hHeight * focusDist

proc getRay* (self: Camera, s, t: float): Ray =
  var rd = randomCirclePoint() * self.lensRadius
  var offset = self.u * rd.x + self.v + rd.y
  return Ray(ori: self.origin + offset,
             dir: self.lowerLeftCorner + self.horizontal * s + self.vertical * t - self.origin - offset)

proc color(ray: Ray, world: openArray[Hittable], depth: int): Vec3 =
  var rec: HitRecord
  if world.hit(ray, 0.001, Inf, rec):
    var scattered: Ray
    var attenuation: Vec3
    if (depth < 50 and rec.material.scatter(ray, rec, attenuation, scattered)):
      return attenuation * color(scattered, world, depth+1)
    else:
      return (0.0, 0.0, 0.0)
  else:
    var unitDir = normalize(ray.dir)
    var t = 0.5 * (unitDir.y + 1.0)
    return (0.5, 0.7, 1.0) * t + (1.0 - t)

when isMainModule:
  var width = 400
  var height = 200
  # Number of samples to take per pixel
  var samples = 100

  var world: array[4, Hittable]

  world[0] = Sphere(center: (0.0, 0.0, -1.0), radius: 0.5, material: Lambertian(albedo: (0.1, 0.2, 0.5)))
  world[1] = Sphere(center: (0.0, -100.5, -1.0), radius: 100, material: Lambertian(albedo: (0.8, 0.8, 0.0)))
  world[2] = Sphere(center: (1.0, 0.0, -1.0), radius: 0.5, material: Metal(albedo: (0.8, 0.6, 0.2), roughness: 0.7))
  world[3] = Sphere(center: (-1.0, 0.0, -1.0), radius: 0.5, material: Metal(albedo: (1.0, 1.0, 1.0), roughness: 0.1))
  
  var lookFrom = (3.0, 3.0, 2.0)
  var lookAt = (0.0, 0.0, -1.0)

  var camera = newCamera(lookFrom, lookAt, (0.0, 1.0, 0.0), 20, width / height, 2.0, length(lookFrom - lookAt))

  var file = newFileStream("img.ppm", fmWrite)
  if not isNil(file):
    file.writeLine(&"P3\n{width} {height}\n255")

    for y in countdown(height-1, 0):
      for x in 0..<width:
        
        var col: Vec3
        for _ in 0..<samples:
          var u = (float(x) + rand()) / float(width)
          var v = (float(y) + rand()) / float(height)
          var ray = camera.getRay(u, v)
          col += color(ray, world, 0)
        
        col /= float(samples)
        # fix gamma
        col = sqrt(col)
        
        var sr = int(255 * min(col.x, 1.0))
        var sg = int(255 * min(col.y, 1.0))
        var sb = int(255 * min(col.z, 1.0))
        file.writeLine(&"{sr} {sg} {sb}")
    file.close()