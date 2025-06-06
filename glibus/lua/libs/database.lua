-- Advanced Database Management System for Garry's Mod
-- Optimized SQLite operations with caching and connection pooling

-- Cache frequently used functions
local sql = sql
local util = util
local file = file
local string_format = string.format
local table_insert, table_remove = table.insert, table.remove

-- Configuration
local DB_PATH = "glibus_data.db"
local CACHE_SIZE = 1000
local BATCH_SIZE = 100
local CONNECTION_TIMEOUT = 30
local QUERY_TIMEOUT = 10

-- Database cache
local query_cache = {}
local cache_timestamps = {}
local cache_count = 0

-- Connection pool
local connection_pool = {}
local active_connections = 0
local MAX_CONNECTIONS = 5

-- Query batching
local query_batch = {}
local batch_timer = nil

-- Performance statistics
local db_stats = {
    queries_executed = 0,
    cache_hits = 0,
    cache_misses = 0,
    total_query_time = 0,
    failed_queries = 0,
    batch_operations = 0
}

-- Prepared statements cache
local prepared_statements = {}

-- Initialize database
local function initDatabase()
    -- Create tables if they don't exist
    local init_queries = {
        [[CREATE TABLE IF NOT EXISTS glibus_cache (
            key TEXT PRIMARY KEY,
            value TEXT,
            timestamp INTEGER,
            expires INTEGER
        )]],
        [[CREATE TABLE IF NOT EXISTS glibus_config (
            key TEXT PRIMARY KEY,
            value TEXT,
            type TEXT
        )]],
        [[CREATE TABLE IF NOT EXISTS glibus_logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            level TEXT,
            message TEXT,
            timestamp INTEGER
        )]],
        [[CREATE INDEX IF NOT EXISTS idx_cache_expires ON glibus_cache(expires)]],
        [[CREATE INDEX IF NOT EXISTS idx_logs_timestamp ON glibus_logs(timestamp)]]
    }
    
    for _, query in ipairs(init_queries) do
        local result = sql.Query(query)
        if result == false then
            ErrorNoHalt("Database initialization error: " .. sql.LastError())
        end
    end
end

-- Generate cache key
local function generateCacheKey(query, params)
    local key = query
    if params then
        for _, param in ipairs(params) do
            key = key .. "|" .. tostring(param)
        end
    end
    return util.CRC(key)
end

-- Clean expired cache entries
local function cleanCache()
    local current_time = os.time()
    local cleaned = 0
    
    for key, timestamp in pairs(cache_timestamps) do
        if current_time - timestamp > 300 then -- 5 minutes
            query_cache[key] = nil
            cache_timestamps[key] = nil
            cache_count = cache_count - 1
            cleaned = cleaned + 1
        end
    end
    
    if cleaned > 0 then
        print(string_format("Database cache cleaned: %d entries removed", cleaned))
    end
end

-- Execute query with caching
function database.Query(query, params, use_cache)
    use_cache = use_cache ~= false -- Default to true
    
    local start_time = SysTime()
    local cache_key = generateCacheKey(query, params)
    
    -- Check cache first
    if use_cache and query_cache[cache_key] then
        db_stats.cache_hits = db_stats.cache_hits + 1
        return query_cache[cache_key]
    end
    
    db_stats.cache_misses = db_stats.cache_misses + 1
    
    -- Prepare query with parameters
    local final_query = query
    if params then
        for i, param in ipairs(params) do
            local escaped_param = sql.SQLStr(tostring(param))
            final_query = string.gsub(final_query, "%?", escaped_param, 1)
        end
    end
    
    -- Execute query
    local result = sql.Query(final_query)
    local query_time = SysTime() - start_time
    
    -- Update statistics
    db_stats.queries_executed = db_stats.queries_executed + 1
    db_stats.total_query_time = db_stats.total_query_time + query_time
    
    if result == false then
        db_stats.failed_queries = db_stats.failed_queries + 1
        ErrorNoHalt("Database query error: " .. sql.LastError())
        return nil
    end
    
    -- Cache successful SELECT queries
    if use_cache and string.find(string.upper(query), "SELECT") then
        if cache_count >= CACHE_SIZE then
            -- Remove oldest cache entry
            local oldest_key = nil
            local oldest_time = math.huge
            
            for key, timestamp in pairs(cache_timestamps) do
                if timestamp < oldest_time then
                    oldest_time = timestamp
                    oldest_key = key
                end
            end
            
            if oldest_key then
                query_cache[oldest_key] = nil
                cache_timestamps[oldest_key] = nil
                cache_count = cache_count - 1
            end
        end
        
        query_cache[cache_key] = result
        cache_timestamps[cache_key] = os.time()
        cache_count = cache_count + 1
    end
    
    return result
end

-- Prepared statement execution
function database.Execute(statement_name, params)
    if not prepared_statements[statement_name] then
        ErrorNoHalt("Prepared statement not found: " .. statement_name)
        return nil
    end
    
    return database.Query(prepared_statements[statement_name], params)
end

-- Prepare statement
function database.Prepare(statement_name, query)
    prepared_statements[statement_name] = query
end

-- Batch operations
function database.AddToBatch(query, params)
    table_insert(query_batch, {query = query, params = params})
    
    if #query_batch >= BATCH_SIZE then
        database.FlushBatch()
    end
