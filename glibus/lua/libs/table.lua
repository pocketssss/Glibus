-- local ffi = require("ffi") luaJIT
local getkeys, rand, pairs = table.GetKeys, math.random, pairs

-- local C = ffi.C
-- local rand = math.random

-- ffi.cdef[[
-- typedef struct { int count; } Table;
-- ]]

-- function Table.Count(t)
-- return t.count
-- end

-- function Table.Empty(t)
-- t.count = 0
-- end

function table.Count(t)
    local count = 0
    for _ in pairs(t) do
        count = count + 1
    end
    return count
end

function table.Empty(t)
    for k in pairs(t) do
        t[k] = nil
    end
end

function table.Random(t)
    local n = #t
    if n == 0 then return nil end 

    local rand_index = rand(1, n)
    return t[rand_index]
end

function table.Shuffle(tbl)
    local len = #tbl
    local rand
    local temp

    for i = len, 2, -1 do
        rand = rand(i)
        temp = tbl[i]
        tbl[i] = tbl[rand]
        tbl[rand] = temp
    end

    return tbl
end


function table.GetWinningKey(t)
    local max_val, max_key
    for k, v in pairs(t) do
        if not max_val or v > max_val then
            max_val = v
            max_key = k
        end
    end
    return max_key
end
