-- Cache frequently used functions for better performance
local pairs, next, math_random = pairs, next, math.random
local table_insert, table_remove = table.insert, table.remove

-- Optimized table.Count using next() which is faster than pairs()
function table.Count(t)
    local count = 0
    local k = next(t)
    while k ~= nil do
        count = count + 1
        k = next(t, k)
    end
    return count
end

function table.Empty(t)
    for k in pairs(t) do
        t[k] = nil
    end
end

-- Optimized table.Random with better performance
function table.Random(t)
    local n = #t
    if n == 0 then return nil end 

    local rand_index = math_random(1, n)
    return t[rand_index]
end

-- Fisher-Yates shuffle algorithm - optimized version
function table.Shuffle(tbl)
    local len = #tbl
    if len <= 1 then return tbl end
    
    for i = len, 2, -1 do
        local j = math_random(1, i)
        tbl[i], tbl[j] = tbl[j], tbl[i]  -- Swap without temp variable
    end

    return tbl
end

-- Optimized GetWinningKey with early exit and better logic
function table.GetWinningKey(t)
    local max_val, max_key = next(t)
    if not max_val then return nil end
    
    for k, v in next, t, max_key do
        if v > max_val then
            max_val = v
            max_key = k
        end
    end
    return max_key
end

-- Additional optimized utility functions
function table.Copy(t)
    local copy = {}
    for k, v in pairs(t) do
        copy[k] = v
    end
    return copy
end

function table.DeepCopy(t)
    if type(t) ~= "table" then return t end
    
    local copy = {}
    for k, v in pairs(t) do
        copy[k] = type(v) == "table" and table.DeepCopy(v) or v
    end
    return copy
end

-- Fast table merge (modifies first table)
function table.Merge(dest, src)
    for k, v in pairs(src) do
        dest[k] = v
    end
    return dest
end

-- Check if table is empty (faster than table.Count)
function table.IsEmpty(t)
    return next(t) == nil
end

-- Get table size for mixed tables (array + hash)
function table.Size(t)
    local count = 0
    for _ in pairs(t) do
        count = count + 1
    end
    return count
end
