local M = {}

--- Promote the current file via `dune promote`
M.dune_promote_file = function()
  if vim.bo.modified then
    vim.notify "Save before trying to promote"
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

--- Destruct a record or variant under the cursor
---@param opts { enumerate_cases: boolean | nil }?: Options for the destruct action
M.destruct = function(opts)
  opts = opts or {}
  opts.enumerate_cases = vim.F.if_nil(opts.enumerate_cases, false)

  -- Keep the old destruct kind, in case of older LSP.
  --    Newer version has multiple destruct kinds we can use.
  local only = { "destruct" }
  if opts.enumerate_cases then
    table.insert(only, "destruct (enumerate cases)")
  else
    table.insert(only, "destruct-line (enumerate cases, use existing match)")
  end

  vim.lsp.buf.code_action {
    apply = true,
    ---@diagnostic disable-next-line: missing-fields
    context = { only = only },
  }
end

return M
