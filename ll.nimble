# Package

version       = "0.2.0"
author        = "Phillip Oldham"
description   = "ll - a more informative ls, based on k"
license       = "MIT"
srcDir        = "src"
bin           = @["ll"]

# Dependencies

requires "nim >= 0.20.0"
requires "cligen >= 0.9.31"
requires "tempfile >= 0.1.5"
requires "memo >= 0.2.1"


task debug, "Build with debug enabled":
  --hints: on
  --linedir: on
  --stacktrace: on
  --linetrace: on
  --debuginfo
  --path:"src"
  --verbose
  setCommand "c", "src/ll.nim"

task test, "Runs the test suite":
  --hints: off
  --linedir: on
  --stacktrace: on
  --linetrace: on
  --debuginfo
  --path:"src"
  --verbose
  --run
  setCommand "c", "tests/all.nim"

task profile, "Build with the profiler enabled":
  --hints: off
  --linedir: on
  --profiler:on
  --stacktrace: on
  --linetrace: on
  --debuginfo
  --path:"src"
  --verbose
  --run
  setCommand "c", "tests/all.nim"
