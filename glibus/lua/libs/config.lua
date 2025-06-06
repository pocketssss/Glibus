-- Glibus Configuration System
-- Centralized configuration for all optimization modules

-- Default configuration
local default_config = {
    -- Memory Management
    memory = {
        enabled = true,
        limit_kb = 1024,
        check_interval = 30,
        aggressive_threshold = 0.85,
        critical_threshold = 0.95,
        object_pooling = true,
        log_level = "INFO"
    },
    
    -- Rendering Optimization
    rendering = {
        enabled = true,
        material_cache_size = 128,
        color_cache_size = 64,
        text_cache_enabled = true,
        batch_rendering = true,
        lod_enabled = true
    },
    
    -- Physics Optimization
    physics = {
        enabled = true,
        trace_cache_size = 256,
        collision_optimization = true,
        distance_culling = true,
        max_trace_distance = 4096,
        batch_physics_updates = true
    },
    
    -- Networking Optimization
    networking = {
        enabled = true,
        compression_enabled = true,
        compression_threshold = 512,
        rate_limiting = true,
        max_packets_per_second = 100,
        reliable_messaging = true,
        batch_messages = true
    },
    
    -- Entity Management
    entities = {
        enabled = true,
        auto_register = true,
        distance_culling = true,
        max_visible_distance = 4096,
        lod_distances = {
            high = 512,
            medium = 1024,
            low = 2048
        },
        update_intervals = {
            static = 5.0,
            slow = 1.0,
            normal = 0.1,
            fast = 0.05,
            critical = 0.01
        }
    },
    
    -- Database Optimization
    database = {
        enabled = true,
        cache_size = 1000,
        batch_size = 100,
        auto_vacuum = true,
        query_timeout = 10,
        log_queries = false
    },
    
    -- Hook System
    hooks = {
        enabled = true,
        use_optimized = true,
        performance_monitoring = true,
        error_handling = true,
        priority_sorting = true
    },
    
    -- Performance Monitoring
    monitoring = {
        enabled = true,
        fps_monitoring = true,
        memory_monitoring = true,
        network_monitoring = true,
        entity_monitoring = true,
        log_performance = true,
        alert_thresholds = {
            fps_low = 30,
            memory_high = 0.9,
            network_high = 1000000 -- bytes per second
        }
    }
}

-- Current configuration (starts with defaults)
local current_config = table.Copy(default_config)

-- Configuration API
local config = {}

-- Get configuration value
function config.Get(path, default_value)
    local keys = string.Split(path, ".")
    local value = current_config
    
    for _, key in ipairs(keys) do
        if type(value) == "table" and value[key] ~= nil then
            value = value[key]
        else
            return default_value
        end
    end
    
    return value
end

