local vec = FindMetaTable("Vector")

function vec:Length()
    local squaredLength = self.x ^ 2 + self.y ^ 2 + self.z ^ 2
    return math.sqrt(squaredLength)
end

function vec:Distance(pos)
    local v = self - pos
    local squaredDistance = v.x ^ 2 + v.y ^ 2 + v.z ^ 2
    return math.sqrt(squaredDistance)
end

function vec.Normalize(v)
    local length = v:Length()
    return Vector(v.x / length, v.y / length, v.z / length)
end

function vec:GetNormalized()
    local length = self:Length()
    return Vector(self.x / length, self.y / length, self.z / length)
end

function vec.Dot(a, b)
    return a.x * b.x + a.y * b.y + a.z * b.z
end
