function util.IsValidPhysicsObject(ent, num)
    if not ent or (not ent:IsValid() and not ent:IsWorld()) then
        return false
    end

    if not ent:IsWorld() then
        local MoveType = ent:GetMoveType()
        if MoveType ~= MOVETYPE_VPHYSICS and (not ent:GetModel() or not ent:GetModel():StartWith("*")) then
            return false
        end
    end

    local Phys = ent:GetPhysicsObjectNum(num)
    return IsValid(Phys)
end

function util.GetPlayerTrace(ply, dir)
    dir = dir or ply:GetAimVector()

    local trace = {}
    trace.start = ply:EyePos()
    trace.endpos = trace.start + dir * (4096 * 8)
    trace.filter = ply

    return trace
end

function util.QuickTrace(origin, dir, filter)
    local trace = {}
    trace.start = origin
    trace.endpos = origin + dir
    trace.filter = filter

    return util.TraceLine(trace)
end


function util.DateStamp()
    local t = os.date("*t")
    return string.format("%04d-%02d-%02d %02d-%02d-%02d", t.year, t.month, t.day, t.hour, t.min, t.sec)
end

local typeCodes = {
    vector = 1,
    angle = 2,
    float = 3,
    int = 4,
    bool = 5,
    string = 6,
    entity = 7
}

local typeHandlers = {
    [1] = function(str) return Vector(str) end,
    [2] = function(str) return Angle(str) end,
    [3] = function(str) return tonumber(str) end,
    [4] = function(str) return math.Round(tonumber(str)) end,
    [5] = function(str) return tobool(str) end,
    [6] = function(str) return tostring(str) end,
    [7] = function(str) return Entity(str) end
}

function util.StringToType(str, typename)
    typename = typename:lower()
    local typeCode = typeCodes[typename]
    if typeCode then
        local handler = typeHandlers[typeCode]
        return handler(str)
    else
        MsgN("util.StringToType: unknown type \"" .. typename .. "\"!")
    end
end

function util.NiceFloat(f)
    local str = string.format("%f", f)
    str = str:TrimRight("0")
    str = str:TrimRight(".")

    return str
end