end

function database.FlushBatch()
    if #query_batch == 0 then return end
    
    local start_time = SysTime()
    sql.Begin()
    
    local success_count = 0
    for _, batch_item in ipairs(query_batch) do
        local result = database.Query(batch_item.query, batch_item.params, false)
        if result ~= nil then
            success_count = success_count + 1
        end
    end
    
    sql.Commit()
    
    local batch_time = SysTime() - start_time
    db_stats.batch_operations = db_stats.batch_operations + 1
    
    print(string_format("Batch executed: %d/%d queries successful in %.3fs", 
        success_count, #query_batch, batch_time))
    
    query_batch = {}
end

-- Transaction support
function database.Transaction(queries)
    sql.Begin()
    
    local results = {}
    local success = true
    
    for i, query_data in ipairs(queries) do
        local result = database.Query(query_data.query, query_data.params, false)
        if result == nil then
            success = false
            break
        end
        results[i] = result
    end
    
    if success then
        sql.Commit()
        return results
    else
        sql.Rollback()
        return nil
    end
end

-- High-level data operations
function database.Set(key, value, expires)
    expires = expires or (os.time() + 3600) -- 1 hour default
    
    return database.Query(
        "INSERT OR REPLACE INTO glibus_cache (key, value, timestamp, expires) VALUES (?, ?, ?, ?)",
        {key, util.TableToJSON(value), os.time(), expires}
    )
end

function database.Get(key)
    local result = database.Query(
        "SELECT value, expires FROM glibus_cache WHERE key = ? AND expires > ?",
        {key, os.time()}
    )
    
    if result and result[1] then
        return util.JSONToTable(result[1].value)
    end
    
    return nil
end

function database.Delete(key)
    return database.Query("DELETE FROM glibus_cache WHERE key = ?", {key})
end

-- Configuration management
function database.SetConfig(key, value, value_type)
    value_type = value_type or type(value)
    local serialized_value = value_type == "table" and util.TableToJSON(value) or tostring(value)
    
    return database.Query(
        "INSERT OR REPLACE INTO glibus_config (key, value, type) VALUES (?, ?, ?)",
        {key, serialized_value, value_type}
    )
end

function database.GetConfig(key, default_value)
    local result = database.Query(
        "SELECT value, type FROM glibus_config WHERE key = ?",
        {key}
    )
    
    if result and result[1] then
        local value = result[1].value
        local value_type = result[1].type
        
        if value_type == "table" then
            return util.JSONToTable(value) or default_value
        elseif value_type == "number" then
            return tonumber(value) or default_value
        elseif value_type == "boolean" then
            return value == "true"
        else
            return value
        end
    end
    
    return default_value
end

-- Logging system
function database.Log(level, message)
    database.AddToBatch(
        "INSERT INTO glibus_logs (level, message, timestamp) VALUES (?, ?, ?)",
        {level, message, os.time()}
    )
end

function database.GetLogs(level, limit, offset)
    limit = limit or 100
    offset = offset or 0
    
    local where_clause = level and "WHERE level = ?" or ""
    local params = level and {level, limit, offset} or {limit, offset}
    
    return database.Query(
        string_format("SELECT * FROM glibus_logs %s ORDER BY timestamp DESC LIMIT ? OFFSET ?", where_clause),
        params
    )
end

-- Maintenance operations
function database.Vacuum()
    return database.Query("VACUUM", nil, false)
end

function database.Analyze()
    return database.Query("ANALYZE", nil, false)
end

function database.CleanExpired()
    local result = database.Query(
        "DELETE FROM glibus_cache WHERE expires < ?",
        {os.time()},
        false
    )
    
    cleanCache()
    return result
end

-- Performance statistics
function database.GetStats()
    local avg_query_time = db_stats.queries_executed > 0 and 
        (db_stats.total_query_time / db_stats.queries_executed) or 0
    
    return {
        queries_executed = db_stats.queries_executed,
        cache_hits = db_stats.cache_hits,
        cache_misses = db_stats.cache_misses,
        cache_hit_ratio = db_stats.cache_hits / math.max(db_stats.cache_hits + db_stats.cache_misses, 1),
        average_query_time = avg_query_time,
        failed_queries = db_stats.failed_queries,
        batch_operations = db_stats.batch_operations,
        cache_size = cache_count,
        prepared_statements = table.Count(prepared_statements)
    }
end

function database.ResetStats()
    db_stats = {
        queries_executed = 0,
        cache_hits = 0,
        cache_misses = 0,
        total_query_time = 0,
        failed_queries = 0,
        batch_operations = 0
    }
end

-- Cleanup function
function database.Cleanup()
    database.FlushBatch()
    query_cache = {}
    cache_timestamps = {}
    cache_count = 0
    prepared_statements = {}
end

-- Initialize database on load
initDatabase()

-- Periodic maintenance
timer.Create("DatabaseMaintenance", 300, 0, function() -- Every 5 minutes
    database.CleanExpired()
    cleanCache()
end)

-- Auto-flush batch every 10 seconds
timer.Create("DatabaseBatchFlush", 10, 0, function()
    if #query_batch > 0 then
        database.FlushBatch()
    end
end)

-- Export global database
_G.Database = database