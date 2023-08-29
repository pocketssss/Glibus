-- Cache frequently used global functions
local cached_functions = {
    pairs = pairs,
    setmetatable = setmetatable,
    isstring = isstring,
    isfunction = isfunction,
    table_insert = table.insert,
    math_min = math.min,
    math_max = math.max
}
local pairs = cached_functions.pairs
local setmetatable = cached_functions.setmetatable
local isstring = cached_functions.isstring
local isfunction = cached_functions.isfunction
local table_insert = cached_functions.table_insert
local math_min = cached_functions.math_min
local math_max = cached_functions.math_max

-- Define hook priorities
local HOOK_MONITOR_HIGH = -2
local HOOK_HIGH = -1
local HOOK_NORMAL = 0
local HOOK_LOW = 1
local HOOK_MONITOR_LOW = 2

-- Store events and hooks
local events = {}

-- Find a hook in an event
local function find_hook(event, name)
    return event[name]
end

-- Copy an event with modified behavior
local function copy_event(event, event_name, ...)
    local new_event = {}

    for k, v in pairs(event) do
        new_event[k] = v
    end

    setmetatable(event, {
        __index = function(_, key)
            local name = new_event[key - 1]
            if not name then return end

            local parent = events[event_name]
            local pos = find_hook(parent, name)
            if not pos then return end

            if parent[name][3] ~= new_event[key + 2] then return end

            return parent[name][1]
        end
    })

    for i = 1, #new_event, 3 do
        local hook_name, hook_func, hook_priority = new_event[i], new_event[i + 1], new_event[i + 2]

        local hook = {hook_func, hook_name, hook_priority}

        if not event[hook_name] then
            event[hook_name] = hook
        else
            local pos = find_hook(events[event_name], hook_name)
            if not pos then
                table_insert(events[event_name], hook)
            else
                table_insert(events[event_name], pos, hook)
            end
        end

        if hook_func ~= event[hook_name][1] then
            table.sort(events[event_name], hook_sort)
        end

        if event[hook_name][1](...) ~= nil then
            break
        end
    end
end 

-- Add a hook to an event
function Add(event_name, name, func, priority)
    if not isstring(event_name) or not isfunction(func) or not name then return end
    
    if not isstring(name) then
        local isvalid = name.IsValid
        if not isvalid or not isvalid(name) then
            Remove(event_name, name)
            return
        end

        func = function(...)
            return func(name, ...)
        end
    end
    
    priority = math_min(math_max(priority or HOOK_NORMAL, HOOK_MONITOR_HIGH), HOOK_MONITOR_LOW)
    if priority >= HOOK_MONITOR_HIGH and priority <= HOOK_MONITOR_LOW then
        func = function(...)
            func(...)
        end
    end
    
    local event = events[event_name] or {n = 0}
    
    local pos = find_hook(event, name)
    if pos and event[pos + 3] ~= priority then
        Remove(event_name, name)
        pos = nil
    end
    
    if pos then
        event[pos + 1] = func
        event[pos + 2] = name
        event[pos + 3] = priority
    else
        local event_pos = 4
        for i = 4, event.n, 4 do
            local _priority = event[i]
            if priority < _priority then
                event_pos = i
                break
            end
            
            event_pos = i + 4
        end
        
        table_insert(event, event_pos, priority)
        table_insert(event, event_pos, name)
        table_insert(event, event_pos, func)
        table_insert(event, event_pos, 1)
        event.n = event.n + 4
    end
end

-- Remove a hook from an event
function Remove(event_name, name)
    if not isstring(event_name) or not name then return end

    local event = events[event_name]
    if not event then return end

    local pos = find_hook(event, name)
    if not pos then return end

    local n = event.n
    for i = pos, n - 4, 4 do
        event[i] = event[i + 4]
        event[i + 1] = event[i + 5]
        event[i + 2] = event[i + 6]
        event[i + 3] = event[i + 7]
    end

    event[n] = nil
    event[n - 1] = nil
    event[n - 2] = nil
    event[n - 3] = nil
    event.n = n - 4

    events[event_name] = copy_event(event, event_name)
end

-- Get a table of events and hooks
function GetTable()
    local new_events = {}
    for event_name, event in next, events, nil do
        new_events[event_name] = {}
        for i = 1, event.n, 4 do
            local name = event[i]
            if name then
                new_events[event_name][name] = event[i + 2] --[[real_func]]
            end
        end
    end

    return new_events
end

-- Call hooks and gamemode function
function Call(event_name, gm, max_return_values, ...)
    local event = events[event_name]
    if event then
        local i, n = 2, event.n
        local results = {}
        local num_results = 0
        ::loop::
        local func = event[i]
        if func then
            local a, b, c, d, e, f = func(...)
            if a ~= nil then
                num_results = num_results + 1
                results[num_results] = a
                if num_results == max_return_values then
                    return unpack(results, 1, max_return_values)
                end
            end
        end
        i = i + 4
        if i <= n then
            goto loop
        end
        if num_results > 0 then
            return unpack(results, 1, num_results)
        end
    end

    -- Call the gamemode function
    if not gm then return end

    local GamemodeFunction = gm[event_name]
    if not GamemodeFunction then return end

    return GamemodeFunction(gm, ...)
end

-- Run a named event
function Run(name, ...)
    return Call(name, gmod and gmod.GetGamemode() or nil, ...)
end
