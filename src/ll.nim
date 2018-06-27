import algorithm
import future
import memo
import os
import osproc
import parseutils
import posix
import sequtils
import strutils
import tables
import times
import typeinfo

when defined(profiler):
  import nimprof

import llpkg/display


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
    reversed: bool
    vcs: bool
    hasGit: bool

  GitStatus {.pure.} = enum
    Unknown,
    WorkingCopyClean,
    WorkingCopyDirty,
    TrackedDirty,
    TrackedDirtyAdded,
    Untracked,
    Ignored,
    Added,
    Good

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
    parent: string
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
    gitInsideWorkTree: bool
    gitStatus: GitStatus

  ColArray = array[0..9, string]


const
  GitStatusMap = {
    "!!": GitStatus.Ignored,
    " M": GitStatus.TrackedDirty,
    "M ": GitStatus.TrackedDirtyAdded,
    "??": GitStatus.Untracked,
    "A ": GitStatus.Added,
  }.toTable

  GitDisplayMap = {
    GitStatus.WorkingCopyDirty: "+".fgColor(Color.Red),
    GitStatus.WorkingCopyClean: "|".fgColor(Color.Green),
    GitStatus.Good: "|".fgColor(82),
    GitStatus.Ignored: "|".fgColor(241),
    GitStatus.TrackedDirty: "+".fgColor(Color.Red),
    GitStatus.TrackedDirtyAdded: "+".fgColor(82),
    GitStatus.Untracked: "+".fgColor(214),
    GitStatus.Added: "+".fgColor(82),
  }.toTable


let
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


proc gitAvailable(executable="git"): bool =
  let
    output = execProcess(executable & " --version")
  return executable & " version" in output


proc gitTopLevel(path: string): string {.memoized.} =
  return execProcess("cd $# && git rev-parse --show-toplevel".format(path)).strip


proc gitTopLevelStatus(path: string): string {.memoized.} =
  return execProcess(
    "cd $# && git status --porcelain --ignored --untracked-files=normal .".format(path)
  )


proc gitInsideWorkTree(path: string): bool {.memoized.} =
  return execProcess(
    "cd $# && git rev-parse --is-inside-work-tree".format(path)
  ).strip == "true"


proc gitWorkTreeDirty(path: string): bool {.memoized.} =
  return execProcess(
    "git --git-dir=\"$#/.git\" --work-tree=\"$#\" diff --stat --ignore-submodules HEAD".format(
      path,
      path
    )
  ).strip != ""


proc gitStatus(path: string): string =
  var
    (dir, name, ext) = splitFile(path)

  let
    base = gitTopLevel(dir)
    details = gitTopLevelStatus(base).splitLines

  for line in details:
    if line.strip == "":
      continue

    let
      status = line[0..1]
      relpath = line[2..^1].strip
      fullpath = joinPath(base, relpath).strip(leading=false, chars={'/'})

    if not fullpath.startsWith(path):
      continue

    if path == fullpath or path.startsWith(fullpath):
      return status

    if existsDir(path) and fullpath.startsWith(path):
      return status

  return ""


proc gitStatus(entry: Entry): GitStatus =
  if not entry.gitInsideWorkTree:
    return GitStatus.Unknown

  let
    status = gitStatus(entry.path)

  if GitStatusMap.hasKey(status):
    return GitStatusMap[status]

  return GitStatus.Good


proc gitWorkingCopyStatus(entry: Entry): GitStatus =
  if not gitInsideWorkTree(entry.path):
    return

  return if gitWorkTreeDirty(entry.path): GitStatus.WorkingCopyDirty
         else: GitStatus.WorkingCopyClean


proc getFileDetails(path: string, name: string, kind: PathComponent, vsc=true): Entry =
  var
    fullpath = path / name
    entry = Entry()
    info = getFileInfo(fullpath, false)

  entry.name = name
  entry.path = expandFilename(fullpath)
  entry.parent = expandFilename(path)
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

  entry.gitInsideWorkTree = gitInsideWorkTree(path)

  if entry.gitInsideWorkTree:
    entry.gitStatus = gitStatus(entry)
  elif entry.kind == FileType.Dir:
    entry.gitStatus = gitWorkingCopyStatus(entry)

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


proc formatGit(entry: Entry): string =
  if entry.kind == FileType.Dir and entry.name == ".git":
    # special-case: ignore git status for .git directories
    return " "

  if GitDisplayMap.hasKey(entry.gitStatus):
    return GitDisplayMap[entry.gitStatus]

  return " "


proc formatTime(entry: Entry): string =
  let
    ancient = now() - initInterval(months=6)
    localtime = inZone(entry.lastWriteTime, local())
    mtime = localtime.toTime.toUnix.float
    age = int(now - mtime)

  result = if mtime < ancient.toTime.toUnix.float: localtime.format(" MMM  yyyy")
           else: localtime.format(" MMM HH:mm")

  result = align(localtime.format("d"), 3) & result

  result = result.colorizeByAge(age)


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
  result = if fmt == DisplaySize.human: formatSizeReadable(entry.size.int64)
           else: $entry.size

  result = result.colorizeBySize(entry.size.int)


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
  max(map(items, (i) => i[offset].clean.len))


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
      padLeft(item[2], widths[2]),
      # group
      padLeft(item[3], widths[3]),
      # size
      padLeft(item[4], widths[4] + 1),
      # mtime
      align(item[5], widths[5]),
      # git status
      item[6],
      # name
      item[7],
      # arrow
      item[8],
      # symlink
      item[9],
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
      formatGit(entry),
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
    let
      filename = extractFilename(name)
      vcs = displayopts.vcs and displayopts.hasGit

    if displayopts.all == DisplayAll.default and filename[0] == '.':
      continue

    result.add(getFileDetails(path, filename, kind, vcs))

  result = result.sortedByIt(it.name)

  if displayopts.reversed:
    result = result.reversed()


proc ll(path: string,
        all = false, aall = true,
        human = false, reverse = false,
        vcs = true): string =

  var
    optAll =
      if all: DisplayAll.all
      elif aall: DisplayAll.hidden
      else: DisplayAll.default
    optSize =
      if human: DisplaySize.human
      else: DisplaySize.default

  let
    displayOpts = DisplayOpts(
      all: optAll,
      size: optSize,
      reversed: reverse,
      vcs: vcs,
      hasGit: gitAvailable(),
    )
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
    human=args["--human"],
    reverse=args["--reverse"],
    vcs=not args["--no-vcs"],
  )
