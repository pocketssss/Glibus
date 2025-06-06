-- Advanced Performance Monitoring System for Garry's Mod
-- Real-time performance tracking and optimization suggestions

-- Cache frequently used functions
local CurTime, SysTime = CurTime, SysTime
local math_floor, math_ceil = math.floor, math.ceil
local table_insert, table_remove = table.insert, table.remove

-- Configuration
local MONITOR_INTERVAL = 1.0
local HISTORY_SIZE = 300 -- 5 minutes at 1 second intervals
local ALERT_COOLDOWN = 30.0

-- Performance metrics storage
local performance_data = {
    fps = {},
    memory = {},
    network = {},
    entities = {},
    hooks = {},
    database = {}
}

-- Alert system
local alerts = {}
local last_alert_time = {}

-- Performance thresholds
local thresholds = {
    fps_critical = 20,
    fps_warning = 40,
    memory_critical = 0.95,
    memory_warning = 0.80,
    network_critical = 2000000, -- 2MB/s
    network_warning = 1000000,  -- 1MB/s
    entity_count_warning = 1000,
    entity_count_critical = 2000
}

-- Profiling data
local profiling_sessions = {}
local active_profiles = {}

-- Performance monitor object
local monitor = {}

-- Add data point to history
local function addToHistory(category, value, timestamp)
    timestamp = timestamp or CurTime()
    
    if not performance_data[category] then
        performance_data[category] = {}
    end
    
    table_insert(performance_data[category], {
        value = value,
        timestamp = timestamp
    })
    
    -- Limit history size
    while #performance_data[category] > HISTORY_SIZE do
        table_remove(performance_data[category], 1)
    end
end

-- Calculate average over time period
local function calculateAverage(category, time_period)
    time_period = time_period or 60 -- Default 1 minute
    local data = performance_data[category]
    if not data or #data == 0 then return 0 end
    
    local current_time = CurTime()
    local cutoff_time = current_time - time_period
    local sum, count = 0, 0
    
    for i = #data, 1, -1 do
        if data[i].timestamp >= cutoff_time then
            sum = sum + data[i].value
            count = count + 1
        else
            break
        end
    end
    
    return count > 0 and (sum / count) or 0
end

-- Send alert if threshold exceeded
local function checkAlert(alert_type, current_value, threshold, message)
    local current_time = CurTime()
    
    if current_value >= threshold then
        if not last_alert_time[alert_type] or 
           current_time - last_alert_time[alert_type] > ALERT_COOLDOWN then
            
            table_insert(alerts, {
                type = alert_type,
                message = message,
                value = current_value,
                threshold = threshold,
                timestamp = current_time
            })
            
            last_alert_time[alert_type] = current_time
            
            -- Log alert
            print(string.format("[GLIBUS][ALERT] %s: %s (%.2f >= %.2f)", 
                alert_type, message, current_value, threshold))
            
            return true
        end
    end
    
    return false
end

-- Collect FPS data
local function collectFPSData()
    local fps = 1 / FrameTime()
    addToHistory("fps", fps)
    
    -- Check FPS alerts
    checkAlert("fps_critical", -fps, -thresholds.fps_critical, 
        string.format("Critical FPS drop: %.1f", fps))
    checkAlert("fps_warning", -fps, -thresholds.fps_warning,
        string.format("FPS warning: %.1f", fps))
end

-- Collect memory data
local function collectMemoryData()
    local memory_kb = collectgarbage("count")
    local memory_limit = GlibusConfig and GlibusConfig.Get("memory.limit_kb") or 1024
    local memory_ratio = memory_kb / memory_limit
    
    addToHistory("memory", memory_ratio)
    
    -- Check memory alerts
    checkAlert("memory_critical", memory_ratio, thresholds.memory_critical,
        string.format("Critical memory usage: %.1f%%", memory_ratio * 100))
    checkAlert("memory_warning", memory_ratio, thresholds.memory_warning,
        string.format("High memory usage: %.1f%%", memory_ratio * 100))
