Utils = {}

function Utils.tableContainsKey(tableToCheck, key)
    for k, v in pairs(tableToCheck) do
        if k == key then
            return true
        end
    end
    return false
end

function Utils.tableContainsValue(tableToCheck, value)
    for i, v in ipairs(tableToCheck) do
        if v == value then
            return true
        end
    end
    return false
end

function Utils.containsValueInTable(tableToRemoveFrom, value)
    for k, v in pairs(tableToRemoveFrom) do
        if v == value then
            return true
        end
    end
    return false
end

function Utils.removeFromTable(tableToRemoveFrom, value)
    for k, v in pairs(tableToRemoveFrom) do
        if v == value then
            table.remove(tableToRemoveFrom, k)
            return true
        end
    end
    return false
end

function Utils.toboolean(value)
    return not not value
end

function Utils.subStringCount(searchString, word, isCaseSensitive)
    if not isCaseSensitive then
        searchString = string.lower(searchString)
        word = string.lower(word)
    end
    local _, count = string.gsub(searchString, word, "")
    return count
end

function Utils.tablelength(tableToCheck)
  local length = 0
  for _ in pairs(tableToCheck) do length = length + 1 end
  return length
end