--------------------------------------------------------------------
-- Runs ONCE per realm. Never re-run: re-including hook.lua would
-- recreate its event storage and wipe all registered hooks.
--------------------------------------------------------------------

local FILES = {
    "libs/hook.lua",
    "libs/math.lua",
    "libs/vector.lua",
    "libs/color.lua",
}

local function log(fmt, ...)
    print("[lib] " .. string.format(fmt, ...))
end

local t0 = SysTime()
local failed = 0
local pre_existing = hook.GetTable()

for i = 1, #FILES do
    local path = FILES[i]

    if not file.Exists(path, "LUA") then
        failed = failed + 1
        log("[FAIL] %s: file not found", path)
    else
        if SERVER then AddCSLuaFile(path) end

        local ok, err = pcall(include, path)
        if not ok then
            failed = failed + 1
            log("[FAIL] %s: %s", path, tostring(err))
        end

        if path == "glibus/hook.lua" and ok then
            local migrated = 0
            for event, hooks in pairs(pre_existing) do
                for name, fn in pairs(hooks) do
                    hook.Add(event, name, fn)
                    migrated = migrated + 1
                end
            end
            if migrated > 0 then
                log("migrated %d pre-existing hooks", migrated)
            end
        end
    end
end

log("loaded %d/%d in %.1f ms", #FILES - failed, #FILES, (SysTime() - t0) * 1000)
