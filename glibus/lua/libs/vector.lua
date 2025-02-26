local vec = FindMetaTable("Vector")
local sqrt = math.sqrt
local Vector = Vector

local _x, _y, _z = 1, 2, 3 
local getmetatable = getmetatable

local function fast_len(x, y, z)
    return sqrt(x*x + y*y + z*z)
end

function vec:Length()
    return fast_len(self.x, self.y, self.z)
end

function vec:Distance(pos)
    local dx = self.x - pos.x
    local dy = self.y - pos.y
    local dz = self.z - pos.z
    return fast_len(dx, dy, dz)
end

function vec.Normalize(v)
    local x, y, z = v.x, v.y, v.z
    local len = sqrt(x*x + y*y + z*z)
    local il = 1 / (len + 1e-10) 
    v.x, v.y, v.z = x*il, y*il, z*il
end

function vec:GetNormalized()
    local x, y, z = self.x, self.y, self.z
    local len = sqrt(x*x + y*y + z*z)
    local il = 1 / (len + 1e-10)
    return Vector(x*il, y*il, z*il)
end

function vec.Dot(a, b)
    return a.x*b.x + a.y*b.y + a.z*b.z
end