-- Set configuration value
function config.Set(path, value)
    local keys = string.Split(path, ".")
    local target = current_config
    
    -- Navigate to parent
    for i = 1, #keys - 1 do
        local key = keys[i]
        if type(target[key]) ~= "table" then
            target[key] = {}
        end
        target = target[key]
    end
    
    -- Set final value
    target[keys[#keys]] = value
    
    -- Save configuration
    config.Save()
    
    return true
end

-- Get entire configuration section
function config.GetSection(section)
    return current_config[section] or {}
end

-- Set entire configuration section
function config.SetSection(section, values)
    current_config[section] = values
    config.Save()
end

-- Reset to defaults
function config.Reset(section)
    if section then
        current_config[section] = table.Copy(default_config[section])
    else
        current_config = table.Copy(default_config)
    end
    config.Save()
end

-- Load configuration from file
function config.Load()
    if not file.Exists("glibus_config.json", "DATA") then
        config.Save() -- Create default config file
        return true
    end
    
    local config_data = file.Read("glibus_config.json", "DATA")
    if not config_data then
        return false
    end
    
    local loaded_config = util.JSONToTable(config_data)
    if not loaded_config then
        return false
    end
    
    -- Merge with defaults to ensure all keys exist
    current_config = table.Merge(table.Copy(default_config), loaded_config)
    
    return true
end

-- Save configuration to file
function config.Save()
    local config_json = util.TableToJSON(current_config, true)
    if not config_json then
        return false
    end
    
    file.Write("glibus_config.json", config_json)
    return true
end

-- Validate configuration
function config.Validate()
    local errors = {}
    
    -- Memory validation
    local memory_limit = config.Get("memory.limit_kb")
    if memory_limit < 256 or memory_limit > 4096 then
        table.insert(errors, "memory.limit_kb must be between 256 and 4096")
    end
    
    -- Rendering validation
    local material_cache = config.Get("rendering.material_cache_size")
    if material_cache < 32 or material_cache > 512 then
        table.insert(errors, "rendering.material_cache_size must be between 32 and 512")
    end
    
    -- Physics validation
    local trace_cache = config.Get("physics.trace_cache_size")
    if trace_cache < 64 or trace_cache > 1024 then
        table.insert(errors, "physics.trace_cache_size must be between 64 and 1024")
    end
    
    -- Entity validation
    local lod_distances = config.GetSection("entities.lod_distances")
    if lod_distances.high >= lod_distances.medium or 
       lod_distances.medium >= lod_distances.low then
        table.insert(errors, "entities.lod_distances must be in ascending order")
    end
    
    return #errors == 0, errors
end

-- Apply configuration to modules
function config.Apply()
    -- Apply memory configuration
    if MemoryManager and config.Get("memory.enabled") then
        MemoryManager.setLimit(config.Get("memory.limit_kb"))
    end
    
    -- Apply entity management configuration
    if EntityManager and config.Get("entities.enabled") then
        EntityManager.SetCullingDistance(config.Get("entities.max_visible_distance"))
        local lod = config.GetSection("entities.lod_distances")
        EntityManager.SetLODDistances(lod.high, lod.medium, lod.low)
        EntityManager.EnableDistanceCulling(config.Get("entities.distance_culling"))
    end
    
    -- Apply rendering configuration
    if render and config.Get("rendering.enabled") then
        -- Configuration will be read by render module
    end
    
    -- Apply physics configuration
    if physics and config.Get("physics.enabled") then
        -- Configuration will be read by physics module
    end
    
    print("[GLIBUS] Configuration applied to all modules")
end

-- Configuration presets
local presets = {
    performance = {
        memory = { limit_kb = 512, check_interval = 15 },
        rendering = { material_cache_size = 64, batch_rendering = true },
        physics = { trace_cache_size = 128, distance_culling = true },
        entities = { max_visible_distance = 2048 }
    },
    
    quality = {
        memory = { limit_kb = 2048, check_interval = 60 },
        rendering = { material_cache_size = 256, batch_rendering = false },
        physics = { trace_cache_size = 512, distance_culling = false },
        entities = { max_visible_distance = 8192 }
    },
    
    balanced = {
        memory = { limit_kb = 1024, check_interval = 30 },
        rendering = { material_cache_size = 128, batch_rendering = true },
        physics = { trace_cache_size = 256, distance_culling = true },
        entities = { max_visible_distance = 4096 }
    }
}

-- Apply preset
function config.ApplyPreset(preset_name)
    local preset = presets[preset_name]
    if not preset then
        return false
    end
    
    for section, values in pairs(preset) do
        for key, value in pairs(values) do
            config.Set(section .. "." .. key, value)
        end
    end
    
    config.Apply()
    print(string.format("[GLIBUS] Applied preset: %s", preset_name))
    return true
end

-- Get available presets
function config.GetPresets()
    local preset_names = {}
    for name in pairs(presets) do
        table.insert(preset_names, name)
    end
    return preset_names
end

-- Console commands for configuration
if SERVER then
    concommand.Add("glibus_config_get", function(ply, cmd, args)
        if not IsValid(ply) or not ply:IsSuperAdmin() then return end
        
        local path = args[1]
        if not path then
            ply:ChatPrint("Usage: glibus_config_get <path>")
            return
        end
        
        local value = config.Get(path)
        ply:ChatPrint(string.format("%s = %s", path, tostring(value)))
    end)
    
    concommand.Add("glibus_config_set", function(ply, cmd, args)
        if not IsValid(ply) or not ply:IsSuperAdmin() then return end
        
        local path = args[1]
        local value = args[2]
        
        if not path or not value then
            ply:ChatPrint("Usage: glibus_config_set <path> <value>")
            return
        end
        
        -- Try to convert value to appropriate type
        if value == "true" then value = true
        elseif value == "false" then value = false
        elseif tonumber(value) then value = tonumber(value)
        end
        
        config.Set(path, value)
        ply:ChatPrint(string.format("Set %s = %s", path, tostring(value)))
    end)
    
    concommand.Add("glibus_config_preset", function(ply, cmd, args)
        if not IsValid(ply) or not ply:IsSuperAdmin() then return end
        
        local preset = args[1]
        if not preset then
            ply:ChatPrint("Available presets: " .. table.concat(config.GetPresets(), ", "))
            return
        end
        
        if config.ApplyPreset(preset) then
            ply:ChatPrint("Applied preset: " .. preset)
        else
            ply:ChatPrint("Unknown preset: " .. preset)
        end
    end)
end

-- Load configuration on startup
config.Load()

-- Validate and apply configuration
local valid, errors = config.Validate()
if not valid then
    print("[GLIBUS] Configuration validation errors:")
    for _, error in ipairs(errors) do
        print("  - " .. error)
    end
    print("[GLIBUS] Using default configuration")
    config.Reset()
end

config.Apply()

-- Export global configuration
_G.GlibusConfig = config

return config