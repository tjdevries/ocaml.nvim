local current_path = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h:h")
local add_to_path = function(subdir)
  local entry = vim.fs.joinpath(current_path, "binaries/_build/_private/default/.pkg/", subdir)

  -- Only add them to the path once
  if not vim.env.PATH:find(entry, nil, true) then
    vim.env.PATH = entry .. ":" .. vim.env.PATH
  end
end

add_to_path "ocaml-lsp-server/target/bin"
add_to_path "ocamlmerlin-mlx/target/bin"

-- Formatting
add_to_path "ocamlformat/target/bin"
add_to_path "ocamlformat-mlx/target/bin"

local ok, lspconfig = pcall(require, "lspconfig")
if not ok then
  return
end

local lsp_path = vim.fs.joinpath(
  -- Base Directory
  current_path,
  -- LSP Binary
  "binaries/_build/_private/default/.pkg/ocaml-lsp-server/target/bin/ocamllsp"
)

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

    -- config.cmd = { "dune", "tool", "exec", "ocamllsp" }
    -- config.cmd = { "./_build/_private/default/.pkg/ocaml-lsp-server/target/bin/ocamllsp" }
    -- config.cmd = { "./_build/_private/default/.dev-tool/ocaml-lsp-server/ocaml-lsp-server/target/bin/ocamllsp" }

    -- We should be able to just use this now, since we have this installed via this plugin in the path
    config.cmd = { lsp_path }
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
