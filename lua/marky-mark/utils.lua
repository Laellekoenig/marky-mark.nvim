local M = {}

M.table_find = function(tbl, predicate)
  for i, v in ipairs(tbl) do
    if predicate(v) then
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

return M
