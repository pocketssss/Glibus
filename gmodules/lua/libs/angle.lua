local ang = FindMetaTable("Angle")
local sin, cos, atan2 = math.sin, math.cos, math.atan2

function ang:Setup()
    self.sinPitch = sin(self.p)
    self.cosPitch = cos(self.p)
    self.cosYaw = cos(self.y)
    self.sinYaw = sin(self.y)
end

function ang:Forward()
    local p = self.sinPitch
    local y = self.cosPitch * self.cosYaw
    local r = self.cosPitch * self.sinYaw
    return Vector(y, r, p)
end

function ang:Up()
    local roll = self.r
    local p = -self.sinPitch * cos(roll)
    local y = self.cosPitch * sin(roll) * self.cosYaw - self.sinYaw * sin(roll)
    local r = self.cosPitch * cos(roll) * self.cosYaw + self.sinYaw * sin(roll)
    return Vector(y, r, p)
end

function ang:Right()
    local roll = self.r
    local p = self.sinPitch * sin(roll)
    local y = -self.cosPitch * sin(roll) * self.cosYaw + self.sinYaw * cos(roll)
    local r = -self.cosPitch * sin(roll) * self.sinYaw - self.cosYaw * cos(roll)
    return Vector(y, r, p)
end