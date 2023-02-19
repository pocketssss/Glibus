-- https://github.com/Srlion/Hook-Library/blob/master/hook.lua
-- I daresay my hooks might work better, but that's just a theory
-- If you can check it, check it


local pairs = pairs
local setmetatable = setmetatable
local isstring = isstring
local isnumber = isnumber
local isfunction = isfunction
local insert = table.insert
local HOOK_MONITOR_HIGH = -2
local HOOK_HIGH = -1
local HOOK_NORMAL = 0
local HOOK_LOW = 1
local HOOK_MONITOR_LOW = 2
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

            -- if hook got removed then don't run it
            local pos = find_hook(parent, name)
            if not pos then return end

            -- if hook priority changed then it should be treated as a new hook, don't run it
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
                table.insert(events[event_name], hook)
            else
                table.insert(events[event_name], pos, hook)
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
        
        table.insert(event, event_pos, priority)
        table.insert(event, event_pos, name)
        table.insert(event, event_pos, func)
        table.insert(event, event_pos, 1)
        event.n = event.n + 4
    end
end

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

function GetTable()
	local new_events = {}

	-- preallocate hooks table with the expected number of items
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

function Call(event_name, gm, ...)
	local event = events[event_name]
	if event then
		local i, n = 2, event.n
		::loop::
		local func = event[i]
		if func then
			local a, b, c, d, e, f = func(...)
			if a ~= nil then
				return a, b, c, d, e, f
			end
		end
		i = i + 4
		if i <= n then
			goto loop
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

