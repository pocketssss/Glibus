-- Advanced Entity Management System for Garry's Mod
-- Optimized entity updates, culling, and performance monitoring

-- Cache frequently used functions
local ents = ents
local IsValid = IsValid
local CurTime = CurTime
local math_min, math_max = math.min, math.max
local table_insert, table_remove = table.insert, table.remove

-- Configuration
local UPDATE_INTERVAL = 0.1
local DISTANCE_CULLING_ENABLED = true
local MAX_VISIBLE_DISTANCE = 4096
local LOD_DISTANCES = {
    HIGH = 512,
    MEDIUM = 1024,
    LOW = 2048
}

-- Entity management
local managed_entities = {}
local entity_updates = {}
local entity_lod_levels = {}
local entity_last_update = {}

-- Performance monitoring
local entity_stats = {
    total_entities = 0,
    active_entities = 0,
    culled_entities = 0,
    update_time = 0,
    lod_changes = 0
}

-- LOD (Level of Detail) system
local LOD_LEVELS = {
    DISABLED = 0,
    LOW = 1,
    MEDIUM = 2,
    HIGH = 3
}

-- Entity categories for different update frequencies
local ENTITY_CATEGORIES = {
    STATIC = 1,      -- Never moves (props, etc.)
    SLOW = 2,        -- Rarely moves (doors, etc.)
    NORMAL = 3,      -- Regular entities
    FAST = 4,        -- Fast moving entities (vehicles, etc.)
    CRITICAL = 5     -- Always update (players, etc.)
}

local category_intervals = {
    [ENTITY_CATEGORIES.STATIC] = 5.0,
    [ENTITY_CATEGORIES.SLOW] = 1.0,
    [ENTITY_CATEGORIES.NORMAL] = 0.1,
    [ENTITY_CATEGORIES.FAST] = 0.05,
    [ENTITY_CATEGORIES.CRITICAL] = 0.01
}

-- Register entity for management
function entity_manager.Register(ent, category, custom_update_func)
    if not IsValid(ent) then return false end
    
    local ent_id = ent:EntIndex()
    category = category or ENTITY_CATEGORIES.NORMAL
    
    managed_entities[ent_id] = {
        entity = ent,
        category = category,
        update_func = custom_update_func,
        last_position = ent:GetPos(),
        last_angle = ent:GetAngles(),
        movement_speed = 0,
        is_visible = true,
        lod_level = LOD_LEVELS.HIGH
    }
    
    entity_last_update[ent_id] = CurTime()
    entity_lod_levels[ent_id] = LOD_LEVELS.HIGH
    
    return true
end

-- Unregister entity
function entity_manager.Unregister(ent)
    if not IsValid(ent) then return false end
    
    local ent_id = ent:EntIndex()
    managed_entities[ent_id] = nil
    entity_last_update[ent_id] = nil
    entity_lod_levels[ent_id] = nil
    
    return true
end

-- Calculate LOD level based on distance and importance
local function calculateLOD(ent, observer_pos)
    local distance = ent:GetPos():Distance(observer_pos)
    
    if distance <= LOD_DISTANCES.HIGH then
        return LOD_LEVELS.HIGH
    elseif distance <= LOD_DISTANCES.MEDIUM then
        return LOD_LEVELS.MEDIUM
    elseif distance <= LOD_DISTANCES.LOW then
        return LOD_LEVELS.LOW
    else
        return LOD_LEVELS.DISABLED
    end
end

-- Check if entity should be culled
local function shouldCullEntity(ent, observer_pos)
    if not DISTANCE_CULLING_ENABLED then return false end
    
    local distance = ent:GetPos():Distance(observer_pos)
    return distance > MAX_VISIBLE_DISTANCE
end

-- Update entity movement tracking
local function updateMovementTracking(ent_data)
    local ent = ent_data.entity
    local current_pos = ent:GetPos()
    local current_ang = ent:GetAngles()
    
    local pos_diff = current_pos:Distance(ent_data.last_position)
    local ang_diff = math.abs(current_ang.y - ent_data.last_angle.y)
    
    ent_data.movement_speed = pos_diff + ang_diff
    ent_data.last_position = current_pos
    ent_data.last_angle = current_ang
    
    -- Auto-adjust category based on movement
    if ent_data.movement_speed > 100 then
        ent_data.category = ENTITY_CATEGORIES.FAST
    elseif ent_data.movement_speed > 10 then
        ent_data.category = ENTITY_CATEGORIES.NORMAL
    elseif ent_data.movement_speed > 1 then
        ent_data.category = ENTITY_CATEGORIES.SLOW
    else
        ent_data.category = ENTITY_CATEGORIES.STATIC
    end
end

