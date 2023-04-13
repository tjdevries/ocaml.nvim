if not pcall(require, "nvim-treesitter") then
  print "treesitter is not installed"
  return
end

-- Adds rapper parser to the list of parsers
local list = require("nvim-treesitter.parsers").get_parser_configs()
list.rapper = {
  install_info = {
    url = "https://github.com/tjdevries/tree-sitter-rapper",
    revision = "26b91c3c517a7a3a9f18c654eb63ebe23907261c",
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
    if not is_installed "rapper" then
      print "[ppx_rapper] Please install rapper parser with `:TSUpdate rapper`"
    end
  end,
}
