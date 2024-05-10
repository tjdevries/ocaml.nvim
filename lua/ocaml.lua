if not pcall(require, "nvim-treesitter") then
  vim.notify "[ocaml.nvim] you must install nvim-treesitter"

  return {
    setup = function() end,
    update = function()
      vim.notify "[ocaml.nvim] you must install nvim-treesitter"
    end,
  }
end

-- Adds rapper parser to the list of parsers
local list = require("nvim-treesitter.parsers").get_parser_configs()
list.rapper = {
  install_info = {
    url = "https://github.com/tjdevries/tree-sitter-rapper",
    revision = "99832d42ff758589050c707aea6d6db965240f86",
    files = { "src/parser.c" },
    branch = "main",
  },
  maintainers = { "@derekstride" },
}

local function is_installed(lang)
  local matched_parsers = vim.api.nvim_get_runtime_file("parser/" .. lang .. ".so", true) or {}
  return matched_parsers[1] ~= nil
end

return {
  setup = function()
    vim.api.nvim_set_hl(0, "@rapper_argument", { link = "@parameter", default = true })
    vim.api.nvim_set_hl(0, "@rapper_return", { link = "@type", default = true })
  end,

  update = function()
    local update = require("nvim-treesitter.install").update {}
    update("ocaml", "ocaml_interface", "rapper")
  end,
}
