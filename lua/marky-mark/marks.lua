local M = {}

M.get_buff_instance = function(buffers, buff_nr)
  for _, b in ipairs(buffers) do
    if b.buff_nr == buff_nr then
      return b
    end
  end
end

M.new_buff_instance = function(buff_nr)
  local buff = {
    buff_nr = buff_nr,
    next_mark = "a",
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

M.mark_buff = function(buff_instance, cursor)
  local mark = M.get_mark_if_marked(buff_instance, cursor[1])
  local do_insert = true
  if mark == nil then
    mark = {
      char = buff_instance.next_mark,
      col = cursor[2],
    }
    vim.api.nvim_buf_set_mark(buff_instance.buff_nr, mark.char, cursor[1], mark.col, {})
  else
    mark.col = cursor[2]
    do_insert = false
  end

  -- TODO: better handling of overflow
  if buff_instance.next_mark == "z" then
    buff_instance.next_mark = "a"
  else
    buff_instance.next_mark = string.char(string.byte(buff_instance.next_mark) + 1)
  end

  if do_insert then
    table.insert(buff_instance.marks, mark)
    table.sort(buff_instance.marks, function(a, b)
      local c1 = vim.api.nvim_buf_get_mark(buff_instance.buff_nr, a.char)
      local c2 = vim.api.nvim_buf_get_mark(buff_instance.buff_nr, b.char)
      return c1[1] < c2[1]
    end)
  end
end

M.get_marks = function(buff_instance)
  local marks = {}

  for _, mark in pairs(buff_instance.marks) do
    local cursor = vim.api.nvim_buf_get_mark(buff_instance.buff_nr, mark.char)
    local lines = vim.api.nvim_buf_get_lines(buff_instance.buff_nr, cursor[1] - 1, cursor[1], false)
    if #lines > 0 then
      local line = lines[1]
      line = line:gsub("^%s*(.-)%s*$", "%1")
      local line_nr = tostring(cursor[1])
      local padding = 5 - #line_nr
      table.insert(marks, line_nr .. string.rep(" ", padding) .. line)
    else
      print("Error getting marked line")
    end
  end

  return marks
end

M.remove_mark = function(buff_instance, mark_index)
  table.remove(buff_instance.marks, mark_index)
end

M.remove_marks = function(buff_instance, from, to)
  for i=to, from, -1 do
    table.remove(buff_instance.marks, i)
  end
end

M.goto_mark = function(buff_instance, mark_index, close_popup)
  local mark = buff_instance.marks[mark_index]
  close_popup()
  vim.api.nvim_feedkeys("'" .. mark.char, "nx", true)

  local cursor = vim.api.nvim_win_get_cursor(0)
  vim.api.nvim_win_set_cursor(0, { cursor[1], mark.col })
end

return M
