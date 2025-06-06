-- Optimized Physics Library for Garry's Mod
-- High-performance tracing, collision detection, and physics operations

-- Cache frequently used functions
local util = util
local Vector, Angle = Vector, Angle
local math_huge = math.huge
local math_min, math_max = math.min, math.max
local table_insert = table.insert

-- Trace cache for repeated traces
local trace_cache = {}
local TRACE_CACHE_SIZE = 256
local trace_cache_count = 0

-- Pre-allocated trace structures to avoid garbage collection
local trace_pool = {}
local trace_pool_index = 0
local TRACE_POOL_SIZE = 64

-- Initialize trace pool
for i = 1, TRACE_POOL_SIZE do
    trace_pool[i] = {}
end

-- Get a trace structure from pool
local function get_trace_struct()
    trace_pool_index = trace_pool_index + 1
    if trace_pool_index > TRACE_POOL_SIZE then
        trace_pool_index = 1
    end
    
    local trace = trace_pool[trace_pool_index]
    -- Clear previous data
    for k in pairs(trace) do
        trace[k] = nil
    end
    
    return trace
end

-- Optimized trace line with caching
function physics.TraceLine(start_pos, end_pos, filter, mask)
    -- Create cache key
    local cache_key = string.format("%.1f,%.1f,%.1f-%.1f,%.1f,%.1f", 
        start_pos.x, start_pos.y, start_pos.z,
        end_pos.x, end_pos.y, end_pos.z)
    
    -- Check cache first
    if trace_cache[cache_key] then
        return trace_cache[cache_key]
    end
    
    -- Perform trace
    local trace_data = get_trace_struct()
    trace_data.start = start_pos
    trace_data.endpos = end_pos
    trace_data.filter = filter
    trace_data.mask = mask or MASK_SOLID
    
    local result = util.TraceLine(trace_data)
    
    -- Cache result if cache isn't full
    if trace_cache_count < TRACE_CACHE_SIZE then
        trace_cache[cache_key] = result
        trace_cache_count = trace_cache_count + 1
    end
    
    return result
end

-- Optimized hull trace
function physics.TraceHull(start_pos, end_pos, mins, maxs, filter, mask)
    local trace_data = get_trace_struct()
    trace_data.start = start_pos
    trace_data.endpos = end_pos
    trace_data.mins = mins
    trace_data.maxs = maxs
    trace_data.filter = filter
    trace_data.mask = mask or MASK_SOLID
    
    return util.TraceHull(trace_data)
end

-- Fast entity collision check
function physics.IsEntityColliding(ent1, ent2)
    if not IsValid(ent1) or not IsValid(ent2) then
        return false
    end
    
    local mins1, maxs1 = ent1:GetCollisionBounds()
    local mins2, maxs2 = ent2:GetCollisionBounds()
    local pos1, pos2 = ent1:GetPos(), ent2:GetPos()
    
    -- Transform bounds to world space
    mins1 = pos1 + mins1
    maxs1 = pos1 + maxs1
    mins2 = pos2 + mins2
    maxs2 = pos2 + maxs2
    
    -- AABB collision check
    return not (maxs1.x < mins2.x or mins1.x > maxs2.x or
                maxs1.y < mins2.y or mins1.y > maxs2.y or
                maxs1.z < mins2.z or mins1.z > maxs2.z)
end

-- Optimized sphere collision
function physics.SphereSphereCollision(pos1, radius1, pos2, radius2)
    local dx = pos1.x - pos2.x
    local dy = pos1.y - pos2.y
    local dz = pos1.z - pos2.z
    local distance_sqr = dx*dx + dy*dy + dz*dz
    local radius_sum = radius1 + radius2
    
    return distance_sqr <= radius_sum * radius_sum
end

-- Fast raycast with early termination
function physics.Raycast(start_pos, direction, max_distance, filter)
    local end_pos = start_pos + direction * max_distance
    return physics.TraceLine(start_pos, end_pos, filter)
end

-- Optimized entity finder in sphere
function physics.FindEntitiesInSphere(center, radius, filter_func)
    local entities = {}
    local radius_sqr = radius * radius
    
    for _, ent in ipairs(ents.GetAll()) do
        if IsValid(ent) then
            local distance_sqr = center:DistToSqr(ent:GetPos())
            if distance_sqr <= radius_sqr then
                if not filter_func or filter_func(ent) then
                    table_insert(entities, ent)
                end
            end
        end
    end
    
    return entities
end

-- Optimized entity finder in box
function physics.FindEntitiesInBox(mins, maxs, filter_func)
    local entities = {}
    
    for _, ent in ipairs(ents.GetAll()) do
        if IsValid(ent) then
            local pos = ent:GetPos()
            if pos.x >= mins.x and pos.x <= maxs.x and
               pos.y >= mins.y and pos.y <= maxs.y and
               pos.z >= mins.z and pos.z <= maxs.z then
                if not filter_func or filter_func(ent) then
                    table_insert(entities, ent)
                end
            end
        end
    end
    
    return entities
end

-- Physics object optimization
function physics.OptimizePhysicsObject(phys_obj)
    if not IsValid(phys_obj) then return end
    
    -- Reduce physics simulation quality for distant objects
    phys_obj:SetMaterial("gmod_silent")
    phys_obj:SetDamping(0.1, 0.1)
    phys_obj:EnableGravity(false)
    phys_obj:Sleep()
end

-- Batch physics operations
local physics_batch = {}
function physics.QueuePhysicsUpdate(ent, pos, ang, vel, ang_vel)
    table_insert(physics_batch, {
        entity = ent,
        position = pos,
        angle = ang,
        velocity = vel,
        angular_velocity = ang_vel
    })
end

function physics.FlushPhysicsBatch()
    for _, update in ipairs(physics_batch) do
        if IsValid(update.entity) then
            local phys = update.entity:GetPhysicsObject()
            if IsValid(phys) then
                if update.position then
                    phys:SetPos(update.position)
                end
                if update.angle then
                    phys:SetAngles(update.angle)
                end
                if update.velocity then
                    phys:SetVelocity(update.velocity)
                end
                if update.angular_velocity then
                    phys:SetAngleVelocity(update.angular_velocity)
                end
            end
        end
    end
    physics_batch = {}
end

-- Performance monitoring
local physics_stats = {
    traces_performed = 0,
    cache_hits = 0,
    entities_checked = 0
}

function physics.GetStats()
    return physics_stats
end

function physics.ResetStats()
    physics_stats = {
        traces_performed = 0,
        cache_hits = 0,
        entities_checked = 0
    }
end

-- Cleanup function
function physics.Cleanup()
    trace_cache = {}
    trace_cache_count = 0
    physics_batch = {}
end

-- Optimized ground check
function physics.IsOnGround(ent, tolerance)
    tolerance = tolerance or 2
    local pos = ent:GetPos()
    local mins, maxs = ent:GetCollisionBounds()
    
    local trace = physics.TraceLine(
        pos,
        pos + Vector(0, 0, -(maxs.z - mins.z + tolerance)),
        ent
    )
    
    return trace.Hit and trace.HitNormal.z > 0.7
end