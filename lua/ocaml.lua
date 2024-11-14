---@diagnostic disable: missing-fields

if not pcall(require, "nvim-treesitter") then
  vim.notify "[ocaml.nvim] you must install nvim-treesitter"

  return {
    setup = function() end,
    update = function()
      vim.notify "[ocaml.nvim] you must install nvim-treesitter"
    end,
  }
end

local parsers = require "nvim-treesitter.parsers"
local list = parsers.get_parser_configs and parsers.get_parser_configs() or parsers

local install_rapper = function()
  list.rapper = {
    install_info = {
      url = "https://github.com/tjdevries/tree-sitter-rapper",
      revision = "99832d42ff758589050c707aea6d6db965240f86",
      files = { "src/parser.c" },
      branch = "main",
    },
    maintainers = { "@derekstride" },
  }

  vim.cmd.TSUpdate "rapper"
end

local install_mlx = function()
  list.ocaml_mlx = {
    tier = 0,

    install_info = {
      location = "grammars/mlx",
      url = "https://github.com/ocaml-mlx/tree-sitter-mlx",
      files = { "src/parser.c", "src/scanner.c" },
      branch = "master",
    },
    filetype = "ocaml_mlx",
  }
end

-- Adds rapper parser to the list of parsers

---@class ocaml.SetupOptions
---@field install_rapper boolean
---@field install_mlx boolean
---@field setup_lspconfig boolean
---@field setup_conform boolean

--- Setup OCaml.nvim
---@param opts ocaml.SetupOptions
local setup = function(opts)
  opts = opts or {}
  opts = vim.tbl_deep_extend("keep", opts, {
    install_rapper = false,
    install_mlx = true,
    setup_lspconfig = true,
    setup_conform = true,
  })

  if opts.install_rapper then
    install_rapper()
  end

  if opts.install_mlx then
    install_mlx()
  end

  if opts.setup_lspconfig then
    local lspconfig = require "lspconfig"
    lspconfig.util.on_setup = lspconfig.util.add_hook_before(lspconfig.util.on_setup, function(config)
      if config.name == "ocamllsp" then
        local filetypes = vim.deepcopy(config.filetypes)
        local get_language_id = config.get_language_id

        local ensure_filetypes = {
          "ocaml",
          "ocaml.interface",
          "ocaml.menhir",
          "ocaml.cram",
          "ocaml.mlx",
          "ocaml.ocamllex",
          "reason",
        }

        for _, ft in ipairs(ensure_filetypes) do
          if not vim.tbl_contains(filetypes, ft) then
            table.insert(filetypes, ft)
          end
        end

        config.cmd = { "dune", "exec", "ocamllsp" }
        config.filetypes = filetypes
        config.get_language_id = function(bufnr, ft)
          if ft == "ocaml.mlx" then
            return "ocaml"
          else
            return get_language_id(bufnr, ft)
          end
        end
      end
    end)
  end

  if opts.setup_conform then
    local conform = require "conform"
    conform.formatters_by_ft.mlx = { "stylua" }
    conform.formatters.ocamlformat_mlx = {
      inherit = false,
      command = "ocamlformat-mlx",
      args = { "--name", "$FILENAME", "--impl", "-" },
      stdin = true,
    }
  end
end

return {
  setup = setup,
  update = function()
    local update = require("nvim-treesitter.install").update {}
    update("ocaml", "ocaml_interface", "rapper")
  end,
}
