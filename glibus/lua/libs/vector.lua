local vec = FindMetaTable("Vector")

function vec:Length()
    local x, y, z = self.x, self.y, self.z
	return (x * x + y * y + z * z) ^ .5
end

function vec:Distance(pos)
    local v = self - pos
    local x, y, z = v.x, v.y, v.z
    return (x * x + y * y + z * z) ^ .5
end

function vec.Normalize(v)
    local l = 1 / v:Length()
    v.x, v.y, v.z = v.x * l, v.y * l, v.z * l
end

function vec:GetNormalized()
	local l = 1 / self:Length() 
	local x, y, z = self.x * l, self.y * l, self.z * l
    return Vector(x, y, z)
end

function vec.Dot(a, b)
    return a.x * b.x + a.y * b.y + a.z * b.z
end
