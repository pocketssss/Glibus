-- Advanced Memory Management System for Garry's Mod
-- Intelligent garbage collection and memory optimization

local ffi = require("ffi")

ffi.cdef[[
    typedef unsigned int DWORD;
    typedef unsigned long long SIZE_T;
    DWORD GetProcessHeap();
    void* HeapAlloc(DWORD hHeap, DWORD dwFlags, SIZE_T dwBytes);
    int HeapFree(DWORD hHeap, DWORD dwFlags, void* lpMem);
    int GetProcessMemoryInfo(void* hProcess, void* ppsmemCounters, DWORD cb);
    void* GetCurrentProcess();
]]

-- Configuration
local DEFAULT_MEMORY_KB = 1024
local MIN_MEMORY_KB = 512
local MAX_MEMORY_KB = 2048
local CHECK_INTERVAL = 30
local AGGRESSIVE_CLEANUP_THRESHOLD = 0.85
local CRITICAL_MEMORY_THRESHOLD = 0.95

-- Memory statistics
local memory_stats = {
    total_cleanups = 0,
    bytes_freed = 0,
    peak_usage = 0,
    average_usage = 0,
    cleanup_times = {}
}

-- Object pools for reuse
local object_pools = {
    vectors = {},
    angles = {},
    colors = {},
    tables = {}
}

local gcMemoryKB = math.Clamp(DEFAULT_MEMORY_KB, MIN_MEMORY_KB, MAX_MEMORY_KB)
local gcMemoryBytes = gcMemoryKB * 1024
local heap = ffi.C.GetProcessHeap()

-- Logging with levels
local LOG_LEVELS = {
    DEBUG = 0,
    INFO = 1,
    WARNING = 2,
    ERROR = 3,
    CRITICAL = 4
}

local current_log_level = LOG_LEVELS.INFO

local function log(level, message)
    if LOG_LEVELS[level] >= current_log_level then
        local timestamp = os.date("%H:%M:%S")
        print(string.format("[%s][MEMORY][%s] %s", timestamp, level, message))
    end
end

-- Advanced memory monitoring
local function getMemoryUsage()
    local lua_memory = collectgarbage("count")
    memory_stats.peak_usage = math.max(memory_stats.peak_usage, lua_memory)
    return lua_memory
end

-- Intelligent garbage collection
local function smartGarbageCollection()
    local start_time = SysTime()
    local before_memory = getMemoryUsage()
    
    -- Incremental collection first
    collectgarbage("step", 1000)
    
    local after_incremental = getMemoryUsage()
    local freed_incremental = before_memory - after_incremental
    
    -- Full collection if incremental didn't free enough
    if freed_incremental < 50 then -- Less than 50KB freed
        collectgarbage("collect")
    end
    
    local after_memory = getMemoryUsage()
    local total_freed = before_memory - after_memory
    local cleanup_time = SysTime() - start_time
    
    -- Update statistics
    memory_stats.total_cleanups = memory_stats.total_cleanups + 1
    memory_stats.bytes_freed = memory_stats.bytes_freed + (total_freed * 1024)
    table.insert(memory_stats.cleanup_times, cleanup_time)
    
    -- Keep only last 10 cleanup times
    if #memory_stats.cleanup_times > 10 then
        table.remove(memory_stats.cleanup_times, 1)
    end
    
    log("INFO", string.format("GC: %.2fKB -> %.2fKB (freed %.2fKB in %.3fs)", 
        before_memory, after_memory, total_freed, cleanup_time))
    
    return total_freed
end

-- Object pool management
function memory.GetVector(x, y, z)
    local vector = table.remove(object_pools.vectors)
    if vector then
        vector.x, vector.y, vector.z = x or 0, y or 0, z or 0
        return vector
    end
    return Vector(x or 0, y or 0, z or 0)
end

function memory.ReturnVector(vector)
    if #object_pools.vectors < 100 then
        table.insert(object_pools.vectors, vector)
    end
end

function memory.GetAngle(p, y, r)
    local angle = table.remove(object_pools.angles)
    if angle then
        angle.p, angle.y, angle.r = p or 0, y or 0, r or 0
        return angle
    end
    return Angle(p or 0, y or 0, r or 0)
end

function memory.ReturnAngle(angle)
    if #object_pools.angles < 100 then
        table.insert(object_pools.angles, angle)
    end
end

function memory.GetTable()
    local tbl = table.remove(object_pools.tables)
    if tbl then
        table.Empty(tbl)
        return tbl
    end
    return {}
