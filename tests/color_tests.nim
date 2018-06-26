# source is included since we're not exporting
# anything to be used by other libs/packages
include ll

import unittest


suite "color display tests":

  test "it colorizes ages":
    let
      new = colorizeByAge("foo", 0.int)
      old = colorizeByAge("foo", 100000.int)
      ancient = colorizeByAge("foo", 100000000.int)

    check:
      new != old
      new != ancient
      old != ancient

  test "it colorizes sizes":
    let
      tiny = colorizeBySize("foo", 0.int)
      small = colorizeBySize("foo", 10000.int)
      huge = colorizeBySize("foo", 1000000000000.int)

    check:
      tiny != small
      tiny != huge
      small != huge
