{.optimization: speed.}

# import streams
import strformat
# from strutils import parseInt
import vec
import math
import random
import locks
import simplepng

# use include instead of import to avoid circular depdencies (which i don't know how to deal with lol)
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
    # var unitDir = normalize(ray.dir)
    # var t = 0.5 * (unitDir.y + 1.0)
    return (0.55, 0.79, 0.93)# * t + (1.0 - t)

when isMainModule:
  const width = 720
  const height = 720
  # Number of samples to take per pixel
  var samples = 100

  # in how many pieces to split the screen for the multi threading
  const cols = 4
  const rows = 2
  var sliceW = int(width/cols)
  var sliceH = int(height/rows)

  const ballsW = 11
  const ballsH = 8

  type worldT = array[ballsW*ballsH+2, Hittable]
  var world: worldT

  world[0] = Sphere(center: (0.0, -500.0, -1.0), radius: 500.0, material: Lambertian(albedo: (0.7, 0.7, 0.8)))
  world[1] = Sphere(center: (1.4, 1.0, -0.2), radius: 1.0, material: Metal(albedo: (1.0, 0.8, 0.4), roughness: 0.05))
  # world[0] = Sphere(center: (0.0, 0.0, -1.0), radius: 0.5, material: Lambertian(albedo: (0.1, 0.2, 0.5)))
  # world[2] = Sphere(center: (1.0, 0.0, -1.0), radius: 0.5, material: Metal(albedo: (0.8, 0.6, 0.2), roughness: 0.7))
  # world[3] = Sphere(center: (-1.0, 0.0, -1.0), radius: 0.5, material: Metal(albedo: (1.0, 1.0, 1.0), roughness: 0.1))
  for x in 0..<ballsW:
    for y in 0..<ballsH:
      var mat: Material
      var color = (rand(1.0), rand(1.0), rand(1.0))
      case rand(50):
        of 0..47: mat = Lambertian(albedo: color)
        of 48, 49: mat = Metal(albedo: color, roughness: rand(1.0))
        of 50: mat = Dieletric(ior: 1.3+rand(0.4))
        else: quit("wtf")
      var r = 0.24 + rand(0.01)
      var pos = (rand(1.0), 0.0, rand(1.0)) * 2.0 - 1.0
      pos *= 0.5
      pos = (float(x) - ballsW * 0.5 + pos.x, r, float(y) - ballsH * 0.5 + pos.z)
      world[y * ballsW + x + 2] = Sphere(center: pos, radius: r, material: mat)

  echo "done making world"
  
  var lookFrom: Vec3
  var lookAt: Vec3

  var camera: Camera

  var pixels: array[width*height, array[3, float]]

  type Data = tuple[x, y: int, world: ptr worldT]

  var lock: Lock

  proc threadFunc(data: Data) {.thread.} =
    var col: Vec3
    var x, y: int
    for yOff in 0..<sliceH:
      for xOff in 0..<sliceW:
        x = data.x + xOff
        y = data.y + yOff
        col = (0.0, 0.0, 0.0)
        for _ in 0..<samples:
          var u = (float(x) + rand()) / float(width)
          var v = (float(y) + rand()) / float(height)
          var ray = camera.getRay(u, v)
          col += color(ray, data.world[], 0)
        
        col /= float(samples)
        # fix gamma
        col = sqrt(col)
        acquire(lock)
        pixels[(height - y - 1) * width + x] = [col.x, col.y, col.z]
        release(lock)
    # acquire(lock)
    # echo "thread done"
    # release(lock)

  initLock(lock)

  var frames = 0
  for frame in 0..frames:
    var t = frame/(frames+1)
    #lookFrom = (cos(t * PI * 2.0)*3.0, 3.0, -1.0+sin(t * PI * 2.0)*3.0)
    lookFrom = (0.0, 1.0, 6.0-t*8.0)
    lookAt = (0.0, 0.5, -1.0-t*8.0)

    camera = newCamera(lookFrom, lookAt, (0.0, 1.0, 0.0), 40, width / height, 0.2, length(lookFrom - lookAt))

    var threads: array[cols*rows, Thread[Data]]
    for y in 0..<rows:
      for x in 0..<cols:
        var i = y * cols + x
        createThread(threads[i], threadFunc, (x * sliceW, y * sliceH, addr(world)))
    joinThreads(threads)
    echo fmt"frame {frame} done"
    discard threads

    # var file = newFileStream("img.ppm", fmWrite)
    # if not isNil(file):
    #   file.writeLine(&"P3\n{width} {height}\n255")

    #   for y in 0..<height:
    #     for x in 0..<width:
    #       var col = pixels[y * width + x]
    #       var sr = int(255 * min(col[0], 1.0))
    #       var sg = int(255 * min(col[1], 1.0))
    #       var sb = int(255 * min(col[2], 1.0))
    #       file.writeLine(&"{sr} {sg} {sb}")
    #   file.close()

    var img = initPixels(width, height)
    img.fill(255, 255, 255, 255)
    var i = 0
    for pixel in img.mitems:
      var pix = pixels[i]
      pixel.setColor(int(255 * pix[0]), int(255 * pix[1]), int(255 * pix[2]), 255)
      inc(i)

    simplePNG(fmt"img{frame}.png", img)