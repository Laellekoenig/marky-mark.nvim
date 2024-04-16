local M = {}

M.table_find = function(tbl, predicate_fn)
  for i, value in ipairs(tbl) do
    if predicate_fn(value) then
      return i
    end
  end

  return nil
end

M.in_marky_mark = function()
  local buff_nr = vim.api.nvim_get_current_buf()
  local buff_filetype = vim.api.nvim_get_option_value("filetype", { buf = buff_nr })
  return buff_filetype == "marky-mark"
end

M.get_curr_line = function()
  local cursor = vim.api.nvim_win_get_cursor(0)
  return cursor[1]
end

M.get_visual_selected_lines = function(buff_nr)
  -- leave visual mode
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<esc>", true, false, true), "nx", false)
  local v_start = vim.api.nvim_buf_get_mark(buff_nr, "<")
  local v_end = vim.api.nvim_buf_get_mark(buff_nr, ">")
  return v_start[1], v_end[1]
end

return M
