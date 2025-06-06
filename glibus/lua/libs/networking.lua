-- Advanced Networking Library for Garry's Mod
-- Optimized packet handling, compression, and synchronization

-- Cache frequently used functions
local net = net
local util = util
local player = player
local table_insert, table_remove = table.insert, table.remove
local math_min, math_max = math.min, math.max
local string_len, string_sub = string.len, string.sub

-- Configuration
local MAX_PACKET_SIZE = 65536
local COMPRESSION_THRESHOLD = 512
local BATCH_SIZE = 10
local RATE_LIMIT_WINDOW = 1.0
local MAX_PACKETS_PER_WINDOW = 100

-- Network statistics
local network_stats = {
    packets_sent = 0,
    packets_received = 0,
    bytes_sent = 0,
    bytes_received = 0,
    compression_ratio = 0,
    rate_limited = 0
}

-- Packet batching system
local packet_batches = {}
local batch_timers = {}

-- Rate limiting
local rate_limits = {}

-- Message queue for reliable delivery
local message_queue = {}
local message_id_counter = 0

-- Compression cache
local compression_cache = {}
local COMPRESSION_CACHE_SIZE = 100

-- Initialize networking
local function initNetworking()
    -- Clear old data
    packet_batches = {}
    batch_timers = {}
    rate_limits = {}
    message_queue = {}
end

-- Rate limiting check
local function checkRateLimit(player_id)
    local current_time = CurTime()
    
    if not rate_limits[player_id] then
        rate_limits[player_id] = {
            packets = {},
            count = 0
        }
    end
    
    local player_limits = rate_limits[player_id]
    
    -- Remove old packets outside the window
    local cutoff_time = current_time - RATE_LIMIT_WINDOW
    for i = #player_limits.packets, 1, -1 do
        if player_limits.packets[i] < cutoff_time then
            table_remove(player_limits.packets, i)
            player_limits.count = player_limits.count - 1
        end
    end
    
    -- Check if player is rate limited
    if player_limits.count >= MAX_PACKETS_PER_WINDOW then
        network_stats.rate_limited = network_stats.rate_limited + 1
        return false
    end
    
    -- Add current packet
    table_insert(player_limits.packets, current_time)
    player_limits.count = player_limits.count + 1
    
    return true
end

-- Compress data if beneficial
local function compressData(data)
    if string_len(data) < COMPRESSION_THRESHOLD then
        return data, false
    end
    
    -- Check compression cache
    local cache_key = util.CRC(data)
    if compression_cache[cache_key] then
        return compression_cache[cache_key], true
    end
    
    local compressed = util.Compress(data)
    if string_len(compressed) < string_len(data) * 0.8 then
        -- Only use compression if it saves at least 20%
        if table.Count(compression_cache) < COMPRESSION_CACHE_SIZE then
            compression_cache[cache_key] = compressed
        end
        return compressed, true
    end
    
    return data, false
end

-- Decompress data
local function decompressData(data, is_compressed)
    if not is_compressed then
        return data
    end
    
    return util.Decompress(data) or data
end

-- Optimized network message sending
function networking.Send(message_name, data, targets, reliable)
    if not message_name then return false end
    
    -- Prepare data
    local serialized_data = util.TableToJSON(data or {})
    local compressed_data, is_compressed = compressData(serialized_data)
    
    -- Check packet size
    if string_len(compressed_data) > MAX_PACKET_SIZE then
        ErrorNoHalt("Packet too large: " .. string_len(compressed_data) .. " bytes")
        return false
    end
    
    -- Handle targets
    if not targets then
        targets = player.GetAll()
    elseif not istable(targets) then
        targets = {targets}
    end
    
    -- Rate limiting check for each target
    local valid_targets = {}
    for _, target in ipairs(targets) do
        if IsValid(target) and target:IsPlayer() then
            local player_id = target:UserID()
            if checkRateLimit(player_id) then
                table_insert(valid_targets, target)
            end
        end
    end
    
    if #valid_targets == 0 then
        return false
    end
    
    -- Send message
    net.Start(message_name)
    net.WriteBool(is_compressed)
    net.WriteUInt(string_len(compressed_data), 16)
    net.WriteData(compressed_data, string_len(compressed_data))
    
    if reliable then
        message_id_counter = message_id_counter + 1
        net.WriteUInt(message_id_counter, 16)
        
        -- Store for potential resend
        message_queue[message_id_counter] = {
            name = message_name,
            data = compressed_data,
            is_compressed = is_compressed,
            targets = valid_targets,
            timestamp = CurTime(),
            attempts = 0
        }
    end
    
    net.Send(valid_targets)
    
    -- Update statistics
    network_stats.packets_sent = network_stats.packets_sent + 1
    network_stats.bytes_sent = network_stats.bytes_sent + string_len(compressed_data)
    
    return true
