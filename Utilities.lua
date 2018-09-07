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

function Utils.containsValueInTable(tableToCheck, value)
    for k, v in pairs(tableToCheck) do
        if v == value then
            return true
        end
    end
    return false
end

-- Checks table of structs for a struct that has the given key-value pair
-- if found: returns index of the struct, if NOT found: returns nil
function Utils.containsPairInStructsTable(tableToCheck, key, value)
    for index, struct in ipairs(tableToCheck) do
        if struct[key] == value then
            return index
        end
    end

    return nil
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

function Utils.containsWord(searchString, word, isCaseSensitive)
    if string.len(searchString) <= string.len(word) then
        return false
    end

    if not isCaseSensitive then
        searchString = string.lower(searchString)
        word = string.lower(word)
    end

    -- check if word is at the start of the string
    local startOfString = string.sub(searchString, 1, string.len(word) + 1)
    local _, count = string.gsub(startOfString, word .. " ", "")
    if count > 0 then
        return true
    end

    -- check if word is at the end of the string
    local endOfString = string.sub(searchString, string.len(searchString) - string.len(word))
    local _, count = string.gsub(endOfString, " " .. word, "")
    if count > 0 then
        return true
    end

    -- check if word is somewhere in the middle of the string
    local _, count = string.gsub(searchString, " " .. word .. " ", "")
    if count > 0 then
        return true
    end

    return false
end

function Utils.tablelength(tableToCheck)
  local length = 0
  for _ in pairs(tableToCheck) do length = length + 1 end
  return length
end

-- Split string every n characters, return number of newlines added and resulting string
function Utils.splitString(text, n)
    local result = {}
    local numLines = math.floor(string.len(text)/n) + 1
    for i = 1, numLines, 1
    do
        table.insert(result, string.sub(text, (i-1)*n + 1, i*n))
    end
    return result
end

function Utils.getTableLength(tableToCheck)
    local counter = 0
    for index in pairs(tableToCheck) do
        counter = counter + 1
    end
    return counter
end

function Utils.reverseTable(tableToReverse)
    local reversedTable = {}
    local itemCount = Utils.getTableLength(tableToReverse)
    for k, v in ipairs(tableToReverse) do
        reversedTable[itemCount + 1 - k] = v
    end
    return reversedTable
end
