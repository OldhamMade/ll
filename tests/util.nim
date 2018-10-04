import re
import sugar


proc isSummaryLine*(line: string): bool =
  return line[0] notin ['l', 'd', '-']


let
  fgDarkGray* = (s: string) => "\e[90m" & s & "\e[0m"
