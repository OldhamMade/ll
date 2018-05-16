import future

type
  Color {.pure.} = enum
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


proc colByAge*(s: string, age: int): string {.procvar.} =
  for boundary, color in items(ages):
    if age.int < boundary:
      return s.fgColor(color)

  s.fgColor(agesDefault)
