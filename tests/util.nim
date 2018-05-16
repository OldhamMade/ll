import future
import re


proc clean*(s: string): string =
  s.replace(re"\x1B\[([0-9]{1,2}(;[0-9]+)*)?[mGK]", "")


proc isSummaryLine*(line: string): bool =
  return line[0] notin ['l', 'd', '-']


let
  fgDarkGray* = (s: string) => "\e[90m" & s & "\e[0m"
