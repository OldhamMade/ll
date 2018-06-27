# source is included since we're not exporting
# anything to be used by other libs/packages
include ll

import algorithm
import future
import os
import re
import sequtils
import strutils
import unittest

import tempfile

import util


var
  tmpdir: string = nil



proc setUpBasicListing() =
  tmpdir = mkdtemp()
  if tmpdir != nil:
    echo "  [su] Created tmpdir: $#".format(tmpdir).fgDarkGray()

  for i in 1..9:
    writeFile(tmpdir / $i, $i)


proc setUpDirectoryListing() =
  tmpdir = mkdtemp()
  if tmpdir != nil:
    echo "  [su] Created tmpdir: $#".format(tmpdir).fgDarkGray()

  for i in 1..9:
    createDir(tmpdir / $i)


proc setUpSymlinkListing() =
  tmpdir = mkdtemp()
  if tmpdir != nil:
    echo "  [su] Created tmpdir: $#".format(tmpdir).fgDarkGray()

  for i in 1..4:
    writeFile(tmpdir / $i, $i)

  for pair in zip(toSeq(1..4), toSeq(5..9)):
    createSymlink(tmpdir / $pair.a, tmpdir / $pair.b)


proc setUpSizedListing() =
  tmpdir = mkdtemp()
  if tmpdir != nil:
    echo "  [su] Created tmpdir: $#".format(tmpdir).fgDarkGray()

  for i in 1..9:
    writeFile(tmpdir / $i, $i.repeat(i))


proc tearDownSuite() =
  if tmpdir != nil:
    removeDir(tmpdir)
    if not existsDir(tmpdir):
      echo "  [td] Removed tmpdir: $#".format(
        tmpdir,
      ).fgDarkGray()


proc getExampleOutput(sortReverse=false, sortBySize=false) =
  echo "\nExample output:"
  echo ll(tmpdir,
          sortReverse=sortReverse,
          sortBySize=sortBySize,
  )
  echo ""


suite "basic file listing tests":

  setUpBasicListing()
  
  test "it returns the correct number of entries":
    var
      lines = ll(tmpdir).splitLines()
      entries: seq[string]

    lines = filter(lines, (l) => not l.isSummaryLine).map(clean)

    entries = @[]
    
    for line in lines:
      entries.add(line)

    check entries.len == 9

  test "it returns sorted entries":
    var
      entries: seq[string]
      expected: seq[string]
      lines = ll(tmpdir).splitLines()

    lines = filter(lines, (l) => not l.isSummaryLine).map(clean)

    entries = @[]
    expected = @[]

    for i in 1..9:
      expected.add($i)

    for line in lines:
      var
        parts = line.split(re"\s+")

      entries.add(parts[^1])

    check entries.len == expected.len
    check entries == expected

  test "it contains permissions":
    var
      lines = ll(tmpdir).splitLines()
    
    lines = filter(lines, (l) => not l.isSummaryLine).map(clean)

    for line in lines:
      var permissions = line.split[0]
      permissions = permissions[1..^1]
      
      check permissions.len == 9
      
      for permission in permissions:
        check permission in ['r', 'w', 'x', '-']

  test "it contains owner details":
    var
      lines = ll(tmpdir).splitLines()
    
    lines = filter(lines, (l) => not l.isSummaryLine).map(clean)

    let
      reUnixName = re"\b[a-zA-Z]+[a-zA-Z_0-9]*\b"
 
    for line in lines:
      var
        parts = line.split(re"\s+")
        user = parts[2]
        group = parts[3]

      check:
        match(user, reUnixName)
        match(group, reUnixName)

  test "it contains a modified datetime":
    var
      lines = ll(tmpdir).splitLines()
    
    lines = filter(lines, (l) => not l.isSummaryLine).map(clean)

    let
      reDay = re"\b\d\d?\b"
      reMonth = re"[JFMASOND][a-z]{2}"
      reTime = re"[0-2]\d:[0-5]\d"
 
    for line in lines:
      var
        parts = line.split(re"\s+")[5..7]
        day, month, time: string

      day = parts[0]
      month = parts[1]
      time = parts[2]

      check:
        match(day, reDay)
        match(month, reMonth)
        match(time, reTime)

  getExampleOutput()
  tearDownSuite()


