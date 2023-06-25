local net = net or {}

local TYPE_COLOR = 255

net.Receivers = {}

local function ValidateColor(col)
	return type(col) == "table" and type(col.r) == "number" and type(col.g) == "number" and type(col.b) == "number" and type(col.a) == "number"
end

-- Set up a function to receive network messages
function net.Receive(name, func)
	net.Receivers[name:lower()] = func
end

-- A message has been received from the network..
function net.Incoming(len, client)
	local i = net.ReadHeader()
	local strName = util.NetworkIDToString(i)

	if not strName then return end

	local func = net.Receivers[strName:lower()]
	if not func then return end

	-- len includes the 16 bit int which told us the message name
	len = len - 16

	func(len, client)
end

-- Read/Write a boolean to the stream
net.WriteBool = net.WriteBit

function net.ReadBool()
	return net.ReadBit() == 1
end

-- Read/Write an entity to the stream
function net.WriteEntity(ent)
	net.WriteUInt(IsValid(ent) and ent:EntIndex() or 0, 16)
end

function net.ReadEntity()
	local i = net.ReadUInt(16)
	return i and Entity(i)
end

-- Read/Write a color to/from the stream
function net.WriteColor(col, writeAlpha)
	if writeAlpha == nil then writeAlpha = true end

	assert(ValidateColor(col), "net.WriteColor: color expected, got " .. type(col))

	net.WriteUInt(col.r, 8)
	net.WriteUInt(col.g, 8)
	net.WriteUInt(col.b, 8)

	if writeAlpha then
		net.WriteUInt(col.a, 8)
	end
end

function net.ReadColor(readAlpha)
	if readAlpha == nil then readAlpha = true end

	local r = net.ReadUInt(8)
	local g = net.ReadUInt(8)
	local b = net.ReadUInt(8)
	local a = readAlpha and net.ReadUInt(8) or 255

	return Color(r, g, b, a)
end

-- Write a whole table to the stream
-- This is less optimal than writing each
-- item individually and in a specific order
-- because it adds type information before each var
function net.WriteTable(tab)
	for k, v in pairs(tab) do
		net.WriteType(k)
		net.WriteType(v)
	end

	-- End of table
	net.WriteType(nil)
end

function net.ReadTable()
	local tab = {}

	while true do
		local k = net.ReadType()
		if k == nil then return tab end

		tab[k] = net.ReadType()
	end
end

local netWriteVars = {
	[TYPE_NIL] = function(v) net.WriteUInt(TYPE_NIL, 8) end,
	[TYPE_STRING] = function(v) net.WriteUInt(TYPE_STRING, 8) net.WriteString(v) end,
	[TYPE_NUMBER] = function(v) net.WriteUInt(TYPE_NUMBER, 8) net.WriteDouble(v) end,
	[TYPE_TABLE] = function(v) net.WriteUInt(TYPE_TABLE, 8) net.WriteTable(v) end,
	[TYPE_BOOL] = function(v) net.WriteUInt(TYPE_BOOL, 8) net.WriteBool(v) end,
	[TYPE_ENTITY] = function(v) net.WriteUInt(TYPE_ENTITY, 8) net.WriteEntity(v) end,
	[TYPE_VECTOR] = function(v) net.WriteUInt(TYPE_VECTOR, 8) net.WriteVector(v) end,
	[TYPE_ANGLE] = function(v) net.WriteUInt(TYPE_ANGLE, 8) net.WriteAngle(v) end,
	[TYPE_MATRIX] = function(v) net.WriteUInt(TYPE_MATRIX, 8) net.WriteMatrix(v) end,
	[TYPE_COLOR] = function(v) net.WriteUInt(TYPE_COLOR, 8) net.WriteColor(v) end,
}

local netReadVars = {
	[TYPE_NIL] = function() return nil end,
	[TYPE_STRING] = function() return net.ReadString() end,
	[TYPE_NUMBER] = function() return net.ReadDouble() end,
	[TYPE_TABLE] = function() return net.ReadTable() end,
	[TYPE_BOOL] = function() return net.ReadBool() end,
	[TYPE_ENTITY] = function() return net.ReadEntity() end,
	[TYPE_VECTOR] = function() return net.ReadVector() end,
	[TYPE_ANGLE] = function() return net.ReadAngle() end,
	[TYPE_MATRIX] = function() return net.ReadMatrix() end,
	[TYPE_COLOR] = function() return net.ReadColor() end,
}

function net.WriteType(v)
	local typeid = ValidateColor(v) and TYPE_COLOR or TypeID(v)
	local writeVar = netWriteVars[typeid]

	if writeVar then
		writeVar(v)
	else
		error("net.WriteType: Couldn't write " .. type(v) .. " (type " .. typeid .. ")")
	end
end

function net.ReadType(typeid)
	typeid = typeid or net.ReadUInt(8)

	local readVar = netReadVars[typeid]
	if readVar then
		return readVar()
	else
		error("net.ReadType: Couldn't read type " .. typeid)
	end
end

return net
