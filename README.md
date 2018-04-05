# `ll` - a better `ls`, based on [`k`][1]

[![Waffle.io - Columns and their card count](https://badge.waffle.io/03e04bd3c5dd71dd392210b4479adccc.svg?columns=all)](https://waffle.io/OldhamMade/ll)


## Description

`ll` is an alternative to [`k`][1], which was created to make directory listings more readable, 
using colour to add more visual weight to the more important items in the listing.

[`k`][1] only works with [`zsh`][2], and I've found that it can be occasionally a little slow
when working with large directories or with large git repositories. I wanted to learn [`nim`][3] 
so I decided to make something a little more general-purpose that could be used without `zsh`.

## Features

### File weight colours

Files sizes are graded from green for small (< 1k), to red for huge (> 1mb).

Human readable files sizes can be shown by using the `-h` flag, and using `-H` will display
file sizes using a power of 1000 instead of 1024.

### "Rotting" dates

Dates fade with age, so that recently changed files/directories can be easily identified.

### Git integration

#### Git status on entire repos

#### Git status on files within a working tree

## Usage

    ll
    
That's it. For more options, pass `--help`.

## Development

`ll` is developed using Github issues and [Kanban][4] (via [Waffle][5]). If there are
any features you would like to see, please add a new issue [here](https://github.com/OldhamMade/ll/issues)
and we'll do our best to add them. 

Contributions and pull-requests are always welcome, as is constructive feedback around 
code structure, hints, tips, etc. 


[1]: https://github.com/supercrabtree/k
[2]: https://en.wikipedia.org/wiki/Z_shell
[3]: https://nim-lang.org
[4]: https://en.wikipedia.org/wiki/Kanban
[5]: https://waffle.io
