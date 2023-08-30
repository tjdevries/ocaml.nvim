-- Register `.mli` files as ocaml interface files
vim.filetype.add {
  extension = {
    mli = "ocaml.interface",
    mly = "ocaml.menhir",
  },
}

-- If you have `ocaml_interface` parser installed, it will use it for `ocaml.interface` files
vim.treesitter.language.register("ocaml_interface", "ocaml.interface")
vim.treesitter.language.register("menhir", "ocaml.menhir")
