# Nim Raytracer
Nim implementation of an raytracer from the book [Ray tracing in one weekend](https://raytracing.github.io/books/RayTracingInOneWeekend.html).\
Code is also multithread

![raytracer render](https://raw.githubusercontent.com/matcool/raytracing-nim/master/result_hd.png "Image produced by the code")

Default code renders a 1280x720 image with 128 samples (these values can be changed on line 62 of `raytracing.nim`).
# Building
As there is no external depdencies, you just compile with
```
nim compile -d:release --threads:on raytracing.nim
```