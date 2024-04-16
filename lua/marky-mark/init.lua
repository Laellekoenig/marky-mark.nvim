local marks = require("marky-mark.marks")
local utils = require("marky-mark.utils")
local ui = require("marky-mark.ui")
local Popup = require("nui.popup")
local event = require("nui.utils.autocmd").event

local M = {}
M.buffers = {}

M.add_mark = function()
  if utils.in_marky_mark() then
    error("Cannot mark lines in marky-mark.")
    return
  end

  local buff_nr = vim.api.nvim_get_current_buf()
  local buff_instance = marks.get_buff_instance(M.buffers, buff_nr)

  if buff_instance == nil then
    buff_instance = marks.new_buff_instance(buff_nr)
    table.insert(M.buffers, buff_instance)
  end

  local cursor = vim.api.nvim_win_get_cursor(0)
  marks.mark_buff_line(buff_instance, cursor)
end

M.goto_next_mark = function()
  if utils.in_marky_mark() then
    error("Cannot go to next mark in marky-mark buffer.")
  end

  local buff_instance = marks.get_curr_buff_instance(M.buffers)
  local curr_line = utils.get_curr_line()
  local i = marks.get_next_mark_index(buff_instance, curr_line)
  if i == nil then
    print("No marks set in this file.")
    return
  end

  marks.goto_mark(buff_instance, i, nil)
end

M.goto_prev_mark = function()
  if utils.in_marky_mark() then
    error("Cannot go to next mark in marky-mark buffer.")
  end

  local buff_instance = marks.get_curr_buff_instance(M.buffers)
  local curr_line = utils.get_curr_line()
  local i = marks.get_prev_mark_index(buff_instance, curr_line)
  if i == nil then
    print("No marks set in this file.")
    return
  end

  marks.goto_mark(buff_instance, i, nil)
end

M.show_list = function()
  if utils.in_marky_mark() then
    error("Cannot open marky-mark in marky-mark.")
    return
  end

  local buff_nr = vim.api.nvim_get_current_buf()
  local buff_instance = marks.get_buff_instance(M.buffers, buff_nr)
  if buff_instance == nil then
    buff_instance = marks.new_buff_instance(buff_nr)
    table.insert(M.buffers, buff_instance)
  end

  local curr_line = utils.get_curr_line()
  local closest_line_index = marks.get_closest_line_index(buff_instance, curr_line)

  -- offset so closest line is ontop of cursor
  local y_off = nil
  if closest_line_index ~= nil then
    y_off = -1 * closest_line_index + 1
  end

  local lines = marks.get_formatted_marks_str(buff_instance)
  local height = math.max(#lines, 1)

  local popup = Popup({
    enter = true,
    focusable = true,
    relative = "cursor",
    border = {
      padding = {
        left = 1,
        right = 1,
      },
      style = "rounded",
      text = {
        top = "Local Marks",
        top_align = "center",
      },
    },
    position = {
      row = y_off or 0,
      col = 0,
    },
    size = {
      width = 40,
      height = height,
    },
  })

  -- quit
  popup:map("n", "q", function() popup:unmount() end, { noremap = true })
  popup:map("n", "<c-c>", function() popup:unmount() end, { noremap = true })
  popup:map("n", "<esc>", function() popup:unmount() end, { noremap = true })

  -- select item
  popup:map("n", "<cr>", function()
    local selected_line = utils.get_curr_line()
    marks.goto_mark(buff_instance, selected_line, function() popup:unmount() end)
    if M.opts.zz_after_jump then
      vim.api.nvim_feedkeys("zz", "n", true)
    end
  end, { noremap = true })

  -- delete items
  popup:map("n", "dd", function()
    local line_to_delete = utils.get_curr_line()
    marks.remove_mark(buff_instance, line_to_delete)
    ui.rerender(buff_instance, popup.bufnr, nil)
  end, { noremap = true })

  popup:map("v", "d", function()
    -- leave visual mode
    local from, to = utils.get_visual_selected_lines(popup.bufnr)
    marks.remove_marks(buff_instance, from, to)
    ui.rerender(buff_instance, popup.bufnr, nil)
  end, { noremap = true })

  popup:on(event.BufLeave, function()
    popup:unmount()
  end)

  local buff_cursor = vim.api.nvim_win_get_cursor(0)
  popup:mount()
  ui.rerender(buff_instance, popup.bufnr, buff_cursor)
end

M.setup = function(opts)
  M.opts = opts or {
    zz_after_jump = true,
    use_default_keymap = true,
  }

  if M.opts.use_default_keymap then
    vim.keymap.set("n", "ma", "<cmd>lua require('marky-mark').add_mark()<cr>", { noremap = true, silent = true })
    vim.keymap.set("n", "mm", "<cmd>lua require('marky-mark').show_list()<cr>", { noremap = true, silent = true })
    vim.keymap.set("n", "mn", "<cmd>lua require('marky-mark').goto_next_mark()<cr>", { noremap = true, silent = true })
    vim.keymap.set("n", "mp", "<cmd>lua require('marky-mark').goto_prev_mark()<cr>", { noremap = true, silent = true })
  end
end

return M
