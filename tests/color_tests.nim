# source is included since we're not exporting
# anything to be used by other libs/packages
include ll

import unittest


suite "color display tests":

  test "it colorizes ages":
    let
      new = colByAge("foo", 0.int)
      old = colByAge("foo", 100000.int)
      ancient = colByAge("foo", 100000000.int)

    check:
      new != old
      new != ancient
      old != ancient
