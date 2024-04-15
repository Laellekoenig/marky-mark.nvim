local marks = require("marky-mark.marks")

local M = {}

M.rerender = function(buff_instance, popup_buff_nr)
  local lines = marks.get_marks(buff_instance)

  vim.api.nvim_set_option_value("modifiable", true, { buf = popup_buff_nr})
  vim.api.nvim_buf_set_lines(popup_buff_nr, 0, -1, false, {})
  vim.api.nvim_buf_set_lines(popup_buff_nr, 0, #lines, false, lines)
  vim.api.nvim_set_option_value("modifiable", false, { buf = popup_buff_nr})
  vim.cmd('syntax match myPluginLeadingNumber /^\\d\\+/')
  vim.cmd('highlight link myPluginLeadingNumber Number')
end

return M
