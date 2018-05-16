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


proc tearDownSuite() =
  if tmpdir != nil:
    removeDir(tmpdir)
    if not existsDir(tmpdir):
      echo "  [td] Removed tmpdir: $#".format(
        tmpdir,
      ).fgDarkGray()


proc getExampleOutput() =
  echo "\nExample output:"
  echo ll(tmpdir)
  echo ""


suite "basic file listing tests":

  setUpBasicListing()
  
  test "it returns the correct number of entries":
    var
      lines = ll(tmpdir).splitLines()
      entries: seq[string]

    lines = filter(lines, (l) => not l.isSummaryLine)

    entries = @[]
    
    for line in lines:
      entries.add(line)

    check entries.len == 9

  test "it returns sorted entries":
    var
      entries: seq[string]
      expected: seq[string]
      lines = ll(tmpdir).splitLines()

    lines = filter(lines, (l) => not l.isSummaryLine)

    entries = @[]
    expected = @[]

    for i in 1..9:
      expected.add($i)

    for line in lines:
      var
        parts = line.split(re"\s+")

      entries.add(parts[8])

    entries = map(entries, (e) => e.clean)

    check entries.len == expected.len
    check entries == expected

  test "it contains permissions":
    var
      lines = ll(tmpdir).splitLines()
    
    lines = filter(lines, (l) => not l.isSummaryLine)

    for line in lines:
      var permissions = line.split[0]
      permissions = permissions[1..^1]
      
      check permissions.len == 9
      
      for permission in permissions:
        check permission in ['r', 'w', 'x', '-']

  test "it contains owner details":
    var
      lines = ll(tmpdir).splitLines()
    
    lines = filter(lines, (l) => not l.isSummaryLine)

    let
      reUnixName = re"\b[a-zA-Z]+[a-zA-Z_0-9]*\b"
 
    for line in lines:
      var
        parts = line.split(re"\s+")
        user = parts[2].clean
        group = parts[3].clean

      check:
        match(user, reUnixName)
        match(group, reUnixName)

  test "it contains a modified datetime":
    var
      lines = ll(tmpdir).splitLines()
    
    lines = filter(lines, (l) => not l.isSummaryLine)

    let
      reDay = re"\b\d\d?\b"
      reMonth = re"[JFMASOND][a-z]{2}"
      reYear = re"[0-2]\d:[0-5]\d"
 
    for line in lines:
      var
        parts = line.split(re"\s+")
        day = parts[5]
        month = parts[6]
        time = parts[7]

      check:
        match(day, reDay)
        match(month, reMonth)
        match(time, reYear)

  getExampleOutput()
  tearDownSuite()


suite "directory listing tests":
  
  setUpDirectoryListing()

  test "it returns the correct number of entries":
    var
      lines = ll(tmpdir).splitLines()
      entries: seq[string]

    lines = filter(lines, (l) => not l.isSummaryLine)

    entries = @[]
    
    for line in lines:
      entries.add(line)

    check entries.len == 9

  test "it identifies directories":
    var
      lines = ll(tmpdir).splitLines()

    lines = filter(lines, (l) => not l.isSummaryLine)

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

    lines = filter(lines, (l) => not l.isSummaryLine)

    entries = @[]
    
    for line in lines:
      entries.add(line)

    check entries.len == 8

  test "it identifies symlinks":
    var
      lines = ll(tmpdir).splitLines()
      entries: seq[string]

    lines = filter(lines, (l) => not l.isSummaryLine)

    entries = @[]
    
    for line in lines:
      if line[0] == 'l':
         entries.add(line)

    check entries.len == 4
    
  test "it displays symlinks":
    var
      lines = ll(tmpdir).splitLines()
      entries: seq[string]

    lines = filter(lines, (l) => not l.isSummaryLine)

    entries = @[]
    
    for line in lines:
      if " -> " in line:
         entries.add(line)

    check entries.len == 4
    
  getExampleOutput()
  tearDownSuite()
