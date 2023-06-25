local ang = FindMetaTable("Angle")
local sin, cos, atan2 = math.sin, math.cos, math.atan2

function ang:Forward()
    local pitch, yaw = self.p, self.y
    local p = sin(pitch)
    local y = cos(pitch) * cos(yaw)
    local r = cos(pitch) * sin(yaw)
    return Vector(y, r, p) -- x y z ???
end

function ang:Up()
    local pitch, yaw, roll = self.p, self.y, self.r
    local p = -sin(pitch) * cos(roll)
    local y = cos(pitch) * sin(roll) * cos(yaw) - sin(yaw) * sin(roll)
    local r = cos(pitch) * cos(roll) * cos(yaw) + sin(yaw) * sin(roll)
    return Vector(y, r, p)
end

function ang:Right()
    local pitch, yaw, roll = self.p, self.y, self.r
    local p = sin(pitch) * sin(roll)
    local y = -cos(pitch) * sin(roll) * cos(yaw) + sin(yaw) * cos(roll)
    local r = -cos(pitch) * sin(roll) * sin(yaw) - cos(yaw) * cos(roll)
    return Vector(y, r, p)
end
