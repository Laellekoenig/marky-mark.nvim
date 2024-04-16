local marks = require("marky-mark.marks")

local M = {}

M.rerender = function(buff_instance, popup_buff_nr, buff_cursor)
  local lines = marks.get_marks(buff_instance)

  local goto_line = nil
  if buff_cursor ~= nil then
    goto_line = marks.get_closest_line_index(buff_instance, buff_cursor[1])
  end

  vim.api.nvim_set_option_value("modifiable", true, { buf = popup_buff_nr })
  vim.api.nvim_buf_set_lines(popup_buff_nr, 0, -1, false, {})
  vim.api.nvim_buf_set_lines(popup_buff_nr, 0, #lines, false, lines)
  vim.api.nvim_set_option_value("modifiable", false, { buf = popup_buff_nr })
  if goto_line ~= nil then
    vim.api.nvim_win_set_cursor(0, { goto_line, 0 })
  end
  vim.api.nvim_set_option_value("filetype", "marky-mark", { buf = popup_buff_nr })

  -- highlight numbers
  vim.cmd('syntax match myPluginLeadingNumber /\\d\\+/')
  vim.cmd('highlight link myPluginLeadingNumber Number')
end

return M
