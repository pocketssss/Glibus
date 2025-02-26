local net = net or {}
local netLimit = 64
local TYPE_COLOR = 255
local pairs, type, util_NetworkIDToString, math_min, error, assert = pairs, type, util.NetworkIDToString, math.min, error, assert
local net_Receivers = {}
local netCounter = {}

local colorMeta = FindMetaTable("Color")
local function ValidateColor(col)
    return getmetatable(col) == colorMeta
end

function net.Receive(name, func)
    local lowerName = name:lower()
    
    if net_Receivers[lowerName] then 
        netCounter[lowerName] = math_min(netCounter[lowerName] + 1, netLimit)
        return
    end

    net_Receivers[lowerName] = func
    netCounter[lowerName] = 1
end

local nameCache = {}
function net.Incoming(len, client)
    local i = net.ReadHeader()
    local strName = nameCache[i] or util_NetworkIDToString(i)
    
    if not strName then return end
    nameCache[i] = strName 

    local lowerName = strName:lower()
    local func = net_Receivers[lowerName]
    
    if not func or netCounter[lowerName] > netLimit then return end
    
    func(len - 16, client) 
end

function net.WriteEntity(ent)
    net.WriteUInt(ent:IsValid() and ent:EntIndex() or 0, 16)
end

function net.ReadEntity()
    return Entity(net.ReadUInt(16)) or NULL
end

function net.WriteColor(col, writeAlpha)
    assert(ValidateColor(col), "net.WriteColor: invalid color")
    
    net.WriteUInt(col.r, 8)
    net.WriteUInt(col.g, 8)
    net.WriteUInt(col.b, 8)
    
    if writeAlpha ~= false then
        net.WriteUInt(col.a, 8)
    end
end

function net.ReadColor(readAlpha)
    return Color(
        net.ReadUInt(8),
        net.ReadUInt(8),
        net.ReadUInt(8),
        readAlpha ~= false and net.ReadUInt(8) or 255
    )
end

local function WriteTable(tab)
    for k, v in pairs(tab) do
        if netWriteVars[TypeID(k)] then
            net.WriteType(k)
            net.WriteType(v)
        end
    end
    net.WriteUInt(TYPE_NIL, 8) 
end

local function ReadTable()
    local tab = {}
    while true do
        local typeID = net.ReadUInt(8)
        if typeID == TYPE_NIL then break end
        
        local k = netReadVars[typeID] and netReadVars[typeID]()
        if k ~= nil then
            tab[k] = net.ReadType()
        end
    end
    return tab
end

local netWriteVars = {
    [TYPE_NIL]     = function() net.WriteUInt(TYPE_NIL, 8) end,
    [TYPE_STRING]  = function(v) net.WriteUInt(TYPE_STRING, 8) net.WriteString(v) end,
    [TYPE_NUMBER]  = function(v) net.WriteUInt(TYPE_NUMBER, 8) net.WriteDouble(v) end,
    [TYPE_TABLE]   = function(v) net.WriteUInt(TYPE_TABLE, 8) WriteTable(v) end,
    [TYPE_BOOL]    = function(v) net.WriteUInt(TYPE_BOOL, 8) net.WriteBool(v) end,
    [TYPE_ENTITY]  = function(v) net.WriteUInt(TYPE_ENTITY, 8) net.WriteEntity(v) end,
    [TYPE_VECTOR]  = function(v) net.WriteUInt(TYPE_VECTOR, 8) net.WriteVectorNormal(v) end,
    [TYPE_COLOR]   = function(v) net.WriteUInt(TYPE_COLOR, 8) net.WriteColor(v) end,
}

local netReadVars = {
    [TYPE_NIL]     = function() return nil end,
    [TYPE_STRING]  = function() return net.ReadString() end,
    [TYPE_NUMBER]  = function() return net.ReadDouble() end,
    [TYPE_TABLE]   = function() return ReadTable() end,
    [TYPE_BOOL]    = function() return net.ReadBool() end,
    [TYPE_ENTITY]  = function() return net.ReadEntity() end,
    [TYPE_VECTOR]  = function() return net.ReadVectorNormal() end,
    [TYPE_COLOR]   = function() return net.ReadColor() end,
}

local typeCache = {}
function net.WriteType(v)
    local typeID = typeCache[v] or (ValidateColor(v) and TYPE_COLOR or TypeID(v))
    
    if netWriteVars[typeID] then
        typeCache[v] = typeID 
        netWriteVars[typeID](v)
    else
        error(string.format("Unsupported type: %s (%d)", type(v), typeID))
    end
end

return net