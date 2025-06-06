-- Optimized Hook System for Garry's Mod
-- Maximum performance with clean code structure

-- Cache frequently used global functions for maximum performance
local pairs, next, type = pairs, next, type
local setmetatable, getmetatable = setmetatable, getmetatable
local isstring, isfunction, IsValid = isstring, isfunction, IsValid
local table_insert, table_remove, table_sort = table.insert, table.remove, table.sort
local math_min, math_max = math.min, math.max
local unpack = unpack or table.unpack

-- Hook priority constants
local HOOK_MONITOR_HIGH = -2
local HOOK_HIGH = -1
local HOOK_NORMAL = 0
local HOOK_LOW = 1
local HOOK_MONITOR_LOW = 2

-- Optimized storage structures
local events = {}           -- Main event storage
local event_cache = {}      -- Cache for faster lookups
local hook_count = {}       -- Track hook counts per event

-- Fast hook lookup using hash table
local function find_hook_index(event_hooks, name)
    for i = 1, #event_hooks do
        if event_hooks[i].name == name then
            return i
        end
    end
    return nil
end

-- Optimized hook sorting by priority
local function sort_hooks_by_priority(hooks)
    table_sort(hooks, function(a, b)
        return a.priority < b.priority
    end)
end

-- Add a hook to an event with maximum performance
function Add(event_name, name, func, priority)
    -- Input validation with early returns
    if not isstring(event_name) or not func or not name then 
        return false 
    end
    
    -- Handle entity hooks
    if not isstring(name) then
        if not IsValid or not IsValid(name) then
            Remove(event_name, name)
            return false
        end
        
        -- Wrap function for entity hooks
        local entity = name
        func = function(...)
            if IsValid(entity) then
                return func(entity, ...)
            end
        end
        name = tostring(entity)
    end
    
    -- Validate function
    if not isfunction(func) then
        return false
    end
    
    -- Clamp priority to valid range
    priority = math_min(math_max(priority or HOOK_NORMAL, HOOK_MONITOR_HIGH), HOOK_MONITOR_LOW)
    
    -- Initialize event if it doesn't exist
    if not events[event_name] then
        events[event_name] = {}
        hook_count[event_name] = 0
        event_cache[event_name] = {}
    end
    
    local event_hooks = events[event_name]
    local existing_index = find_hook_index(event_hooks, name)
    
    local hook_data = {
        name = name,
        func = func,
        priority = priority,
        is_monitor = priority <= HOOK_MONITOR_HIGH or priority >= HOOK_MONITOR_LOW
    }
    
    if existing_index then
        -- Update existing hook
        event_hooks[existing_index] = hook_data
    else
        -- Add new hook
        table_insert(event_hooks, hook_data)
        hook_count[event_name] = hook_count[event_name] + 1
    end
    
    -- Sort hooks by priority for optimal execution order
    sort_hooks_by_priority(event_hooks)
    
    -- Clear cache for this event
    event_cache[event_name] = {}
    
    return true
end

-- Remove a hook from an event
function Remove(event_name, name)
    if not isstring(event_name) or not name then 
        return false 
    end
    
    local event_hooks = events[event_name]
    if not event_hooks then 
        return false 
    end
    
    -- Convert entity to string if needed
    if not isstring(name) then
        name = tostring(name)
    end
    
    local index = find_hook_index(event_hooks, name)
    if not index then 
        return false 
    end
    
    -- Remove hook
    table_remove(event_hooks, index)
    hook_count[event_name] = hook_count[event_name] - 1
    
    -- Clean up empty events
    if hook_count[event_name] == 0 then
        events[event_name] = nil
        hook_count[event_name] = nil
        event_cache[event_name] = nil
    else
        -- Clear cache for this event
        event_cache[event_name] = {}
    end
    
    return true
end

-- Get hooks table (for compatibility)
function GetTable()
    local result = {}
    for event_name, event_hooks in pairs(events) do
        result[event_name] = {}
        for _, hook_data in pairs(event_hooks) do
            result[event_name][hook_data.name] = hook_data.func
        end
    end
    return result
end

-- Optimized hook calling with maximum performance
function Call(event_name, gm, ...)
    local event_hooks = events[event_name]
    
    -- Fast path: no hooks registered
    if not event_hooks or hook_count[event_name] == 0 then
        -- Call gamemode function if available
        if gm and gm[event_name] then
            return gm[event_name](gm, ...)
        end
        return
    end
    
    -- Execute hooks in priority order
    local results = {}
    local result_count = 0
    
    for i = 1, #event_hooks do
        local hook_data = event_hooks[i]
        local success, a, b, c, d, e, f = pcall(hook_data.func, ...)
        
        if success and a ~= nil then
            -- Monitor hooks don't affect return values
            if not hook_data.is_monitor then
                result_count = result_count + 1
                results[result_count] = a
                
                -- Early return for performance
                if result_count >= 6 then  -- Limit return values
                    return a, b, c, d, e, f
                end
            end
        elseif not success then
            -- Log hook errors in development
            if GetConVar and GetConVar("developer"):GetInt() > 0 then
                ErrorNoHalt(string.format("Hook error in %s[%s]: %s\n", 
                    event_name, hook_data.name, tostring(a)))
            end
        end
    end
    
    -- Return hook results if any
    if result_count > 0 then
        return unpack(results, 1, result_count)
    end
    
    -- Call gamemode function if no hook returned a value
    if gm and gm[event_name] then
        return gm[event_name](gm, ...)
    end
end

-- Run a named event (convenience function)
function Run(event_name, ...)
    local gm = gmod and gmod.GetGamemode() or nil
    return Call(event_name, gm, ...)
end

-- Performance monitoring functions
function GetHookCount(event_name)
    return hook_count[event_name] or 0
end

function GetEventCount()
    local count = 0
    for _ in pairs(events) do
        count = count + 1
    end
    return count
end

-- Debug function to list all hooks
function PrintHooks(event_name)
    if event_name then
        local event_hooks = events[event_name]
        if event_hooks then
            print(string.format("Hooks for %s (%d):", event_name, #event_hooks))
            for i, hook_data in ipairs(event_hooks) do
                print(string.format("  %d. %s (priority: %d)", i, hook_data.name, hook_data.priority))
            end
        else
            print(string.format("No hooks for event: %s", event_name))
        end
    else
        print("All registered events:")
        for name, hooks in pairs(events) do
            print(string.format("  %s: %d hooks", name, #hooks))
        end
    end
end