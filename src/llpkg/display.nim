import re
import strutils
import sugar

type
  Color* {.pure.} = enum
    Black,
    Red,
    Green,
    Yellow,
    Blue,
    Magenta,
    Cyan,
    LightGrey,
    DarkGrey,
    LightRed,
    LightGreen,
    LightYellow,
    LightBlue,
    LightMagenta,
    LightCyan,
    White


const
  ages* = [
    # age, color
    (0, 196),         # somehow in the future
    (60, 255),        # less than 1 min old
    (3600, 252),      # less than 1 hour old
    (86400, 250),     # less than 1 day old
    (604800, 244),    # less than 1 week old
    (2419200, 244),   # less than 28 days (4 weeks) old
    (15724800, 242),  # less than 26 weeks (6 months) old
    (31449600, 240),  # less than 1 year old
    (62899200, 238),  # less than 2 years old
  ]
  agesDefault* = 236  # more than 2 years old
  sizes* = [
    # size, color
    (1024, 47),       # <= 1kb
    (2048, 82),       # <= 2kb
    (3072, 118),      # <= 3kb
    (5120, 154),      # <= 5kb
    (10240, 190),     # <= 10kb
    (20480, 226),     # <= 20kb
    (40960, 220),     # <= 40kb
    (102400, 214),    # <= 100kb
    (262144, 208),    # <= 0.25mb || 256kb
    (524288, 202),    # <= 0.5mb || 512kb
  ]
  sizesDefault* = 196


let
  ColorCode = re"\x1B\[([0-9]{1,2}(;[0-9]+)*)?[mGK]"

  
proc reset(): string {.procvar.} =
  "\e[0m"

proc fgColor*(s: string, c: int): string {.procvar.} =
  "\e[38;5;" & $c & "m" & s & reset()

proc fgColor*(s: string, c: Color): string {.procvar.} =
  s.fgColor(ord(c))

proc bgColor*(s: string, c: int): string {.procvar.} =
  "\e[48;5;" & $c & "m" & s & reset()

proc bgColor*(s: string, c: Color): string {.procvar.} =
  s.bgColor(ord(c))


# Colour mapping
let
  colDirectory* = (s: string) => s.fgColor(Color.Blue)
  colSymlink* = (s: string) => s.fgColor(Color.Magenta)
  colExecutable* = (s: string) => s.fgColor(Color.Red)
  colSocket* = (s: string) => s.fgColor(Color.Green)
  colPipe* = (s: string) => s.fgColor(Color.Yellow)
  colBlockSpecial* = (s: string) => s.fgColor(Color.Blue).bgColor(Color.Cyan)
  colCharSpecial* = (s: string) => s.fgColor(Color.Blue).bgColor(Color.Yellow)
  colExecutableSetuid* = (s: string) => s.fgColor(Color.Black).bgColor(Color.Cyan)
  colExecutableSetguid* = (s: string) => s.fgColor(Color.Black).bgColor(Color.Red)
  colDirectoryWritableStickyBit* = (s: string) => s.fgColor(Color.Black).bgColor(Color.Green)
  colDirectoryWritable* = (s: string) => s.fgColor(Color.Black).bgColor(Color.Yellow)
  colOwner* = (s: string) => s.fgColor(241)


proc colorizeByAge*(s: string, age: int): string {.procvar.} =
  for boundary, color in items(ages):
    if age.int < boundary:
      return s.fgColor(color)

  s.fgColor(agesDefault)


proc colorizeBySize*(s: string, size: int): string {.procvar.} =
  for boundary, color in items(sizes):
    if size.int <= boundary:
      return s.fgColor(color)

  s.fgColor(sizesDefault)


proc clean*(s: string): string =
  s.replace(ColorCode, "")


proc padLeft*(s: string, l=0, c=' '): string =
  ## add `l` instances of `c`
  ## to the left side of string `s`
  let
    markers = s.findAll(ColorCode)
  join([markers[0], align(s.clean(), l, c), markers[1]])


proc padRight*(s: string, l=0, c=' '): string =
  ## add `l` instances of `c`
  ## to the right side of string `s`
  let
    markers = s.findAll(ColorCode)
  join([markers[0], alignLeft(s.clean(), l, c), markers[1]])