end

-- Optimized network message receiving
function networking.Receive(message_name, callback)
    net.Receive(message_name, function(len, ply)
        if not IsValid(ply) then return end
        
        -- Rate limiting check
        local player_id = ply:UserID()
        if not checkRateLimit(player_id) then
            return
        end
        
        -- Read message data
        local is_compressed = net.ReadBool()
        local data_length = net.ReadUInt(16)
        local data = net.ReadData(data_length)
        
        -- Decompress if needed
        data = decompressData(data, is_compressed)
        
        -- Parse JSON
        local parsed_data = util.JSONToTable(data)
        if not parsed_data then
            ErrorNoHalt("Failed to parse network data from " .. ply:Nick())
            return
        end
        
        -- Update statistics
        network_stats.packets_received = network_stats.packets_received + 1
        network_stats.bytes_received = network_stats.bytes_received + data_length
        
        -- Call callback
        if callback then
            local success, error_msg = pcall(callback, parsed_data, ply)
            if not success then
                ErrorNoHalt("Network callback error: " .. tostring(error_msg))
            end
        end
    end)
end

-- Batch multiple messages for efficiency
function networking.StartBatch(target)
    local target_id = IsValid(target) and target:UserID() or "all"
    
    if not packet_batches[target_id] then
        packet_batches[target_id] = {}
    end
    
    return target_id
end

function networking.AddToBatch(batch_id, message_name, data)
    if not packet_batches[batch_id] then
        return false
    end
    
    table_insert(packet_batches[batch_id], {
        name = message_name,
        data = data
    })
    
    return true
end

function networking.SendBatch(batch_id, target)
    local batch = packet_batches[batch_id]
    if not batch or #batch == 0 then
        return false
    end
    
    -- Send all messages in batch
    for _, message in ipairs(batch) do
        networking.Send(message.name, message.data, target)
    end
    
    -- Clear batch
    packet_batches[batch_id] = nil
    
    return true
end

-- Reliable message acknowledgment
function networking.SendAck(message_id, target)
    net.Start("NetworkingAck")
    net.WriteUInt(message_id, 16)
    net.Send(target)
end

-- Handle acknowledgments
net.Receive("NetworkingAck", function(len, ply)
    local message_id = net.ReadUInt(16)
    
    if message_queue[message_id] then
        message_queue[message_id] = nil
    end
end)

-- Resend unacknowledged messages
local function resendMessages()
    local current_time = CurTime()
    
    for message_id, message in pairs(message_queue) do
        if current_time - message.timestamp > 5.0 then -- 5 second timeout
            if message.attempts < 3 then
                -- Resend message
                net.Start(message.name)
                net.WriteBool(message.is_compressed)
                net.WriteUInt(string_len(message.data), 16)
                net.WriteData(message.data, string_len(message.data))
                net.WriteUInt(message_id, 16)
                net.Send(message.targets)
                
                message.attempts = message.attempts + 1
                message.timestamp = current_time
            else
                -- Give up after 3 attempts
                message_queue[message_id] = nil
            end
        end
    end
end

-- Network statistics
function networking.GetStats()
    local compression_ratio = 0
    if network_stats.bytes_sent > 0 then
        compression_ratio = (1 - (network_stats.bytes_sent / (network_stats.bytes_sent + 1000))) * 100
    end
    
    return {
        packets_sent = network_stats.packets_sent,
        packets_received = network_stats.packets_received,
        bytes_sent = network_stats.bytes_sent,
        bytes_received = network_stats.bytes_received,
        compression_ratio = compression_ratio,
        rate_limited = network_stats.rate_limited,
        queued_messages = table.Count(message_queue),
        active_batches = table.Count(packet_batches)
    }
end

function networking.ResetStats()
    network_stats = {
        packets_sent = 0,
        packets_received = 0,
        bytes_sent = 0,
        bytes_received = 0,
        compression_ratio = 0,
        rate_limited = 0
    }
end

-- Cleanup function
function networking.Cleanup()
    packet_batches = {}
    batch_timers = {}
    rate_limits = {}
    message_queue = {}
    compression_cache = {}
end

-- Initialize networking system
initNetworking()

-- Periodic maintenance
timer.Create("NetworkingMaintenance", 1.0, 0, function()
    resendMessages()
end)

-- Export global networking
_G.Networking = networking