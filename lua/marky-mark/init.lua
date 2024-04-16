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

  marks.mark_buff(buff_instance, vim.api.nvim_win_get_cursor(0))
end

M.show_list = function()
  if utils.in_marky_mark() then
    error("Cannot open marky-mark in marky-mark.")
    return
  end

  local popup = Popup({
    enter = true,
    focusable = true,
    border = {
      style = "rounded",
      text = {
        top = "Local Marks",
        top_align = "center",
      },
    },
    position = "50%",
    size = {
      width = 40,
      height = 10,
    },
  })

  local buff_nr = vim.api.nvim_get_current_buf()
  local buff_cursor = vim.api.nvim_win_get_cursor(0)
  local buff_instance = marks.get_buff_instance(M.buffers, buff_nr)
  if buff_instance == nil then
    buff_instance = marks.new_buff_instance(buff_nr)
    table.insert(M.buffers, buff_instance)
  end

  local ok = popup:map("n", "q", function() popup:unmount() end, { noremap = true })
  local ok2 = popup:map("n", "<c-c>", function() popup:unmount() end, { noremap = true })
  local ok3 = popup:map("n", "<esc>", function() popup:unmount() end, { noremap = true })
  local ok4 = popup:map("n", "<cr>", function()
    local cursor = vim.api.nvim_win_get_cursor(0)
    marks.goto_mark(buff_instance, cursor[1], function() popup:unmount() end)
    if M.opts.zz_after_jump then
      vim.api.nvim_feedkeys("zz", "n", true)
    end
  end, { noremap = true })

  local ok5 = popup:map("n", "dd", function()
    local cursor = vim.api.nvim_win_get_cursor(0)
    marks.remove_mark(buff_instance, cursor[1])
    ui.rerender(buff_instance, popup.bufnr, buff_cursor)
  end, { noremap = true })

  local ok6 = popup:map("v", "d", function()
    -- leave visual mode
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<esc>", true, false, true), "nx", false)
    local v_start = vim.api.nvim_buf_get_mark(popup.bufnr, "<")
    local v_end = vim.api.nvim_buf_get_mark(popup.bufnr, ">")
    marks.remove_marks(buff_instance, v_start[1], v_end[1])
    ui.rerender(buff_instance, popup.bufnr)
  end, { noremap = true })

  if not ok or not ok2 or not ok3 or not ok4 or not ok5 or not ok6 then
    print("error when setting keybinds")
    return
  end

  popup:on(event.BufLeave, function()
    popup:unmount()
  end)

  popup:mount()
  ui.rerender(buff_instance, popup.bufnr, buff_cursor)
end

M.setup = function(opts)
  M.opts = opts or {
    zz_after_jump = true,
  }
  vim.keymap.set("n", "ma", "<cmd>lua require('marky-mark').add_mark()<cr>")
  vim.keymap.set("n", "mm", "<cmd>lua require('marky-mark').show_list()<cr>")
end

return M
