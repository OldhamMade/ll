# source is included since we're not exporting
# anything to be used by other libs/packages
include ll

import unittest


suite "git tests":

  test "it returns a true when git is available":
    ## It's expected that git will be available
    ## on the testing machine

    let
      available = gitAvailable()

    check:
      available == true


  test "it returns false when git is missing":
    let
      available = gitAvailable("MISSING_EXECUTABLE")

    check:
      available == false
