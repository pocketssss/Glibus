local function OptimizeRendering()
    render.PushFilterMag(TEXFILTER.ANISOTROPIC) 
    render.PushFilterMin(TEXFILTER.ANISOTROPIC) 

    render.EnableClipping(true)
    render.SetBlend(0)
end

local function ResetRendering()
    render.PopFilterMag()
    render.PopFilterMin() 

    render.EnableClipping(false) 
    render.SetBlend(1) 
end

hook.Add("Initialize", "OptimizeGame", OptimizeRendering)
hook.Add("InitPostEntity", "OptimizeGame", OptimizeRendering)
hook.Add("ShutDown", "ResetOptimizations", ResetRendering)
hook.Add("PostCleanupMap", "ResetOptimizations", ResetRendering)
