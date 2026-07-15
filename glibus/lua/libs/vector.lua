local vec = FindMetaTable("Vector")
local Vector = Vector
local sqrt = math.sqrt

local function clamp(n, l, h)
    return n < l and l or (n > h and h or n)
end

function vec:Clamp(mn, mx)
    local x, y, z    = self:Unpack()
    local ax, ay, az = mn:Unpack()
    local bx, by, bz = mx:Unpack()
    self:SetUnpacked(clamp(x, ax, bx), clamp(y, ay, by), clamp(z, az, bz))
    return self
end

function vec:GetClamped(mn, mx)
    local x, y, z    = self:Unpack()
    local ax, ay, az = mn:Unpack()
    local bx, by, bz = mx:Unpack()
    return Vector(clamp(x, ax, bx), clamp(y, ay, by), clamp(z, az, bz))
end

function vec:Min(other)
    local x, y, z    = self:Unpack()
    local ox, oy, oz = other:Unpack()
    self:SetUnpacked(
        x < ox and x or ox,
        y < oy and y or oy,
        z < oz and z or oz
    )
    return self
end

-- Length, Distance, Normalize, Dot, Cross, LengthSqr, DistToSqr,
-- GetNormalized, IsZero are intentionally NOT redefined here.
-- They are native C++ engine methods, and any Lua replacement
-- of them is slower.

function vec:Max(other)
    local x, y, z    = self:Unpack()
    local ox, oy, oz = other:Unpack()
    self:SetUnpacked(
        x > ox and x or ox,
        y > oy and y or oy,
        z > oz and z or oz
    )
    return self
end

function vec:GetMin(other)
    local x, y, z    = self:Unpack()
    local ox, oy, oz = other:Unpack()
    return Vector(
        x < ox and x or ox,
        y < oy and y or oy,
        z < oz and z or oz
    )
end

function vec:GetMax(other)
    local x, y, z    = self:Unpack()
    local ox, oy, oz = other:Unpack()
    return Vector(
        x > ox and x or ox,
        y > oy and y or oy,
        z > oz and z or oz
    )
end

function vec:ClampLength(maxlen)
    local x, y, z = self:Unpack()
    local lsq = x * x + y * y + z * z
    if lsq > maxlen * maxlen then
        local s = maxlen / sqrt(lsq)
        self:SetUnpacked(x * s, y * s, z * s)
    end
    return self
end

function vec:GetClampedLength(maxlen)
    local x, y, z = self:Unpack()
    local lsq = x * x + y * y + z * z
    if lsq > maxlen * maxlen then
        local s = maxlen / sqrt(lsq)
        return Vector(x * s, y * s, z * s)
    end
    return Vector(x, y, z)
end

function vec:LerpTo(other, t)
    local x, y, z    = self:Unpack()
    local ox, oy, oz = other:Unpack()
    local it = 1 - t
    self:SetUnpacked(
        x * it + ox * t,
        y * it + oy * t,
        z * it + oz * t
    )
    return self
end
