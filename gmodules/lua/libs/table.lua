local getkeys, rand, pairs =
    table.GetKeys, math.random, pairs -- Some warmup(???)

local function table.Count(t)
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
    local n = table.Count(t)
    if n == 0 then return nil end 

    local rand_index = rand(1, n)
    local i = 1
    for _, v in pairs(t) do
        if i == rand_index then
            return v
        end
        i = i + 1
    end
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
