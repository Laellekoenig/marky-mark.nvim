local marks = require("marky-mark.marks")

local M = {}

M.rerender = function(buff_instance, popup_buff_nr, buff_cursor, popup_width)
  local lines = marks.get_formatted_marks_str(buff_instance, popup_width)

  -- clear buffer and insert new lines
  vim.api.nvim_set_option_value("filetype", "marky-mark", { buf = popup_buff_nr })
  vim.api.nvim_set_option_value("modifiable", true, { buf = popup_buff_nr })
  vim.api.nvim_buf_set_lines(popup_buff_nr, 0, -1, false, {})
  vim.api.nvim_buf_set_lines(popup_buff_nr, 0, #lines, false, lines)
  vim.api.nvim_set_option_value("modifiable", false, { buf = popup_buff_nr })

  -- highlight numbers and marks
  vim.cmd('syntax match marky_mark_leading_number "^\\s*\\d\\+"')
  vim.cmd('highlight link marky_mark_leading_number Comment')

  vim.cmd('syntax match marky_mark_mark "\\(^\\s*\\d\\+\\s*\\)\\@<=\'\\k\\{1}"')
  vim.cmd('highlight link marky_mark_mark String')

  vim.cmd('syntax match marky_mark_line "\\(^\\s*\\d\\+\\s*\'\\k\\{1}\\)\\@<=.*"')
  vim.cmd('highlight link marky_mark_line Identifier')

  local goto_line = nil
  if buff_cursor ~= nil then
    goto_line = marks.get_closest_line_index(buff_instance, buff_cursor[1])
  end

  if goto_line ~= nil then
    vim.api.nvim_win_set_cursor(0, { goto_line, 0 })
  end
end

return M
