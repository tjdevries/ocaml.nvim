local M = {}

M.dune_promote_file = function()
  if vim.bo.modified then
    print "Save before trying to promote"
    return
  end

  local event = assert(vim.uv.new_fs_event())
  local path = vim.fn.expand "%:p"
  event:start(path, {}, function(err, _)
    event:stop()
    event:close()

    if err then
      print("Oh no, an error", vim.inspect(err))
      return
    end
    vim.defer_fn(vim.cmd.checktime, 100)
  end)

  vim.lsp.buf.code_action {
    filter = function(x)
      return string.find(x.title, "Promote") ~= nil
    end,
    apply = true,
    range = {
      ["start"] = { 0, 0 },
      ["end"] = { -1, -1 },
    },
  }
end

return M