-- Main entity update loop
local function updateEntities()
    local start_time = SysTime()
    local current_time = CurTime()
    local observer_pos = LocalPlayer() and LocalPlayer():GetPos() or Vector(0, 0, 0)
    
    local total_count = 0
    local active_count = 0
    local culled_count = 0
    local lod_changes = 0
    
    for ent_id, ent_data in pairs(managed_entities) do
        total_count = total_count + 1
        
        local ent = ent_data.entity
        if not IsValid(ent) then
            managed_entities[ent_id] = nil
            goto continue
        end
        
        -- Check update interval for this category
        local update_interval = category_intervals[ent_data.category]
        if current_time - entity_last_update[ent_id] < update_interval then
            goto continue
        end
        
        entity_last_update[ent_id] = current_time
        
        -- Distance culling
        if shouldCullEntity(ent, observer_pos) then
            ent_data.is_visible = false
            culled_count = culled_count + 1
            goto continue
        end
        
        ent_data.is_visible = true
        active_count = active_count + 1
        
        -- LOD calculation
        local new_lod = calculateLOD(ent, observer_pos)
        if new_lod ~= ent_data.lod_level then
            ent_data.lod_level = new_lod
            entity_lod_levels[ent_id] = new_lod
            lod_changes = lod_changes + 1
        end
        
        -- Movement tracking
        updateMovementTracking(ent_data)
        
        -- Custom update function
        if ent_data.update_func then
            local success, error_msg = pcall(ent_data.update_func, ent, ent_data)
            if not success then
                ErrorNoHalt("Entity update error: " .. tostring(error_msg))
            end
        end
        
        ::continue::
    end
    
    -- Update statistics
    entity_stats.total_entities = total_count
    entity_stats.active_entities = active_count
    entity_stats.culled_entities = culled_count
    entity_stats.update_time = SysTime() - start_time
    entity_stats.lod_changes = lod_changes
end

-- Get entity LOD level
function entity_manager.GetLOD(ent)
    if not IsValid(ent) then return LOD_LEVELS.DISABLED end
    return entity_lod_levels[ent:EntIndex()] or LOD_LEVELS.HIGH
end

-- Set entity category
function entity_manager.SetCategory(ent, category)
    if not IsValid(ent) then return false end
    
    local ent_id = ent:EntIndex()
    if managed_entities[ent_id] then
        managed_entities[ent_id].category = category
        return true
    end
    
    return false
end

-- Get entity visibility
function entity_manager.IsVisible(ent)
    if not IsValid(ent) then return false end
    
    local ent_data = managed_entities[ent:EntIndex()]
    return ent_data and ent_data.is_visible or true
end

-- Batch entity operations
function entity_manager.BatchOperation(entities, operation)
    local results = {}
    
    for _, ent in ipairs(entities) do
        if IsValid(ent) then
            local success, result = pcall(operation, ent)
            if success then
                table_insert(results, result)
            end
        end
    end
    
    return results
end

-- Find entities by category
function entity_manager.FindByCategory(category)
    local entities = {}
    
    for _, ent_data in pairs(managed_entities) do
        if ent_data.category == category and IsValid(ent_data.entity) then
            table_insert(entities, ent_data.entity)
        end
    end
    
    return entities
end

-- Find entities in radius with LOD consideration
function entity_manager.FindInRadius(center, radius, min_lod)
    local entities = {}
    min_lod = min_lod or LOD_LEVELS.DISABLED
    
    for ent_id, ent_data in pairs(managed_entities) do
        if IsValid(ent_data.entity) and ent_data.lod_level >= min_lod then
            local distance = ent_data.entity:GetPos():Distance(center)
            if distance <= radius then
                table_insert(entities, ent_data.entity)
            end
        end
    end
    
    return entities
end

-- Performance optimization functions
function entity_manager.OptimizeAll()
    for ent_id, ent_data in pairs(managed_entities) do
        local ent = ent_data.entity
        if IsValid(ent) then
            -- Disable unnecessary features for distant entities
            if ent_data.lod_level <= LOD_LEVELS.LOW then
                if ent.SetRenderMode then
                    ent:SetRenderMode(RENDERMODE_TRANSCOLOR)
                end
                if ent.SetLOD then
                    ent:SetLOD(1)
                end
            end
        end
    end
end

-- Get performance statistics
function entity_manager.GetStats()
    return {
        total_entities = entity_stats.total_entities,
        active_entities = entity_stats.active_entities,
        culled_entities = entity_stats.culled_entities,
        update_time_ms = entity_stats.update_time * 1000,
        lod_changes = entity_stats.lod_changes,
        managed_count = table.Count(managed_entities)
    }
end

-- Configuration functions
function entity_manager.SetCullingDistance(distance)
    MAX_VISIBLE_DISTANCE = distance
end

function entity_manager.SetLODDistances(high, medium, low)
    LOD_DISTANCES.HIGH = high or LOD_DISTANCES.HIGH
    LOD_DISTANCES.MEDIUM = medium or LOD_DISTANCES.MEDIUM
    LOD_DISTANCES.LOW = low or LOD_DISTANCES.LOW
end

function entity_manager.EnableDistanceCulling(enabled)
    DISTANCE_CULLING_ENABLED = enabled
end

-- Cleanup function
function entity_manager.Cleanup()
    managed_entities = {}
    entity_updates = {}
    entity_lod_levels = {}
    entity_last_update = {}
end

-- Auto-register common entity types
hook.Add("OnEntityCreated", "EntityManagerAutoRegister", function(ent)
    timer.Simple(0.1, function()
        if IsValid(ent) then
            local class = ent:GetClass()
            
            -- Auto-categorize based on entity class
            local category = ENTITY_CATEGORIES.NORMAL
            
            if string.find(class, "prop_") then
                category = ENTITY_CATEGORIES.STATIC
            elseif string.find(class, "door") then
                category = ENTITY_CATEGORIES.SLOW
            elseif string.find(class, "vehicle") then
                category = ENTITY_CATEGORIES.FAST
            elseif ent:IsPlayer() then
                category = ENTITY_CATEGORIES.CRITICAL
            end
            
            entity_manager.Register(ent, category)
        end
    end)
end)

-- Main update timer
timer.Create("EntityManagerUpdate", UPDATE_INTERVAL, 0, updateEntities)

-- Export global entity manager
_G.EntityManager = entity_manager