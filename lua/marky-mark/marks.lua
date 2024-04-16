local utils = require("marky-mark.utils")

local M = {}

M.get_buff_instance = function(buffers, buff_nr)
  for _, b in ipairs(buffers) do
    if b.buff_nr == buff_nr then
      return b
    end
  end
end

M.get_curr_buff_instance = function(buffers)
  local buff_nr = vim.api.nvim_get_current_buf()
  return M.get_buff_instance(buffers, buff_nr)
end

M.new_buff_instance = function(buff_nr)
  local buff = {
    buff_nr = buff_nr,
    next_mark = "a",
    freed_marks = {},
    marks = {},
  }
  return buff
end

M.get_mark_if_marked = function(buff_instance, line)
  for _, m in ipairs(buff_instance.marks) do
    local cursor = vim.api.nvim_buf_get_mark(buff_instance.buff_nr, m.char)
    if cursor[1] == line then
      return m
    end
  end
end

M.get_next_mark_char = function(buff_instance)
  if #buff_instance.freed_marks > 0 then
    return table.remove(buff_instance.freed_marks, 1)
  end

  if buff_instance.next_mark == '{' then
    error("All marks used.")
    return nil
  end

  local mark = buff_instance.next_mark
  buff_instance.next_mark = string.char(string.byte(mark) + 1)
  return mark
end

M.mark_buff_line = function(buff_instance, cursor)
  -- check if line has already been marked
  local mark = M.get_mark_if_marked(buff_instance, cursor[1])

  if mark ~= nil then
    mark.col = cursor[2]
    return
  end

  mark = {
    char = M.get_next_mark_char(buff_instance),
    col = cursor[2],
  }
  vim.api.nvim_buf_set_mark(buff_instance.buff_nr, mark.char, cursor[1], mark.col, {})

  table.insert(buff_instance.marks, mark)
  table.sort(buff_instance.marks, function(a, b)
    local c1 = vim.api.nvim_buf_get_mark(buff_instance.buff_nr, a.char)
    local c2 = vim.api.nvim_buf_get_mark(buff_instance.buff_nr, b.char)
    return c1[1] < c2[1]
  end)
end

M.get_formatted_marks_str = function(buff_instance)
  local lines = {}
  local line_nums = {}
  local max_num_len = 0

  for _, mark in pairs(buff_instance.marks) do
    local cursor = vim.api.nvim_buf_get_mark(buff_instance.buff_nr, mark.char)
    local got_lines = vim.api.nvim_buf_get_lines(buff_instance.buff_nr, cursor[1] - 1, cursor[1], false)

    if #got_lines > 0 then
      local line = got_lines[1]
      -- remove leading and trailing whitespace
      line = line:gsub("^%s*(.-)%s*$", "%1")

      local line_nr = tostring(cursor[1])
      max_num_len = math.max(max_num_len, #line_nr)

      table.insert(lines, line)
      table.insert(line_nums, line_nr)
    else
      error("Could not get marked line")
    end
  end

  local marks = {}
  local padding = 5

  for i, line in ipairs(lines) do
    local line_num = line_nums[i]
    local num_str = string.rep(" ", max_num_len - #line_num) .. line_num
    table.insert(marks, num_str .. string.rep(" ", padding - #num_str) .. line)
  end

  return marks
end

M.remove_mark = function(buff_instance, mark_index)
  local removed_mark = table.remove(buff_instance.marks, mark_index)
  table.insert(buff_instance.freed_marks, removed_mark.char)
  table.sort(buff_instance.freed_marks)
end

M.remove_marks = function(buff_instance, from_index, to_index)
  for i = to_index, from_index, -1 do
    M.remove_mark(buff_instance, i)
  end
end

M.goto_mark = function(buff_instance, mark_index, close_popup_fn)
  local mark = buff_instance.marks[mark_index]

  if close_popup_fn ~= nil then
    close_popup_fn()
  end

  vim.api.nvim_feedkeys("'" .. mark.char, "nx", true)
  local curr_line = utils.get_curr_line()
  vim.api.nvim_win_set_cursor(0, { curr_line, mark.col })
end

M.get_closest_line_index = function(buff_instance, line_nr)
  local min = nil
  local diff = nil

  for i, mark in ipairs(buff_instance.marks) do
    local cursor = vim.api.nvim_buf_get_mark(buff_instance.buff_nr, mark.char)
    if min == nil or math.abs(line_nr - cursor[1]) <= diff then
      min = i
      diff = math.abs(line_nr - cursor[1])
    end
  end

  return min
end

M.get_next_mark_index = function(buff_instance, curr_line_nr)
  if buff_instance == nil or #buff_instance.marks == 0 then
    return
  end

  for i, mark in ipairs(buff_instance.marks) do
    local cursor = vim.api.nvim_buf_get_mark(buff_instance.buff_nr, mark.char)
    if cursor ~= nil and cursor[1] > curr_line_nr then
      return i
    end
  end

  if #buff_instance.marks > 0 then
    return 1
  end

  error("Failed to find next mark in buffer.")
end

M.get_prev_mark_index = function(buff_instance, curr_line_nr)
  if buff_instance == nil or #buff_instance.marks == 0 then
    return
  end

  local found = nil
  for i, mark in ipairs(buff_instance.marks) do
    local cursor = vim.api.nvim_buf_get_mark(buff_instance.buff_nr, mark.char)
    if cursor ~= nil and cursor[1] < curr_line_nr then
      found = i
    elseif cursor ~= nil and cursor[1] >= curr_line_nr then
      break
    end
  end

  if found ~= nil then
    return found
  end

  if #buff_instance.marks > 0 then
    return #buff_instance.marks
  end

  error("Failed to find previous mark in buffer.")
end

return M
