local vec = FindMetaTable("Vector")

local min, max = math.min, math.max
local sqrt = math.sqrt

function vec:Length()
	local x, y, z = self.x, self.y, self.z
	return sqrt(x * x + y * y + z * z)
end

function vec:Distance(pos)
	local v = self - pos
	local x, y, z = v.x, v.y, v.z
	return sqrt(x * x + y * y + z * z)
end

function vec.Normalize(v)
	local l = v:Length()
	v.x = v.x / l
	v.y = v.y / l
	v.z = v.z / l
end

function vec:GetNormalized()
	local l = self:Length()
	local x, y, z = self.x, self.y, self.z
	return Vector(x, y, z) / l
end

function vec.Dot(a, b)
	return a.x * b.x + a.y * b.y + a.z * b.z
end
