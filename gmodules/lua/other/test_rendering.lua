local function OptimizeRendering()
    render.PushFilterMag(16)
    render.PushFilterMin(16)

    render.EnableClipping(true)
    render.SetBlend(0)
end

local function ResetRendering()
    render.PopFilterMag()
    render.PopFilterMin() 

    render.EnableClipping(false) 
    render.SetBlend(1) 
end

hook.Add("InitPostEntity", "OptimizeGame", OptimizeRendering)
hook.Add("ShutDown", "ResetOptimizations", ResetRendering)
