# `ll` - a more informative `ls`, based on [`k`][k]

![CI](https://github.com/OldhamMade/ll/workflows/CI/badge.svg)


## Description

`ll` is an alternative to [`k`][k], which was created to make
directory listings more informative and readable, using colour to add
visual weight to important information in the listing.

### Motivation

[`k`][k] only works with [`zsh`][zsh], and I've found that it can
occasionally be a little slow when working with large directories or
with large git repositories. I was looking for a project which would
be a good match to learn/use [`nim`][nim], and this seemed like a great
opportunity to make something a little more general-purpose that could
be used without the [`zsh`][zsh] dependency.

## Features

### Full file listing

Calling `ll` provides a full file listing for a directory, similar to calling
`ls -l`.

### File weight colours

Files sizes are graded from green for small (< 1k), to red for huge (> 1mb).

Human readable files sizes can be shown by using the `-h` or `--human` flag.

### "Rotting" dates

Dates fade with age, so that recently changed files/directories can be
easily identified.

### Broken Symlinks

Broken symlinks are identified by a `~>` (tilde-arrow) leading symbol
and differing colors.

### Git integration

`ll` provides easy-to-understand information about the `git` status of
your files/directories.

#### Git status on entire repos

When listing a directory which contains git repos, `ll` displays the
active state of those repos:

![Image demonstrating repository listing](.images/repos.png)

#### Git status on files within a working tree

When listing files/directories within a working tree, `ll` displays
the active state of each file, and the overall state for directories:

![Image demonstrating file listing](.images/status.png)

### Speed

`ll` improves on `k`'s rendering speeds. Currently `ll` is comparable
to `ls` display times when using the `--no-vcs` flag. Listing git
repositories and trees take a little longer, but even with large
listings with many git-tracked entries `ll` is still sub-second.

## Installation

[The latest binary distribution is avilable here.][builds]

It is also possible to build and install using the following
instructions:

### Requirements

- [Nim][nim], minimum v1.2.*
- `make`

### Steps

Firstly install [Nim][nim]. I personally use [`asdf`][asdf] to manage Nim
versions on my machine. With `asdf` installed, this is as simple as
calling `asdf install nim latest`.

Once Nim is installed, clone this repository. From within the cloned
directory, call `make install` which will build `ll` into the working
directory and will then opy the resulting `ll` binary to `/usr/local/bin`.

## Usage

    $ ll

That's it. For more options, pass `-?` or `--help`.

## Status

- [x] Full file listing
- [x] File weight colours
- [x] "Rotting" dates
- [x] Display symlink status
- [x] Git status on entire repos
- [x] Git status on files within a working tree
- [x] Sort output by size
- [x] Sort output by modified time
- [x] Sort output in reversed order
- [x] Options for filtering directories
- [x] Remove dependency on PCRE (using the `regex` package)
- [ ] Installable via Homebrew
- [ ] Support light themes
- [ ] Support globs

### Fixes over [`k`][k]

* [`k`][k] has an odd behaviour; given `pwd` is a git-tracked
directory, if you `k somedir` where `somedir` contains git-tracked
directories but isn't itself tracked, `k` reports as though it is
working inside a work-tree. `ll` reports this as one would expect, as
though `pwd` is `somedir`. **UPDATE:** This has now
[been fixed](https://github.com/supercrabtree/k/issues/47).

### Future plans

According to the [`k`][k] source, there are future plans to colorise
file permissions. If this happens, I plan to bring those changes
over. If any other enhancements are added, I hope to port those also.

I'd like to display some additional information in the summary line of
the listing; I'm currently reviewing what would be most useful.

## Contributing

Contributions and pull-requests are always welcome, as is constructive
feedback around code structure, hints, tips, etc.

If you would like to request a feature or report a bug, please add a
new issue [here](https://github.com/OldhamMade/ll/issues) and we'll do
our best to address them. Please note that this is not a funded
project and fixes will be addressed on a best-effort basis.

To contribute directly:

1.  Fork it (https://github.com/OldhamMade/ll/fork)
2.  Create your feature branch (`git checkout -b my-new-feature`)
3.  Commit your changes (`git commit -am 'Add some feature'`)
4.  Push to the branch (`git push origin my-new-feature`)
5.  Create a new pull request

## Liability

We take no responsibility for the use of this tool, or external
instances provided by third parties. We strongly recommend you abide
by the valid official regulations in your country. Furthermore, we
refuse liability for any inappropriate or malicious use of this
tool. This tool is provided to you in the spirit of free, open
software.

You may view the LICENSE in which this software is provided to you
[here](./LICENSE).

> IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
> CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
> TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
> SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


[k]: https://github.com/supercrabtree/k
[zsh]: https://en.wikipedia.org/wiki/Z_shell
[nim]: https://nim-lang.org
[asdf]: https://github.com/asdf-vm/asdf
[builds]: https://github.com/OldhamMade/ll/releases/latest
