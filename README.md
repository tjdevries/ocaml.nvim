# ocaml.nvim

This plugin requires the new dune:

- Get it here: https://preview.dune.build/
- Or shortcut: `curl -fsSL https://get.dune.build/install | sh`

You also need to run `make` for the plugin on installation

# New Filetypes

```
.ml -> ocaml
.mli -> ocaml.interface
.mll -> ocaml.ocamllex
.mly -> ocaml.menhir
.t -> ocaml.cram
```

## Overview

Tools for working with OCaml.
Status is very work in progress and likely to break.
Use at your own risk (but feel free to file issues)

Just some utilties for working with ppx_rapper.

If you're not using OCaml (you should be) then this plugin is worthless to you.

## Installation

```lua
return {
    {
        "tjdevries/ocaml.nvim",
        dependencies = {
            "stevearc/conform.nvim",
        },
        build = "make"
    },
}
```

```lua
require('ocaml').setup()
```

# Features

- Configures nvim lsp
- Configures mlx
- Configures conform

## Feature: Highlighting


- Automatically highlight code from `ppx_wraper`:

```ocaml
let create_query =
  [%rapper
    get_one
      {|
      INSERT INTO resources (name)
      VALUES (%string{name})
      RETURNING @int{id}
    |}]
;;
```

You can customize the colors by doing something like:

```vim
hi! link @rapper_argument @parameter
hi! link @rapper_return @type
```

- Automatically highlight code from `%graphql`:

```ocaml
module SomeGraphql = [%graphql
  {| mutation deposit($account: String, $amount: UInt64) {
    changeBalance(account: $account) {
      payment {
        id
      }
    }
  } |}
];
```

You just need to have `graphql` grammar installed.

## Feature: Easily update types in `.ml`/`.mli` files

You can map a function to easily update the corresponding type in your `.ml` or `.mli` files, by doing:

```lua
-- Use <leader>out to update the type
vim.keymap.set("n", "<leader>out", require('ocaml.actions').update_interface_type, { desc = "[O]caml [U]pdate [T]ype" })
```
