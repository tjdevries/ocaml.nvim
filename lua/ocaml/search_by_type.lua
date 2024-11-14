local uv = vim.loop

local function get_ocamllsp()
  local cs = vim.lsp.get_clients { name = "ocamllsp" }
  return cs[1]
end

local function with_ocamllsp(f)
  local c = get_ocamllsp()
  if c then
    return f(c)
  else
    return vim.api.nvim_err_writeln "ocamllsp is not running"
  end
end

local function remove_newlines(s)
  return s:gsub("\n", " ")
end

--- switch between .ml and .mli
-- local function switchImplIntf()
--   with_ocamllsp(function(client)
--     local uri = vim.uri_from_bufnr(0)
--     local res = client.request_sync("ocamllsp/switchImplIntf", { vim.uri_from_bufnr(0) })
--     if res.result then
--       for _, uri in ipairs(res.result) do
--         vim.api.nvim_command("edit " .. vim.uri_to_fname(uri))
--         return
--       end
--     end
--   end)
-- end

local function merlinRequest(command, args, bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  return with_ocamllsp(function(lsp)
    local params = {
      uri = vim.uri_from_bufnr(0),
      command = command,
      args = args or {},
      resultAsSexp = false,
    }
    local res = lsp.request_sync("ocamllsp/merlinCallCompatible", params, 3000, bufnr)
    if res.error then
      return vim.api.nvim_err_writeln("ERROR: " .. vim.inspect(res.error))
    end
    return vim.json.decode(res.result.result).value
  end)
end

local function co_merlinRequest(command, args, bufnr)
  return with_ocamllsp(function(lsp)
    local params = {
      uri = vim.uri_from_bufnr(bufnr),
      command = command,
      args = args or {},
      resultAsSexp = false,
    }
    local me = coroutine.running()
    local handler = function(err, res)
      local value
      if res ~= nil then
        value = vim.json.decode(res.result).value
      end
      coroutine.resume(me, err, value)
    end
    lsp.request("ocamllsp/merlinCallCompatible", params, handler, bufnr)
    return coroutine.yield()
  end)
end

local function documentSymbols()
  local bufnr = vim.api.nvim_get_current_buf()
  local value = merlinRequest "outline"
  if not value then
    return
  end

  local function format_item(parents, item)
    local prefix = ""
    if item.kind == "Module" then
      prefix = "module "
    elseif item.kind == "Type" then
      prefix = "type "
    elseif item.kind == "Value" then
      prefix = "val "
    elseif item.kind == "Constructor" then
      prefix = "constructor "
    elseif item.kind == "Label" then
      prefix = "field "
    else
      prefix = item.kind .. " "
    end
    local padding = string.rep(" ", #parents)
    local name = item.name
    if #parents > 0 then
      name = table.concat(parents, ".") .. "." .. name
    end
    if item.kind == "Value" then
      name = name .. " : " .. remove_newlines(item.type or "...")
    end
    return string.format("%s%s%s", padding, prefix, name)
  end

  local data = {}

  local function handle(parents, item)
    local text = format_item(parents, item)
    if item.children and #item.children > 0 then
      local next_parents = vim.list_extend(parents, { item.name })
      for _, child in ipairs(item.children) do
        handle(next_parents, child)
      end
    end
    table.insert(data, { text = text, col = item.start.col, line = item.start.line })
  end

  for _, item in ipairs(value) do
    handle({}, item)
  end

  local rev_data = {}
  for i = #data, 1, -1 do
    table.insert(rev_data, data[i])
  end
  return rev_data
end

local function get_merlin_pos(winnr)
  winnr = winnr or 0
  local pos = vim.api.nvim_win_get_cursor(winnr)
  return string.format("%d:%d", pos[1], pos[2])
end

local function searchByType(query, bufnr, winnr)
  local pos = get_merlin_pos(winnr)
  return merlinRequest("search-by-type", { query = query, position = pos, ["with-doc"] = true }, bufnr)
end

SEARCH_BY_TYPE = function()
  --[[
  
    constructible = "Astlib__Stdlib0.Int.to_string _",
    cost = 8,
    doc = vim.NIL,
    ["end"] = {
      col = 15,
      line = 2
    },
    file = "astlib/stdlib0.ml",
    name = "Astlib__Stdlib0.Int.to_string",
    start = {
      col = 6,
      line = 2
    },
    type = "int -> string"
  }
  --]]
  --
  local pickers = require "telescope.pickers"
  local finders = require "telescope.finders"
  local conf = require("telescope.config").values
  local actions = require "telescope.actions"
  local action_state = require "telescope.actions.state"
  local ts_query = vim.treesitter.query

  local function search_by_type_picker(opts)
    opts = opts or {}

    -- Get current buffer and window for the search context
    local bufnr = vim.api.nvim_get_current_buf()
    local winnr = vim.api.nvim_get_current_win()

    -- Get search results
    local results = searchByType(opts.query or "int -> expression", bufnr, winnr)
    if not results then
      vim.notify("No results found", vim.log.levels.WARN)
      return
    end

    local function ocaml_entry_maker(entry)
      local function make_display(entry)
        local names = vim.split(entry.value.name, ".", { plain = true })
        local modname = names[#names]
        local text = string.format("val %s : %s", modname, entry.value.type)

        local parser = vim.treesitter.get_string_parser(text, "ocaml_interface")
        local tree = parser:parse()[1]
        local root = tree:root()
        local query = assert(ts_query.get("ocaml_interface", "highlights"), "Must have ocaml_interface highlights")

        local hl_map = {}

        for id, node, _ in query:iter_captures(root, text, 0, -1) do
          local hl = query.captures[id]
          if hl then
            local _, scol, _, ecol = node:range()
            table.insert(hl_map, {
              highlight = hl,
              col_start = scol,
              col_end = ecol,
            })
          end
        end

        local display_line = text

        -- Sort highlights by start column
        table.sort(hl_map, function(a, b)
          return a.col_start < b.col_start
        end)

        local hl_entries = {}
        -- { { hl_start, hl_end }, hl }
        local last_index = 1
        for _, hl in ipairs(hl_map) do
          table.insert(hl_entries, { { hl.col_start, hl.col_end }, hl.highlight })
          last_index = hl.col_end + 1
        end

        vim.print(hl_entries)
        return text, hl_entries
      end

      return {
        value = entry,
        display = make_display,
        ordinal = string.format("%s %s", entry.name, entry.type),
        -- Additional metadata for preview
        preview_text = entry.doc ~= vim.NIL and entry.doc or "No documentation available",
        constructible = entry.constructible,
      }
    end

    -- Create the picker
    pickers
      .new(require("telescope.themes").get_ivy(opts), {
        prompt_title = "Search by Type",
        finder = finders.new_table {
          results = results,
          entry_maker = ocaml_entry_maker,
        },
        sorter = conf.generic_sorter(opts),
        previewer = require("telescope.previewers").new_buffer_previewer {
          title = "Documentation",
          define_preview = function(self, entry, status)
            vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, vim.split(entry.preview_text, "\n"))
          end,
        },
        attach_mappings = function(prompt_bufnr, map)
          actions.select_default:replace(function()
            actions.close(prompt_bufnr)
            local selection = action_state.get_selected_entry()
            if selection then
              -- Insert the constructible expression at current cursor position
              local pos = vim.api.nvim_win_get_cursor(0)
              vim.api.nvim_buf_set_text(
                0,
                pos[1] - 1,
                pos[2],
                pos[1] - 1,
                pos[2],
                { "(" .. selection.value.constructible .. ")" }
              )
            end
          end)
          return true
        end,
      })
      :find()
  end

  search_by_type_picker {}
end

-- if can_require "fzf" then
--   local fzf = require "fzf"
--   local action = require("fzf.actions").action
--   local raw_async_action = require("fzf.actions").raw_async_action
--
--   local function item_to_line(item)
--     return string.format("%s,%s,%s", item.line, item.col, item.text)
--   end
--   local function line_to_item(line)
--     local parts = vim.split(line, ",")
--     return { line = tonumber(parts[1]), col = tonumber(parts[2]), text = parts[3] }
--   end
--
--   local c_bold = "\027[1m"
--   local c_reset = "\027[0m"
--
--   local function get_buffer_lines(bufnr, line, height)
--     local s = math.max(math.floor(line - height / 2), 0)
--     local e = math.floor(line + height / 2)
--     if vim.api.nvim_buf_is_loaded(bufnr) then
--       local lines = vim.api.nvim_buf_get_lines(bufnr, s, e, false)
--       if lines[line - s] ~= nil then
--         lines[line - s] = c_bold .. lines[line - s] .. c_reset
--         return lines
--       else
--         return {} -- nothing to preview, maybe symbol is generated by ppx?
--       end
--     end
--   end
--
--   local function fzf_documentSymbols()
--     local bufnr = vim.api.nvim_get_current_buf()
--     local symbols = documentSymbols()
--     if not symbols then
--       return vim.api.nvim_err_writeln "No symbols found"
--     end
--     local lines = {}
--     for _, item in ipairs(symbols) do
--       table.insert(lines, item_to_line(item))
--     end
--     local preview = action(function(lines, height, width)
--       local item = line_to_item(lines[1])
--       return get_buffer_lines(bufnr, item.line, height)
--     end)
--     coroutine.wrap(function()
--       local args = {
--         "--prompt='DocumentSymbols> '",
--         "--delimiter=,",
--         "--with-nth=3..",
--         "--layout=reverse-list",
--         "--preview=" .. preview,
--       }
--       local cmd = table.concat(args, " ")
--       local lines = fzf.fzf(lines, cmd, {})
--       vim.schedule(function()
--         if not lines or #lines < 1 then
--           return
--         end
--         local item = line_to_item(lines[1])
--         vim.api.nvim_win_set_cursor(0, { item.line, item.col })
--         vim.cmd "normal! zz"
--       end)
--     end)()
--   end
--
--   vim.api.nvim_create_user_command("OCamlDocumentSymbols", fzf_documentSymbols, {})
--
--   local function insert_at_position(text)
--     local pos = vim.api.nvim_win_get_cursor(0)
--     vim.api.nvim_buf_set_text(0, pos[1] - 1, pos[2] - 1, pos[1] - 1, pos[2] - 1, { text })
--   end
--
--   local function fzf_searchByType(opts)
--     local bufnr = vim.api.nvim_get_current_buf()
--     local winnr = vim.api.nvim_get_current_win()
--     local last_value = {}
--
--     local function search(query, with_newline)
--       if not query or query == "" then
--         return nil, {}
--       end
--       local newline = with_newline and "\n" or ""
--       local err, value = searchByType(query, bufnr, winnr)
--       if err then
--         return err
--       end
--       last_value = value
--       local lines = {}
--       for idx, item in ipairs(value) do
--         local line = string.format("%d,%s : %s%s", idx, item.name, remove_newlines(item.type), newline)
--         table.insert(lines, line)
--       end
--       return nil, lines
--     end
--
--     local function get_item(line)
--       local parts = vim.split(line, ",")
--       local idx = tonumber(parts[1])
--       return last_value[idx]
--     end
--
--     local on_change = raw_async_action(function(oc, args)
--       coroutine.wrap(function()
--         local query = args[2]
--         local err, lines = search(query, true)
--         if err then
--           uv.close(oc)
--           return vim.api.nvim_err_writeln("ERROR: " .. vim.inspect(err))
--         end
--         for _, line in ipairs(lines) do
--           uv.write(oc, line)
--         end
--         uv.close(oc)
--       end)()
--     end)
--
--     local preview = action(function(res, height, width)
--       local item = get_item(res[1])
--       if item.doc == vim.NIL then
--         return ""
--       else
--         return item.doc
--       end
--     end)
--
--     local query = opts.fargs[1]
--     local args = {
--       "--prompt='SearchByType> '",
--       "--delimiter=,",
--       "--with-nth=2..",
--       "--layout=reverse-list",
--       "--disabled",
--       "--preview=" .. preview,
--       vim.fn.shellescape(string.format("--bind=change:reload:%s {q}", on_change)),
--     }
--     if query then
--       table.insert(args, string.format("--query=%s", vim.fn.shellescape(query)))
--     end
--     local cmd = table.concat(args, " ")
--
--     coroutine.wrap(function()
--       local err, lines = search(query, false)
--       if err then
--         return vim.api.nvim_err_writeln("ERROR: " .. vim.inspect(err))
--       end
--       local res = fzf.fzf(lines, cmd)
--       vim.schedule(function()
--         if not res or #res < 1 then
--           return
--         end
--         local item = get_item(res[1])
--         if not item then
--           return
--         end
--         insert_at_position("(" .. item.constructible .. ")")
--       end)
--     end)()
--   end
--
--   vim.api.nvim_create_user_command("OCamlSearchByType", fzf_searchByType, { nargs = "?" })
-- end
