# ppx_rapper.nvim

Just some utilties for working with ppx_rapper.

If you're not using OCaml (you should be) then this plugin is worthless to you.

## Installation

```vim
Plug 'tjdevries/ppx_rapper.nvim', {'do': ':TSUpdate rapper'}
```

And then, you'll probably need to do this before you load nvim-treesitter
(if you want to use `ensure_installed`)

```lua
requre('ppx_rapper').setup()
```

You can customize the colors by doing something like:

```vim
hi! link @rapper_argument @parameter
hi! link @rapper_return @type
```

## Features

Mostly just syntax highlighting for sql inside of `ppx_rapper`