end

-- Collect network data
local function collectNetworkData()
    if Networking then
        local stats = Networking.GetStats()
        local bytes_per_second = stats.bytes_sent + stats.bytes_received
        
        addToHistory("network", bytes_per_second)
        
        -- Check network alerts
        checkAlert("network_critical", bytes_per_second, thresholds.network_critical,
            string.format("Critical network usage: %.2f MB/s", bytes_per_second / 1000000))
        checkAlert("network_warning", bytes_per_second, thresholds.network_warning,
            string.format("High network usage: %.2f MB/s", bytes_per_second / 1000000))
    end
end

-- Collect entity data
local function collectEntityData()
    if EntityManager then
        local stats = EntityManager.GetStats()
        addToHistory("entities", stats.total_entities)
        
        -- Check entity count alerts
        checkAlert("entity_critical", stats.total_entities, thresholds.entity_count_critical,
            string.format("Critical entity count: %d", stats.total_entities))
        checkAlert("entity_warning", stats.total_entities, thresholds.entity_count_warning,
            string.format("High entity count: %d", stats.total_entities))
    end
end

-- Main monitoring function
local function performanceMonitor()
    collectFPSData()
    collectMemoryData()
    collectNetworkData()
    collectEntityData()
    
    -- Collect hook performance data
    if hook and hook.GetStats then
        local hook_stats = hook.GetStats()
        addToHistory("hooks", hook_stats.total_calls or 0)
    end
    
    -- Collect database performance data
    if Database then
        local db_stats = Database.GetStats()
        addToHistory("database", db_stats.average_query_time or 0)
    end
end

-- Start profiling session
function monitor.StartProfile(name)
    if active_profiles[name] then
        return false -- Already profiling
    end
    
    active_profiles[name] = {
        start_time = SysTime(),
        start_memory = collectgarbage("count"),
        name = name
    }
    
    return true
end

-- End profiling session
function monitor.EndProfile(name)
    local profile = active_profiles[name]
    if not profile then
        return nil
    end
    
    local end_time = SysTime()
    local end_memory = collectgarbage("count")
    
    local result = {
        name = name,
        duration = end_time - profile.start_time,
        memory_used = end_memory - profile.start_memory,
        timestamp = CurTime()
    }
    
    -- Store profiling result
    if not profiling_sessions[name] then
        profiling_sessions[name] = {}
    end
    
    table_insert(profiling_sessions[name], result)
    
    -- Limit profiling history
    while #profiling_sessions[name] > 100 do
        table_remove(profiling_sessions[name], 1)
    end
    
    active_profiles[name] = nil
    
    return result
end

