# `ll` - a more informative `ls`, based on [`k`][1]

[![Waffle.io - Columns and their card count](https://badge.waffle.io/03e04bd3c5dd71dd392210b4479adccc.svg?columns=all)](https://waffle.io/OldhamMade/ll)


## Description

`ll` is an alternative to [`k`][1], which was created to make directory listings more informative 
and readable, using colour to add visual weight to important information in the listing.

[`k`][1] only works with [`zsh`][2], and I've found that it can occasionally be a little slow
when working with large directories or with large git repositories. I've been looking for a project
in which to use [`nim`][3] for a while now, and this seemed like a great opportunity to make 
something a little more general-purpose that could be used without the `zsh` dependency.

## Features

### [ ] Full file listing

Calling `ll` provides a full file listing for a directory, similar to calling `ls -l`.

### [ ] File weight colours

Files sizes are graded from green for small (< 1k), to red for huge (> 1mb).

Human readable files sizes can be shown by using the `-h` flag, and using `-H` will display
file sizes using a power of 1000 instead of 1024.

### [ ] "Rotting" dates

Dates fade with age, so that recently changed files/directories can be easily identified.

### Git integration

#### [ ] Git status on entire repos

#### [ ] Git status on files within a working tree

## Usage

    ll
    
That's it. For more options, pass `--help`.

## Development

`ll` is developed using Github issues and [Kanban][4] (via [Waffle][5]). If you would like to
request a feature or report a bug, please add a new issue [here](https://github.com/OldhamMade/ll/issues)
and we'll do our best to address them. 

Contributions and pull-requests are always welcome, as is constructive feedback around 
code structure, hints, tips, etc. 


[1]: https://github.com/supercrabtree/k
[2]: https://en.wikipedia.org/wiki/Z_shell
[3]: https://nim-lang.org
[4]: https://en.wikipedia.org/wiki/Kanban
[5]: https://waffle.io
