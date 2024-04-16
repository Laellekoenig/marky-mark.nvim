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

M.get_next_mark = function(buff_instance)
  if #buff_instance.freed_marks > 0 then
    return table.remove(buff_instance.freed_marks, 1)
  end

  local mark = buff_instance.next_mark
  buff_instance.next_mark = string.char(string.byte(mark) + 1)
  if buff_instance.next_mark == 'z' then
    -- TODO: better error handling
    error("All marks used.")
  else
    return mark
  end
end

M.mark_buff = function(buff_instance, cursor)
  local mark = M.get_mark_if_marked(buff_instance, cursor[1])
  local do_insert = true
  if mark == nil then
    mark = {
      char = M.get_next_mark(buff_instance),
      col = cursor[2],
    }
    vim.api.nvim_buf_set_mark(buff_instance.buff_nr, mark.char, cursor[1], mark.col, {})
  else
    mark.col = cursor[2]
    do_insert = false
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
  local removed_mark = table.remove(buff_instance.marks, mark_index)
  table.insert(buff_instance.freed_marks, removed_mark.char)
  table.sort(buff_instance.freed_marks)
  print(vim.inspect(buff_instance))
end

M.remove_marks = function(buff_instance, from, to)
  for i = to, from, -1 do
    M.remove_mark(buff_instance, i)
  end
end

M.goto_mark = function(buff_instance, mark_index, close_popup)
  local mark = buff_instance.marks[mark_index]
  close_popup()
  vim.api.nvim_feedkeys("'" .. mark.char, "nx", true)

  local cursor = vim.api.nvim_win_get_cursor(0)
  vim.api.nvim_win_set_cursor(0, { cursor[1], mark.col })
end

M.get_closest_line_index = function(buff_instance, line_nr)
  local min = nil
  local diff = nil
  for i, m in ipairs(buff_instance.marks) do
    local mark = vim.api.nvim_buf_get_mark(buff_instance.buff_nr, m.char)
    if min == nil or math.abs(line_nr - mark[1]) <= diff then
      min = i
      diff = math.abs(line_nr - mark[1])
    end
  end

  return min
end

return M