-- Get performance statistics
function monitor.GetStats(category, time_period)
    time_period = time_period or 60
    
    if category then
        return {
            current = performance_data[category] and 
                performance_data[category][#performance_data[category]] and
                performance_data[category][#performance_data[category]].value or 0,
            average = calculateAverage(category, time_period),
            history = performance_data[category] or {}
        }
    else
        local stats = {}
        for cat in pairs(performance_data) do
            stats[cat] = monitor.GetStats(cat, time_period)
        end
        return stats
    end
end

-- Get recent alerts
function monitor.GetAlerts(count)
    count = count or 10
    local recent_alerts = {}
    
    for i = math.max(1, #alerts - count + 1), #alerts do
        table_insert(recent_alerts, alerts[i])
    end
    
    return recent_alerts
end

-- Clear alerts
function monitor.ClearAlerts()
    alerts = {}
    last_alert_time = {}
end

-- Get profiling data
function monitor.GetProfilingData(name)
    if name then
        return profiling_sessions[name] or {}
    else
        return profiling_sessions
    end
end

-- Generate performance report
function monitor.GenerateReport()
    local report = {
        timestamp = os.date("%Y-%m-%d %H:%M:%S"),
        summary = {},
        details = {},
        alerts = monitor.GetAlerts(20),
        recommendations = {}
    }
    
    -- Generate summary
    report.summary.fps = {
        current = monitor.GetStats("fps", 10).current,
        average_1min = calculateAverage("fps", 60),
        average_5min = calculateAverage("fps", 300)
    }
    
    report.summary.memory = {
        current = monitor.GetStats("memory", 10).current,
        average_1min = calculateAverage("memory", 60),
        peak_5min = math.max(unpack(performance_data.memory and 
            {performance_data.memory[math.max(1, #performance_data.memory - 300)].value} or {0}))
    }
    
    -- Generate recommendations
    local fps_avg = report.summary.fps.average_1min
    local memory_avg = report.summary.memory.average_1min
    
    if fps_avg < 30 then
        table_insert(report.recommendations, "Consider reducing entity count or enabling more aggressive culling")
    end
    
    if memory_avg > 0.8 then
        table_insert(report.recommendations, "Memory usage is high - consider reducing cache sizes or enabling more frequent garbage collection")
    end
    
    if #alerts > 10 then
        table_insert(report.recommendations, "Multiple performance alerts detected - review system configuration")
    end
    
    return report
end

-- Set performance thresholds
function monitor.SetThresholds(new_thresholds)
    for key, value in pairs(new_thresholds) do
        if thresholds[key] then
            thresholds[key] = value
        end
    end
end

-- Export performance data
function monitor.ExportData(format)
    format = format or "json"
    
    if format == "json" then
        return util.TableToJSON({
            performance_data = performance_data,
            alerts = alerts,
            profiling_sessions = profiling_sessions,
            thresholds = thresholds
        }, true)
    elseif format == "csv" then
        -- Generate CSV format for FPS data
        local csv_lines = {"timestamp,fps,memory,entities"}
        
        local fps_data = performance_data.fps or {}
        for i, data_point in ipairs(fps_data) do
            local memory_point = performance_data.memory[i]
            local entity_point = performance_data.entities[i]
            
            table_insert(csv_lines, string.format("%.2f,%.2f,%.4f,%d",
                data_point.timestamp,
                data_point.value,
                memory_point and memory_point.value or 0,
                entity_point and entity_point.value or 0
            ))
        end
        
        return table.concat(csv_lines, "\n")
    end
    
    return nil
end

-- Console commands for monitoring
if SERVER then
    concommand.Add("glibus_performance_report", function(ply, cmd, args)
        if not IsValid(ply) or not ply:IsSuperAdmin() then return end
        
        local report = monitor.GenerateReport()
        
        ply:ChatPrint("=== Glibus Performance Report ===")
        ply:ChatPrint(string.format("FPS: Current %.1f, 1min avg %.1f", 
            report.summary.fps.current, report.summary.fps.average_1min))
        ply:ChatPrint(string.format("Memory: Current %.1f%%, 1min avg %.1f%%", 
            report.summary.memory.current * 100, report.summary.memory.average_1min * 100))
        ply:ChatPrint(string.format("Recent alerts: %d", #report.alerts))
        
        if #report.recommendations > 0 then
            ply:ChatPrint("Recommendations:")
            for _, rec in ipairs(report.recommendations) do
                ply:ChatPrint("  - " .. rec)
            end
        end
    end)
    
    concommand.Add("glibus_performance_export", function(ply, cmd, args)
        if not IsValid(ply) or not ply:IsSuperAdmin() then return end
        
        local format = args[1] or "json"
        local data = monitor.ExportData(format)
        
        if data then
            local filename = string.format("glibus_performance_%s.%s", os.date("%Y%m%d_%H%M%S"), format)
            file.Write(filename, data)
            ply:ChatPrint("Performance data exported to: " .. filename)
        else
            ply:ChatPrint("Failed to export performance data")
        end
    end)
end

-- Start monitoring
timer.Create("GlibusPerformanceMonitor", MONITOR_INTERVAL, 0, performanceMonitor)

-- Export global monitor
_G.PerformanceMonitor = monitor

return monitor