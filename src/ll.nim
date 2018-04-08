import os
import strutils
import tables


const
  Usage = staticRead("usage.txt")
  AppName = "ll"
  AppVersion = "0.1.0"
  AppVersionFull = "$1, version $2".format(AppName, AppVersion)


type
  Entry = object
    name: string


proc getFileList(path: string): seq[Entry] =
  var
    entries: seq[Entry]

  entries = @[]
  
  for kind, path in walkDir(path, relative=true):
    var entry = Entry()
    entry.name = path
    entries.add(entry)

  return entries

  
proc ll(path: string,
         all = false, aall = true,
         dirs = true, no_dirs = false,
         human = false, si = false,
         no_vcs = true): string =

  let entries = getFileList(path)
  
  var output = ""
  for entry in entries:
    output = output & entry.name & "\n"

  return output


proc getTargetPath(path: string): string =
  var path = path
  
  case path
  of "":
    path = getCurrentDir()
  of ".":
    path = getCurrentDir()
  of "..":
    path = getCurrentDir() / ".."
  of "~":
    path = getHomeDir()
  else:
    if not isAbsolute(path):
      path = getCurrentDir() / path

  return path


when isMainModule:
  import docopt

  let args = docopt(Usage, version=AppVersionFull)

  var target_path = if not args["<path>"]: ""
                    else: $args["<path>"]
  
  target_path = getTargetPath(target_path)
  
  echo ll(
    path=target_path,
    all=args["--all"],
    aall=args["--almost-all"],
    dirs=args["--directory"],
    no_dirs=args["--no-directory"],
    human=args["--human"],
    si=args["--si"],
    no_vcs=args["--no-vcs"]
  )
