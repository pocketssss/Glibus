local vec = FindMetaTable("Vector")

local min, max = math.min, math.max

function vec:Length()		 -- Maths are faster than functions.
	local x, y, z = self.x, self.y, self.z
	return (x * x + y * y + z * z) ^ 0.5
end

function vec:Distance(pos)	 -- Same as top.
	local v = self - pos
	local x, y, z = v.x, v.y, v.z
	return (x * x + y * y + z * z) ^ 0.5
end

function vec.Normalize(v)	 -- No conditions. Should be faster.
	local l = v:Length()
	v.x = v.x / l
	v.y = v.y / l
	v.z = v.z / l
end

function vec:GetNormalized()	 -- Same as top.
	local l = self:Length()
	local x, y, z = self.x, self.y, self.z
	return Vector(x, y, z) / l
end

function vec.Dot(a, b)			-- Sometimes I tend to think that everything in Garry's Mod is broken.
	return a.x * b.x + a.y * b.y + a.z * b.y
end