local M = {}

M.table_find = function(tbl, predicate)
  for i, v in ipairs(tbl) do
    if predicate(v) then
      return i
    end
  end

  return nil
end

return M
