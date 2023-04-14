# ocaml.nvim

Tools for working with OCaml.
Status is very work in progress and likely to break.
Use at your own risk.

Just some utilties for working with ppx_rapper.

If you're not using OCaml (you should be) then this plugin is worthless to you.

## Installation

```vim
Plug 'tjdevries/ocaml.nvim', {'do': ':lua require("ocaml").update()'}
```

And then, you'll probably need to do this before you load nvim-treesitter
(if you want to use `ensure_installed`, but I do my best to make this not required)

```lua
requre('ocaml').setup()
```

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