suite "directory listing tests":
  
  setUpDirectoryListing()

  test "it returns the correct number of entries":
    var
      lines = ll(tmpdir).splitLines()
      entries: seq[string]

    lines = filter(lines, (l) => not l.isSummaryLine).map(clean)

    entries = @[]
    
    for line in lines:
      entries.add(line)

    check entries.len == 9

  test "it identifies directories":
    var
      lines = ll(tmpdir).splitLines()

    lines = filter(lines, (l) => not l.isSummaryLine).map(clean)

    for line in lines:
      check line[0] == 'd'
    
  getExampleOutput()
  tearDownSuite()


suite "symlink listing tests":
  
  setUpSymlinkListing()

  test "it returns the correct number of entries":
    var
      lines = ll(tmpdir).splitLines()
      entries: seq[string]

    lines = filter(lines, (l) => not l.isSummaryLine).map(clean)

    entries = @[]
    
    for line in lines:
      entries.add(line)

    check entries.len == 8

  test "it identifies symlinks":
    var
      lines = ll(tmpdir).splitLines()
      entries: seq[string]

    lines = filter(lines, (l) => not l.isSummaryLine).map(clean)

    entries = @[]
    
    for line in lines:
      if line[0] == 'l':
         entries.add(line)

    check entries.len == 4
    
  test "it displays symlinks":
    var
      lines = ll(tmpdir).splitLines()
      entries: seq[string]

    lines = filter(lines, (l) => not l.isSummaryLine).map(clean)

    entries = @[]
    
    for line in lines:
      if " -> " in line:
         entries.add(line)

    check entries.len == 4
    
  getExampleOutput()
  tearDownSuite()


suite "formatting tests":

  test "it calculates widths correctly":
    let
      lines = @[
        ["1",
         "1",
         "1",
         "1",
         "1",
         "1",
         "1",
         "1",
         "1",
         "1",
        ],
        ["55555",
         "55555",
         "55555",
         "55555",
         "55555",
         "55555",
         "55555",
         "55555",
         "55555",
         "55555",
        ]
      ]

    check:
      getWidth(lines) == 5

  test "it calculates widths correctly for colorized values":
    let
      lines = @[
        ["1".fgColor(1),
         "1",
         "1",
         "1",
         "1",
         "1",
         "1",
         "1",
         "1",
         "1",
        ],
        ["55555".fgColor(2),
         "55555",
         "55555",
         "55555",
         "55555",
         "55555",
         "55555",
         "55555",
         "55555",
         "55555",
        ]
      ]

    check:
      getWidth(lines) == 5

  test "it should left-pad colorized text":
    let
      text = "a".fgColor(2)

    check:
      padLeft(text, 5).clean == "    a"

  test "it should right-pad colorized text":
    let
      text = "a".fgColor(2)

    check:
      padRight(text, 5).clean == "a    "


suite "sorting option tests: reverse":
      
  setUpBasicListing()

  test "it reverses ordering for -r flag":
    var
      entries: seq[string]
      expected: seq[string]
      lines = ll(tmpdir, sortReverse=true).splitLines()

    lines = filter(lines, (l) => not l.isSummaryLine).map(clean)

    entries = @[]
    expected = @[]

    for i in 1..9:
      expected.add($i)

    expected = expected.reversed

    for line in lines:
      var
        parts = line.split(re"\s+")

      entries.add(parts[^1])

    check entries.len == expected.len
    check entries == expected

  getExampleOutput(sortReverse=true)  
  tearDownSuite()


suite "sorting option tests: size":
      
  setUpSizedListing()

  test "it sorts by size order, descending":
    var
      entries: seq[string]
      expected: seq[string]
      lines = ll(tmpdir, sortBySize=true).splitLines()

    lines = filter(lines, (l) => not l.isSummaryLine).map(clean)

    entries = @[]
    expected = @[]

    for i in 1..9:
      expected.add($i)

    expected = expected.reversed

    for line in lines:
      var
        parts = line.split(re"\s+")

      entries.add(parts[^1])

    check entries.len == expected.len
    check entries == expected

  test "it sorts by size order, reversed":
    var
      entries: seq[string]
      expected: seq[string]
      lines = ll(tmpdir, sortBySize=true, sortReverse=true).splitLines()

    lines = filter(lines, (l) => not l.isSummaryLine).map(clean)

    entries = @[]
    expected = @[]

    for i in 1..9:
      expected.add($i)

    for line in lines:
      var
        parts = line.split(re"\s+")

      entries.add(parts[^1])

    check entries.len == expected.len
    check entries == expected

  getExampleOutput(sortBySize=true)
  tearDownSuite()
