local pairs = pairs
local setmetatable = setmetatable
local isstring = isstring
local isfunction = isfunction
local insert = table.insert
local HOOK_MONITOR_HIGH = -2
local HOOK_HIGH = -1
local HOOK_NORMAL = 0
local HOOK_LOW = 1
local events = {}

local function find_hook(event, name)
    return event[name]
end

local function copy_event(event, event_name)
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

        local event_hooks = events[event_name]
        if not event_hooks[hook_name] then
            event_hooks[hook_name] = {}
        end

        local hooks = event_hooks[hook_name]
        local pos = find_hook(hooks, hook_name)
        if not pos then
            insert(hooks, hook)
        else
            insert(hooks, pos, hook)
        end

        if hook_func ~= hooks[pos][1] then
            table.sort(hooks, hook_sort)
        end

        if hooks[pos][1](...) ~= nil then
            break
        end
    end
end

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
    
    priority = math.min(math.max(priority or HOOK_NORMAL, HOOK_MONITOR_HIGH), HOOK_MONITOR_LOW)
    if priority >= HOOK_MONITOR_HIGH and priority <= HOOK_MONITOR_LOW then
        func = function(...)
            func(...)
        end
    end
    
    local event = events[event_name] or {}
    events[event_name] = event
    
    local event_hooks = events[event_name]
    local hooks = event_hooks[name]
    if not hooks then
        hooks = {}
        event_hooks[name] = hooks
    end
    
    local pos = find_hook(hooks, name)
    if pos and hooks[pos + 3] ~= priority then
        Remove(event_name, name)
        pos = nil
    end
    
    if pos then
        hooks[pos + 1] = func
        hooks[pos + 2] = name
        hooks[pos + 3] = priority
    else
        local event_pos = 4
        for i = 4, #event, 4 do
            local _priority = event[i]
            if priority < _priority then
                event_pos = i
                break
            end
            
            event_pos = i + 4
        end
        
        insert(event, event_pos, priority)
        insert(event, event_pos, name)
        insert(event, event_pos, func)
        insert(event, event_pos, 1)
    end
end

function Remove(event_name, name)
    if not isstring(event_name) or not name then return end

    local event = events[event_name]
    if not event then return end

    local event_hooks = events[event_name]
    local hooks = event_hooks[name]
    if not hooks then return end

    local pos = find_hook(hooks, name)
    if not pos then return end

    local n = #event
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

    events[event_name] = copy_event(event, event_name)
end

function GetTable()
    local new_events = {}

    for event_name, event in pairs(events) do
        new_events[event_name] = {}
        for i = 1, #event, 4 do
            local name = event[i]
            if name then
                new_events[event_name][name] = event[i + 2]
            end
        end
    end

    return new_events
end

function Call(event_name, gm, max_return_values, ...)
    local event = events[event_name]
    if event then
        local i, n = 2, #event
        local results = {}
        local num_results = 0
        repeat
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
        until i > n
        if num_results > 0 then
            return unpack(results, 1, num_results)
        end
    end

    if not gm then return end

    local GamemodeFunction = gm[event_name]
    if not GamemodeFunction then return end

    return GamemodeFunction(gm, ...)
end

function Run(name, ...)
    return Call(name, gmod and gmod.GetGamemode() or nil, ...)
end