end

function memory.ReturnTable(tbl)
    if #object_pools.tables < 50 then
        table.insert(object_pools.tables, tbl)
    end
end

-- Advanced memory cleanup
local function advancedMemoryCleanup()
    local current_memory = getMemoryUsage()
    local memory_ratio = current_memory / gcMemoryKB
    
    if memory_ratio >= CRITICAL_MEMORY_THRESHOLD then
        log("CRITICAL", string.format("Critical memory usage: %.1f%%", memory_ratio * 100))
        
        -- Emergency cleanup
        collectgarbage("collect")
        collectgarbage("collect") -- Double collection for critical situations
        
        -- Clear all caches
        if render and render.Cleanup then render.Cleanup() end
        if physics and physics.Cleanup then physics.Cleanup() end
        
        -- Force heap cleanup
        local memoryBlock = ffi.C.HeapAlloc(heap, 0, gcMemoryBytes)
        if memoryBlock ~= nil then
            ffi.C.HeapFree(heap, 0, memoryBlock)
        end
        
    elseif memory_ratio >= AGGRESSIVE_CLEANUP_THRESHOLD then
        log("WARNING", string.format("High memory usage: %.1f%%", memory_ratio * 100))
        smartGarbageCollection()
        
    elseif current_memory >= gcMemoryKB then
        smartGarbageCollection()
    end
end

-- Memory profiling
function memory.StartProfiling()
    memory_stats.profiling_start = SysTime()
    memory_stats.profiling_start_memory = getMemoryUsage()
end

function memory.EndProfiling(operation_name)
    if not memory_stats.profiling_start then return end
    
    local duration = SysTime() - memory_stats.profiling_start
    local memory_used = getMemoryUsage() - memory_stats.profiling_start_memory
    
    log("DEBUG", string.format("Profile [%s]: %.3fs, %.2fKB", 
        operation_name or "Unknown", duration, memory_used))
    
    memory_stats.profiling_start = nil
    memory_stats.profiling_start_memory = nil
end

-- Get memory statistics
function memory.GetStats()
    local current_memory = getMemoryUsage()
    local avg_cleanup_time = 0
    
    if #memory_stats.cleanup_times > 0 then
        local total_time = 0
        for _, time in ipairs(memory_stats.cleanup_times) do
            total_time = total_time + time
        end
        avg_cleanup_time = total_time / #memory_stats.cleanup_times
    end
    
    return {
        current_usage_kb = current_memory,
        peak_usage_kb = memory_stats.peak_usage,
        limit_kb = gcMemoryKB,
        usage_percentage = (current_memory / gcMemoryKB) * 100,
        total_cleanups = memory_stats.total_cleanups,
        bytes_freed = memory_stats.bytes_freed,
        average_cleanup_time = avg_cleanup_time,
        pool_sizes = {
            vectors = #object_pools.vectors,
            angles = #object_pools.angles,
            tables = #object_pools.tables
        }
    }
end

-- Set memory limit
function memory.SetLimit(kb)
    gcMemoryKB = math.Clamp(kb, MIN_MEMORY_KB, MAX_MEMORY_KB)
    gcMemoryBytes = gcMemoryKB * 1024
    log("INFO", string.format("Memory limit set to %dKB", gcMemoryKB))
end

-- Force cleanup
function memory.ForceCleanup()
    log("INFO", "Forcing memory cleanup...")
    return smartGarbageCollection()
end

-- Configure garbage collector for optimal performance
collectgarbage("setpause", 110)    -- Start GC when memory grows 10% 
collectgarbage("setstepmul", 300)  -- More aggressive stepping

-- Main memory management timer
timer.Create("AdvancedMemoryManager", CHECK_INTERVAL, 0, function()
    local success, error_msg = pcall(advancedMemoryCleanup)
    if not success then
        log("CRITICAL", "Memory manager error: " .. tostring(error_msg))
    end
end)

-- Export global memory manager
_G.MemoryManager = {
    cleanup = memory.ForceCleanup,
    stats = memory.GetStats,
    setLimit = memory.SetLimit,
    getVector = memory.GetVector,
    returnVector = memory.ReturnVector,
    getAngle = memory.GetAngle,
    returnAngle = memory.ReturnAngle,
    getTable = memory.GetTable,
    returnTable = memory.ReturnTable
}

log("INFO", string.format("Advanced Memory Manager initialized (Limit: %dKB)", gcMemoryKB))
