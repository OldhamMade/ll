import future
import re


proc isSummaryLine*(line: string): bool =
  return line[0] notin ['l', 'd', '-']


let
  fgDarkGray* = (s: string) => "\e[90m" & s & "\e[0m"
