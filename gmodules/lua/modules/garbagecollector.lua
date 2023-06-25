local GarbageCollector = {}

function GarbageCollector:new(interval)
    local obj = {
        interval = interval,
        observers = {}
    }
    setmetatable(obj, self)
    self.__index = self
    return obj
end

function GarbageCollector:Attach(observer)
    table.insert(self.observers, observer)
end

function GarbageCollector:Detach(observer)
    for i, obs in ipairs(self.observers) do
        if obs == observer then
            table.remove(self.observers, i)
            break
        end
    end
end

function GarbageCollector:Notify()
    for _, observer in ipairs(self.observers) do
        observer:Update()
    end
end

function GarbageCollector:Start()
    self.timer = timer.Create("GarbageCollector", self.interval, 0, function()
        self:Notify()
    end)
end

function GarbageCollector:Stop()
    timer.Remove("GarbageCollector")
end

return GarbageCollector