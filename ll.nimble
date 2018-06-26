# Package

version       = "0.1.0"
author        = "Phillip Oldham"
description   = "ll - a more informative ls, based on k"
license       = "MIT"
srcDir        = "src"
skipDirs      = @["tests"]
skipFiles     = @["colors.nim"]
bin           = @["ll"]

# Dependencies

requires "nim >= 0.18.0"
requires "docopt >= 0.6.5"
requires "tempfile >= 0.1.5"
requires "memo >= 0.2.1"

# Tests

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
  setCommand "c", "src/ll.nim"
