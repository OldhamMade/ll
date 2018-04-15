import algorithm
import future
import os
import parseutils
import posix
import sequtils
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
  DisplayAll {.pure.} = enum
    all,
    hidden,
    default

  DisplaySize {.pure.} = enum
    human,
    default

  DisplayOpts = object
    all: DisplayAll
    size: DisplaySize
    vcs: bool

  Entry = object
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

  ColArray = array[0..7, string]


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
    tests = [
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


proc formatLinks(entry: Entry): string =
  $entry.linkCount


proc formatUser(entry: Entry): string =
  $getpwuid(entry.owner.user).pw_name


proc formatGroup(entry: Entry): string =
  $getgrgid(entry.owner.group).gr_name


proc formatTime(entry: Entry): string =
  var
    localtime = inZone(entry.lastWriteTime, local())
  return align(localtime.format("d"), 3) & localtime.format(" MMM HH:mm ")


proc formatSizeReadable(size: int64): string =
  var
    formatted = formatSize(size, includeSpace=true).split
    num = formatted[0]
    suffix = formatted[1][0].toUpperAscii
    parsed: float

  discard parseFloat(num, parsed)

  result = if parsed < 10.0: parsed.formatFloat(ffDecimal, 1)
           else: parsed.formatFloat(ffDecimal, 0, decimalSep=' ').strip

  if suffix != 'K':
    result.removeSuffix(".0")

  if suffix == 'B':
    result &= ""
  else:
    result &= $suffix


proc formatSize(entry: Entry, fmt: DisplaySize): string =
  return if fmt == DisplaySize.human: formatSizeReadable(entry.size.int64)
         else: $entry.size


proc formatName(entry: Entry): string =
  entry.name


proc formatSymlink(entry: Entry): string =
  return if entry.symlink != nil: "-> " & entry.symlink
         else: ""


proc formatSummary(entries: seq[Entry]): string =
  var
    blocks = 0

  for entry in entries:
    blocks += entry.blocks

  "total $#".format(blocks)


proc getWidth(items: seq[ColArray], offset = 0): int =
  max(map(items, (i) => i[offset].len))


proc getWidths(items: seq[ColArray]): seq[int] =
  result = @[]
  for i in 0..<items[0].len:
    result.add(getWidth(items, i))


proc tabulate(items: seq[ColArray]): string =
  var
    lines: seq[string]
    widths = getWidths(items)

  lines = @[]

  for item in items:
    lines.add([
      # permissions
      item[0],

      # linkCount
      align(item[1], widths[1] + 1),

      # user
      alignLeft(item[2], widths[2]),

      # group
      alignLeft(item[3], widths[3]),

      # size
      align(item[4], widths[4] + 1),

      # mtime
      align(item[5], widths[5]),

      # name
      item[6],

      # symlink
      item[7]
    ].join(" "))

  lines.join("\n")


proc formatAttributes(entries: seq[Entry], displayopts: DisplayOpts): seq[ColArray] =
  var
    attrs: ColArray

  result = @[]

  for entry in entries:
    result.add([
      formatKind(entry) & formatPermissions(entry),
      formatLinks(entry),
      formatUser(entry),
      formatGroup(entry),
      formatSize(entry, displayopts.size),
      formatTime(entry),
      formatName(entry),
      formatSymlink(entry),
    ])


proc getFileList(path: string, displayopts: DisplayOpts): seq[Entry] =
  result = @[]

  if displayopts.all == DisplayAll.all:
    result.add(getFileDetails(path, ".", PathComponent.pcDir))
    result.add(getFileDetails(path, "..", PathComponent.pcDir))

  for kind, name in walkDir(path, relative=true):
    if displayopts.all == DisplayAll.default and name[0] == '.':
      continue
    result.add(getFileDetails(path, name, kind))

  return result.sortedByIt(it.name)


proc ll(path: string,
        all = false, aall = true,
        dirs = true, no_dirs = false,
        human = false, vcs = true): string =

  var
    optAll =
      if all: DisplayAll.all
      elif aall: DisplayAll.hidden
      else: DisplayAll.default
    optSize =
      if human: DisplaySize.human
      else: DisplaySize.default

  let
    displayOpts = DisplayOpts(all: optAll, size: optSize, vcs: vcs)
    entries = getFileList(path, displayOpts)
    formatted = formatAttributes(entries, displayOpts)

  result = formatSummary(entries) & "\n"
  result &= tabulate(formatted)


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

  var
    target_path =
      if not args["<path>"]: ""
      else: $args["<path>"]

  target_path = getTargetPath(target_path)

  echo ll(
    path=target_path,
    all=args["--all"],
    aall=args["--almost-all"],
    dirs=args["--directory"],
    no_dirs=args["--no-directory"],
    human=args["--human"],
    vcs=not args["--no-vcs"]
  )
