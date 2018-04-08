# Package

version       = "0.1.0"
author        = "Phillip Oldham"
description   = "ll - a more informative ls, based on k"
license       = "MIT"
srcDir        = "src"
skipDirs      = @["tests"]
bin           = @["ll"]

# Dependencies

requires "nim >= 0.18.0"
requires "docopt >= 0.6.5"
requires "colorize >= 0.2.0"
requires "tempfile >= 0.1.5"

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
