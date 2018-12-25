# source is included since we're not exporting
# anything to be used by other libs/packages
include ll

import os
import strutils
import sugar
import unittest


suite "basic path tests":

  test "it provides absolute paths for common shortcuts":
    let
      trim = (s: string) => s.strip(leading=false, chars={'/'})

    check:
      getTargetPath("..").trim == expandFilename(getCurrentDir() / "..").trim
      getTargetPath(".").trim == getCurrentDir().trim
      getTargetPath("~").trim == getHomeDir().trim


  test "it recognises absolute paths":
    if defined(macosx):
      check getTargetPath("/tmp") == "/private/tmp"
    else:
      check getTargetPath("/tmp") == "/tmp"
