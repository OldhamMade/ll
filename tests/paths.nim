# source is included since we're not exporting
# anything to be used by other libs/packages
include ll

import strutils
import os
import unittest


suite "basic path tests":

  test "it provides absolute paths for common shortcuts":
    check:
      getTargetPath("..") == getCurrentDir() / ".."
      getTargetPath(".") == getCurrentDir()
      getTargetPath("~") == getHomeDir()


  test "it recognises absolute paths":
    check:
      getTargetPath("/tmp") == "/tmp"
