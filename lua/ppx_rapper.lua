if not pcall(require, "nvim-treesitter") then
  print "treesitter is not installed"
  return
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
    if not is_installed "rapper" then
      print "[ppx_rapper] Please install rapper parser with `:TSUpdate rapper`"
    end

    -- Put some default highlights to arguments
    pcall(
      vim.cmd,
      [[
        silent! hi link @rapper_argument @parameter
        silent! hi link @rapper_return @type
      ]]
    )
  end,
}
