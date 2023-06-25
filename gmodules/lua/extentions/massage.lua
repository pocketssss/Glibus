-- Example 
-- Example
-- Example

-- local CraftItem = NetMessage("CraftItem")
-- CraftItem:AddParam(50)
-- CraftItem:AddParam("sword_super")
-- CraftItem:Send(player)

-- Example 
-- Example
-- Example

function NetMessage(name)
    local message = {
        name = name,
        data = {}
    }

    function message:AddParam(param)
        table.insert(self.data, param)
    end

    function message:Send(receiver)
        net.Start(self.name)

        for _, param in ipairs(self.data) do
            net.WriteType(param)
        end

        net.Send(receiver)
    end

    return message
end

function CreateEmptyNetMessage(name)
    local message = {
        name = name
    }

    function message:Send(receiver)
        net.Start(self.name)
        net.Send(receiver)
    end

    return message
end

function ReadNetMessage()
    local message = {
        name = net.ReadString(),
        data = {}
    }

    local numParams = net.ReadUInt(8)
    for i = 1, numParams do
        table.insert(message.data, net.ReadType())
    end

    return message
end
