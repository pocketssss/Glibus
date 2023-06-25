
local GarbageCollector = require("garbagecollector")

local GCObserver = {}

function GCObserver:new()
    local obj = {}
    setmetatable(obj, self)
    self.__index = self
    return obj
end

function GCObserver:Update()
    self:PerformGarbageCollection()
end

function GCObserver:PerformGarbageCollection()
    local gc = collectgarbage
    local SysTime = SysTime
    local limit, die = 1 / 300, 0

    while gc("step", 1) do
        if SysTime() > die then
            coroutine.yield()
        end
    end
end

local gc = GarbageCollector:new(60)
local observer = GCObserver:new()
gc:Attach(observer)
gc:Start()