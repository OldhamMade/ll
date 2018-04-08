# source is included since we're not exporting
# anything to be used by other libs/packages
include ll

import algorithm
import strutils
import os
import oids
import unittest
import tempfile
import colorize

var tmpdir: string = nil

proc setUpSuite() =
  tmpdir = mkdtemp()
  if tmpdir != nil:
    echo "  [su] Created tmpdir: $#".format(tmpdir).fg_dark_gray()

  for i in 1..9:
    writeFile(tmpdir / $i, $i)


proc tearDownSuite() =
  
  if tmpdir != nil:
    removeDir(tmpdir)
    if not existsDir(tmpdir):
      echo "  [td] Removed tmpdir: $#".format(
        tmpdir,
      ).fg_dark_gray()


suite "basic file listing tests":

  setUpSuite()
  
  test "it returns the correct number of entries":
    var lines = ll(tmpdir).splitLines()
    var entries: seq[string]

    entries = @[]
    
    for line in lines:
      if $line != "":
        entries.add(line)

    check entries.len == 9

  tearDownSuite()

