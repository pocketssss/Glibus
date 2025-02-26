-- _G.MemoryManager = { clear = clearLuaMemory }

local ffi = require("ffi")

ffi.cdef[[
    typedef unsigned int DWORD;
    DWORD GetProcessHeap();
    void* HeapAlloc(DWORD hHeap, DWORD dwFlags, size_t dwBytes);
    int HeapFree(DWORD hHeap, DWORD dwFlags, void* lpMem);
]]

local DEFAULT_MEMORY_KB = 768    
local MIN_MEMORY_KB = 256      
local MAX_MEMORY_KB = 960         
local CHECK_INTERVAL = 60        

local gcMemoryKB = math.Clamp(DEFAULT_MEMORY_KB, MIN_MEMORY_KB, MAX_MEMORY_KB)
local gcMemoryBytes = gcMemoryKB * 1024
local heap = ffi.C.GetProcessHeap()

local function log(level, message)
    print(string.format("[MEMORY][%s] %s", level, message))
end

local function clearLuaMemory()
    local currentMemoryKB = collectgarbage("count")
    local currentMemoryBytes = currentMemoryKB * 1024

    if currentMemoryBytes >= gcMemoryBytes then
        log("WARNING", string.format("Memory overflow: %.2fKB/%.2fKB", currentMemoryKB, gcMemoryKB))

        local memoryBlock = ffi.C.HeapAlloc(heap, 0, gcMemoryBytes)
        if memoryBlock == nil then
            log("ERROR", "HeapAlloc failed!")
            return
        end
        if ffi.C.HeapFree(heap, 0, memoryBlock) == 0 then
            log("ERROR", "HeapFree failed!")
            return
        end

        collectgarbage("collect")
        log("INFO", string.format("Memory cleaned. Current: %.2fKB", collectgarbage("count")))
    end
end

collectgarbage("setpause", 100)   
collectgarbage("setstepmul", 200)
timer.Create("MemoryManagerTimer", CHECK_INTERVAL, 0, function()
    local ok, err = pcall(clearLuaMemory)
    if not ok then
        log("CRITICAL", "GC error: " .. tostring(err))
    end
end)
