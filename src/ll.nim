import algorithm
import future
import os
import posix
import strutils
import tables
import times
import typeinfo


const
  Usage = staticRead("usage.txt")
  AppName = "ll"
  AppVersion = "0.1.0"
  AppVersionFull = "$1, version $2".format(AppName, AppVersion)


type
  Entry = ref object
    name: string
    path: string
    id: tuple[device: DeviceId, file: FileId]
    kind: PathComponent
    size: BiggestInt
    permissions: set[FilePermission]
    linkCount: BiggestInt
    lastAccessTime: times.Time
    lastWriteTime: times.Time
    creationTime: times.Time
    blocks: int
    owner: tuple[group: Gid, user: Uid]
    symlink: string
    hidden: bool


proc getLongestValue(key: string, items: seq[Entry]): uint32 =
  var
    values: seq[int]

  values = @[]

  for item in items:
    for k, v in item[].fieldPairs:
      if k == key:
        let s = $v
        values.add(s.len)

  return max(values).uint32


proc getFileDetails(path: string, name: string, kind: PathComponent): Entry =
  var
    fullpath = path / name
    entry = Entry()
    info = getFileInfo(fullpath, false)
    
  entry.name = name
  entry.path = expandFilename(fullpath)
  entry.hidden = false
  
  if entry.name[0] == '.':
    entry.hidden = true

  entry.id = info.id
  entry.kind = kind
  entry.size = info.size
  entry.permissions = info.permissions
  entry.linkCount = info.linkCount
  entry.lastAccessTime = info.lastAccessTime
  entry.lastWriteTime = info.lastWriteTime
  entry.creationTime = info.creationTime

  if symlinkExists(fullpath):
    entry.symlink = expandSymlink(fullpath)

  var stat: Stat
  if lstat(fullpath, stat) < 0:
    raiseOSError(osLastError())

  entry.owner = (group: stat.st_gid, user: stat.st_uid)
  entry.blocks = stat.st_blocks

  return entry


proc formatKind(entry: Entry): string =
  case entry.kind
  of PathComponent.pcLinkToDir:
    return "l"
  of PathComponent.pcLinkToFile:
    return "l"
  of PathComponent.pcDir:
    return "d"
  else:
    return "-"


proc formatPermissions(entry: Entry): string =
  let
    tests = @[
      (perm: FilePermission.fpUserRead, val: "r"),
      (perm: FilePermission.fpUserWrite, val: "w"),
      (perm: FilePermission.fpUserExec, val: "x"),
      (perm: FilePermission.fpGroupRead, val: "r"),
      (perm: FilePermission.fpGroupWrite, val: "w"),
      (perm: FilePermission.fpGroupExec, val: "x"),
      (perm: FilePermission.fpOthersRead, val: "r"),
      (perm: FilePermission.fpOthersWrite, val: "w"),
      (perm: FilePermission.fpOthersExec, val: "x"),
    ]
    
  var
    permissions: seq[string]

  permissions = @[]

  for test in tests:
    if test.perm in entry.permissions:
      permissions.add(test.val)
    else:
      permissions.add("-")
    
  return permissions.join


proc formatLinks(entry: Entry, max: uint32): string =
  return align($entry.linkCount, max + 1)


proc formatOwner(entry: Entry): string =
  var
    output: seq[string]
    user = getpwuid(entry.owner.user)
    group = getgrgid(entry.owner.group)

  output = @[]
  output.add($user.pw_name)
  output.add($group.gr_name)
  
  return output.join(" ")


proc formatTime(entry: Entry): string =
  var
    localtime = inZone(entry.lastWriteTime, local())
  return align(localtime.format("d"), 3) & localtime.format(" MMM HH:mm ")


proc formatSize(entry: Entry, max: uint32): string =
  return align($entry.size, max + 1)


proc formatName(entry: Entry): string =
  return entry.name


proc formatSymlink(entry: Entry): string =
  if entry.symlink != nil:
    return "-> " & entry.symlink

  return ""


proc formatSummary(entries: seq[Entry]): string =
  var
    blocks = 0

  for entry in entries:
    blocks += entry.blocks

  return "total $#".format(blocks)


proc formatEntries(entries: seq[Entry]): string =
  var
    output: seq[string]
    parts: seq[string]

  output = @[]

  output.add(formatSummary(entries))
    
  for entry in entries:
    parts = @[]

    parts.add(formatKind(entry) & formatPermissions(entry))
    parts.add(formatLinks(entry, getLongestValue("linkCount", entries)))
    parts.add(formatOwner(entry))
    parts.add(formatSize(entry, getLongestValue("size", entries)))
    parts.add(formatTime(entry))
    parts.add(formatName(entry))
    parts.add(formatSymlink(entry))
    
    output.add(parts.join(" ").strip)

  return output.join("\n")


proc getFileList(path: string): seq[Entry] =
  var
    entries: seq[Entry]

  entries = @[]
  
  for kind, name in walkDir(path, relative=true):
    entries.add(getFileDetails(path, name, kind))

  return entries.sortedByIt(it.name)


proc ll(path: string,
        all = false, aall = true,
        dirs = true, no_dirs = false,
        human = false, si = false,
        no_vcs = true): string =

  let
    entries = getFileList(path)
    output = formatEntries(entries)
  
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
