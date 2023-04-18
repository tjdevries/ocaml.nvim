local M = {}

---@param node TSNode
function M.get_node_parents(node)
  -- save nodes in a table to iterate from top to bottom
  --- @type TSNode[]
  local parents = {}
  while node ~= nil do
    table.insert(parents, 1, node)
    node = node:parent()
  end
  return parents
end

return M
