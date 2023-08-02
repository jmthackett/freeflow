function string.contains(source, target)
  return source:find(target, 1, true) ~= nil
end

function string.startsWith(source, target)
  return source:find(target, 1, true) == 1
end

function string.endsWith(source, target)
  local _, endIndex = source:find(target, 1, true)
  return endIndex == #source
end
