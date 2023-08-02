local M = {}

-- Returns the number of items in a given table that match a predicate.
function M.count(t, predicate)
  local c = 0
  for i, v in ipairs(t) do
    if predicate(v, i) then c = c + 1 end
  end
  return c
end

-- Returns a boolean indicating whether
-- every item in a given table matches a predicate.
function M.every(t, predicate)
  for i, v in ipairs(t) do
    if not predicate(v, i) then return false end
  end
  return true
end

-- Returns a new table containing all items in a given table
-- that match a predicate.
function M.filter(t, predicate)
  local result = {}
  for i, v in ipairs(t) do
    if predicate(v, i) then
      table.insert(result, v)
    end
  end
  return result
end

-- Returns the first item in a given table that matches a predicate.
function M.find(t, predicate)
  for _, v in ipairs(t) do
    if predicate(v) then return v end
  end
end

-- Returns a new table containing the results of passing
-- each item in a given table to a given function.
function M.map(t, fn)
  local result = {}
  for i, v in ipairs(t) do
    result[i] = fn(v, i)
  end
  return result
end

-- Returns the maximum value returned by a function
-- that is passed each item in a given table.
function M.max(t, fn)
  local result
  for i, v in ipairs(t) do
    local computed = fn(v, i)
    if not result or computed > result then result = computed end
  end
  return result
end

-- Returns the minimum value returned by a function
-- that is passed each item in a given table.
function M.min(t, fn)
  local result
  for i, v in ipairs(t) do
    local computed = fn(v, i)
    if not result or computed < result then result = computed end
  end
  return result
end

-- Returns a single value computed by accumulating the results
-- of passing each item in a given table to a given function.
function M.reduce(t, fn, initial)
  local acc = initial or 0
  for i, v in ipairs(t) do
    acc = fn(acc, v, i)
  end
  return acc
end

-- Returns a boolean indicating whether
-- some item in a given table matches a predicate.
function M.some(t, predicate)
  for i, v in ipairs(t) do
    if predicate(v, i) then return true end
  end
  return false
end

-- Returns the sum of the numbers in a given table.
-- While this can be implemented using "reduce",
-- this is a bit more efficient.
function M.sum(t)
  local result = 0
  for _, v in ipairs(t) do
    result = result + v
  end
  return result
end

-- Returns the sum of the values returned by
-- a function that is passed each item in a given table.
-- While this can be implemented using "reduce",
-- this is a bit more efficient.
function M.sumFn(t, fn)
  local result = 0
  for _, v in ipairs(t) do
    result = result + fn(v)
  end
  return result
end

return M
