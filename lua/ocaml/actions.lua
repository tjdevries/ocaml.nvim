local ocaml_ts = require "ocaml.treesitter"

local M = {}

local query = vim.treesitter.query.parse(
  "ocaml",
  [[ (type_definition
         (type_binding
          (type_constructor) @name)) @type_definition ]]
)

local name_idx = 1
local type_def_idx = 2

local find_cursor_match = function(bufnr)
  local cursor = vim.api.nvim_win_get_cursor(0)
  local tree = vim.treesitter.get_parser(bufnr, "ocaml"):parse()[1]
  for _, match, _ in query:iter_matches(tree:root(), bufnr, 0, -1) do
    local definition_node = match[type_def_idx]
    if
      vim.treesitter.node_contains(definition_node, {
        cursor[1] - 1,
        cursor[2],
        cursor[1] - 1,
        cursor[2],
      })
    then
      return match
    end
  end
end

local context_types = {
  module_binding = true,
  class_binding = true,
  class_type_binding = true,
  method_definition = true,
  let_binding = true,
  function_expression = true,
}

local find_context = function(node, bufnr)
  local parents = ocaml_ts.get_node_parents(node)

  local context = {}
  for _, parent in ipairs(parents) do
    if context_types[parent:type()] then
      table.insert(context, vim.split(vim.treesitter.get_node_text(parent, bufnr), "\n")[1])
    end
  end

  return table.concat(context, " > ")
end

local find_match_by_context = function(context, bufnr)
  local matches = {}

  local tree = vim.treesitter.get_parser(bufnr, "ocaml"):parse()[1]
  for _, match, _ in query:iter_matches(tree:root(), bufnr, 0, -1) do
    local match_context = find_context(match[name_idx], bufnr)
    if match_context == context then
      table.insert(matches, match)
    end
  end

  return matches
end

M.update_interface_type = function()
  local input_file = vim.api.nvim_buf_get_name(0)
  local input_extension = vim.fn.fnamemodify(input_file, ":e")
  local output_config = ({
    ml = {
      extension = ".mli",
    },
    mli = {
      extension = ".ml",
    },
  })[input_extension]

  if not output_config then
    vim.notify "[ocaml.nvim] not an .ml/.mli file"
    return
  end

  local output_file = vim.fn.fnamemodify(input_file, ":p:r") .. output_config.extension
  if not vim.loop.fs_stat(output_file) then
    vim.notify "[ocaml.nvim] no mli file found"
    return
  end

  local input_bufnr = vim.api.nvim_get_current_buf()
  local match = find_cursor_match(input_bufnr)
  if not match then
    vim.notify "[ocaml.nvim] cursor not on a type_definition"
    return
  end

  local output_bufnr = vim.fn.bufnr(output_file, true)

  local search_context = find_context(match[name_idx], input_bufnr)
  local matches = find_match_by_context(search_context, output_bufnr)

  if #matches == 0 then
    vim.notify "[ocaml.nvim] no match found in .ml/.mli"
    return
  end

  local update = function(to_update)
    local range = require("nvim-treesitter.ts_utils").node_to_lsp_range(to_update)
    local updated_text = vim.treesitter.get_node_text(match[type_def_idx], input_bufnr)
    local edit = { range = range, newText = updated_text }
    vim.lsp.util.apply_text_edits({ edit }, output_bufnr, "utf-8")
  end

  if #matches == 1 then
    local to_update = matches[1][type_def_idx]
    update(to_update)
  else
    vim.ui.select(matches, {
      prompt = "Select variant to update",
      format_item = function(item)
        local context = find_context(item[name_idx], output_bufnr)
        local range = { item:range() }
        return string.format("line: %d, column: %d, %s", range[1], range[2], context)
      end,
    }, function(choice)
      local to_update = choice[type_def_idx]
      update(to_update)
    end)
  end
end

return M
