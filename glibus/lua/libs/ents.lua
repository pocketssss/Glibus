function ents.FindByClassAndParent(classname, entity)
    if not IsValid(entity) then
        return
    end

    local list = ents.FindByClass(classname)
    if not list then
        return
    end

    local out = {}
    local entityIndex = entity:EntIndex() 

    for i = 1, #list do
        local v = list[i]

        if IsValid(v) and v:GetParent() == entityIndex then
            table.insert(out, v)
        end
    end

    if #out == 0 then
        return
    end

    return out
end
