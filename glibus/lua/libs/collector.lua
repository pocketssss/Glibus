local ffi = require("ffi")
ffi.cdef[[
    typedef unsigned int DWORD;
    DWORD GetProcessHeap();
    void* HeapAlloc(DWORD hHeap, DWORD dwFlags, size_t dwBytes);
    int HeapFree(DWORD hHeap, DWORD dwFlags, void* lpMem);
]]

local _clamp = math.Clamp
local gcMemoryKB = _clamp(768432, 256, 960)
local gcMemoryBytes = gcMemoryKB * 1024
local heap = ffi.C.GetProcessHeap()

local function clearLuaMemory()
    local currentMemory = collectgarbage("count")
    if currentMemory >= gcMemoryBytes then
        local memoryBlock = ffi.C.HeapAlloc(heap, 0, gcMemoryBytes)
        ffi.C.HeapFree(heap, 0, memoryBlock)
    end
end

timer.Create("gcLoopTimer", 60, 0, clearLuaMemory)
