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

import colors


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

  FileType {.pure.} = enum
    Block,
    Char,
    Dir,
    Pipe,
    File,
    Link,
    Socket

  Entry = object
    name: string
    path: string
    id: tuple[device: DeviceId, file: FileId]
    kind: FileType
    size: BiggestInt
    permissions: set[FilePermission]
    linkCount: BiggestInt
    lastAccessTime: times.Time
    lastWriteTime: times.Time
    creationTime: times.Time
    blocks: int
    owner: tuple[group: Gid, user: Uid]
    symlink: string
    executable: bool
    mode: Mode
    hidden: bool

  ColArray = array[0..8, string]


var
  now = epochTime()


proc isExecutable(perms: set[FilePermission]): bool =
  {FilePermission.fpUserExec, FilePermission.fpGroupExec, FilePermission.fpOthersExec} - perms == {}


proc isWritableByOthers(perms: set[FilePermission]): bool =
  {FilePermission.fpUserWrite, FilePermission.fpGroupWrite, FilePermission.fpOthersWrite} - perms == {}


proc isGID(mode: Mode): bool =
  return (mode and S_ISGID) > 0


proc isUID(mode: Mode): bool =
  return (mode and S_ISUID) > 0


proc hasStickyBit(mode: Mode): bool =
  return (mode and S_ISVTX) > 0


proc getKind(mode: Mode): FileType =
  if S_ISDIR(mode):
    return FileType.Dir

  if S_ISBLK(mode):
    return FileType.Block

  if S_ISCHR(mode):
    return FileType.Char

  if S_ISFIFO(mode):
    return FileType.Pipe

  if S_ISREG(mode):
    return FileType.File

  if S_ISLNK(mode):
    return FileType.Link

  if S_ISSOCK(mode):
    return FileType.Socket


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

  entry.kind = getKind(stat.st_mode)
  entry.owner = (group: stat.st_gid, user: stat.st_uid)
  entry.blocks = stat.st_blocks
  entry.mode = stat.st_mode

  entry.executable = isExecutable(info.permissions)

  return entry


proc formatKind(entry: Entry): string =
  if entry.kind == FileType.File:
    return "-"

  result = $entry.kind
  result = result[0..0].toLowerAscii


proc formatPermissions(entry: Entry): string =
  let
    tests = [
      (perm: FilePermission.fpUserRead, val: 'r'),
      (perm: FilePermission.fpUserWrite, val: 'w'),
      (perm: FilePermission.fpUserExec, val: 'x'),
      (perm: FilePermission.fpGroupRead, val: 'r'),
      (perm: FilePermission.fpGroupWrite, val: 'w'),
      (perm: FilePermission.fpGroupExec, val: 'x'),
      (perm: FilePermission.fpOthersRead, val: 'r'),
      (perm: FilePermission.fpOthersWrite, val: 'w'),
      (perm: FilePermission.fpOthersExec, val: 'x'),
    ]

  var
    permissions: array[tests.len, char]

  for i, test in tests:
    if test.perm in entry.permissions:
      permissions[i] = test.val
    else:
      permissions[i] = '-'

  if isUID(entry.mode):
    permissions[2] = 'S'

  if isGID(entry.mode):
    permissions[5] = 'S'

  if FilePermission.fpOthersExec in entry.permissions and hasStickyBit(entry.mode):
    permissions[8] = 't'

  return permissions.join


proc formatLinks(entry: Entry): string =
  $entry.linkCount


proc formatUser(entry: Entry): string =
  result = $getpwuid(entry.owner.user).pw_name
  result = result.colOwner


proc formatGroup(entry: Entry): string =
  result = $getgrgid(entry.owner.group).gr_name
  result = result.colOwner


proc formatTime(entry: Entry): string =
  let
    ancient = now() - initInterval(months=6)
    localtime = inZone(entry.lastWriteTime, local())
    mtime = localtime.toTime.toUnix.float
    age = int(now - mtime)

  result = if mtime < ancient.toTime.toUnix.float: localtime.format(" MMM  yyyy ")
           else: localtime.format(" MMM HH:mm ")

  result = align(localtime.format("d"), 3) & result  

  result = result.colByAge(age)


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
  if entry.kind == FileType.Dir:
    if isWritableByOthers(entry.permissions):
      if hasStickyBit(entry.mode):
        return entry.name.colDirectoryWritableStickyBit
      return entry.name.colDirectoryWritable
    return entry.name.colDirectory

  if entry.kind == FileType.Block:
    return entry.name.colBlockSpecial

  if entry.kind == FileType.Char:
    return entry.name.colCharSpecial

  if entry.kind == FileType.Pipe:
    return entry.name.colPipe

  if entry.kind == FileType.Socket:
    return entry.name.colSocket

  if entry.symlink != nil and existsDir(entry.symlink):
    return entry.name.colDirectory

  if entry.symlink != nil:
    return entry.name.colSymlink

  if entry.executable:
    return entry.name.colExecutable

  return entry.name


proc formatArrow(entry: Entry): string =
  return if entry.symlink != nil: "->"
         else: ""


proc formatSymlink(entry: Entry): string =
  return if entry.symlink != nil: entry.symlink
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
      # arrow
      item[7],
      # symlink
      item[8],
    ].join(" ").strip)

  lines.join("\n")


proc formatAttributes(entries: seq[Entry], displayopts: DisplayOpts): seq[ColArray] =
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
      formatArrow(entry),
      formatSymlink(entry),
    ])


proc getFileList(path: string, displayopts: DisplayOpts): seq[Entry] =
  result = @[]

  if displayopts.all == DisplayAll.all:
    result.add(getFileDetails(path, ".", PathComponent.pcDir))
    result.add(getFileDetails(path, "..", PathComponent.pcDir))

  for kind, name in walkDir(path):
    let filename = extractFilename(name)
    if displayopts.all == DisplayAll.default and filename[0] == '.':
      continue
    result.add(getFileDetails(path, filename, kind))

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
  of "~":
    path = getHomeDir()
  else:
    if not isAbsolute(path):
      path = getCurrentDir() / path

  return expandFilename(path)


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
