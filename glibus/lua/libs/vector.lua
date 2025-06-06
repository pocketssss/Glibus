-- Optimized Vector operations for Garry's Mod
local vec = FindMetaTable("Vector")
local sqrt, abs, min, max = math.sqrt, math.abs, math.min, math.max
local Vector, Angle = Vector, Angle

-- Cache commonly used values
local EPSILON = 1e-10
local INV_SQRT_CACHE = {}

-- Fast inverse square root approximation with caching
local function fast_inv_sqrt(x)
    if x <= EPSILON then return 0 end
    
    local cached = INV_SQRT_CACHE[x]
    if cached then return cached end
    
    local result = 1 / sqrt(x)
    INV_SQRT_CACHE[x] = result
    return result
end

-- Optimized length calculation
local function fast_len(x, y, z)
    return sqrt(x*x + y*y + z*z)
end

-- Fast length squared (avoids sqrt when possible)
local function fast_len_sqr(x, y, z)
    return x*x + y*y + z*z
end

-- Optimized Length calculation
function vec:Length()
    return fast_len(self.x, self.y, self.z)
end

-- Length squared (faster when you don't need exact length)
function vec:LengthSqr()
    return fast_len_sqr(self.x, self.y, self.z)
end

-- Optimized Distance calculation
function vec:Distance(pos)
    local dx = self.x - pos.x
    local dy = self.y - pos.y
    local dz = self.z - pos.z
    return fast_len(dx, dy, dz)
end

-- Distance squared (faster when you don't need exact distance)
function vec:DistanceSqr(pos)
    local dx = self.x - pos.x
    local dy = self.y - pos.y
    local dz = self.z - pos.z
    return fast_len_sqr(dx, dy, dz)
end

-- Optimized in-place normalization
function vec:Normalize()
    local x, y, z = self.x, self.y, self.z
    local len_sqr = x*x + y*y + z*z
    
    if len_sqr <= EPSILON then
        self.x, self.y, self.z = 0, 0, 0
        return 0
    end
    
    local inv_len = fast_inv_sqrt(len_sqr)
    self.x, self.y, self.z = x * inv_len, y * inv_len, z * inv_len
    return sqrt(len_sqr)
end

-- Get normalized copy without modifying original
function vec:GetNormalized()
    local x, y, z = self.x, self.y, self.z
    local len_sqr = x*x + y*y + z*z
    
    if len_sqr <= EPSILON then
        return Vector(0, 0, 0)
    end
    
    local inv_len = fast_inv_sqrt(len_sqr)
    return Vector(x * inv_len, y * inv_len, z * inv_len)
end

-- Fast dot product
function vec:Dot(other)
    return self.x * other.x + self.y * other.y + self.z * other.z
end

-- Cross product
function vec:Cross(other)
    return Vector(
        self.y * other.z - self.z * other.y,
        self.z * other.x - self.x * other.z,
        self.x * other.y - self.y * other.x
    )
end

-- Linear interpolation
function vec:Lerp(other, t)
    local inv_t = 1 - t
    return Vector(
        self.x * inv_t + other.x * t,
        self.y * inv_t + other.y * t,
        self.z * inv_t + other.z * t
    )
end

-- Check if vector is zero (within epsilon)
function vec:IsZero()
    return abs(self.x) <= EPSILON and abs(self.y) <= EPSILON and abs(self.z) <= EPSILON
end

-- Clamp vector components
function vec:Clamp(min_vec, max_vec)
    self.x = min(max(self.x, min_vec.x), max_vec.x)
    self.y = min(max(self.y, min_vec.y), max_vec.y)
    self.z = min(max(self.z, min_vec.z), max_vec.z)
end

-- Get clamped copy
function vec:GetClamped(min_vec, max_vec)
    return Vector(
        min(max(self.x, min_vec.x), max_vec.x),
        min(max(self.y, min_vec.y), max_vec.y),
        min(max(self.z, min_vec.z), max_vec.z)
    )
end