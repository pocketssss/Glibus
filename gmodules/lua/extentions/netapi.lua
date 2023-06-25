local NetMessage = {}
NetMessage.__index = NetMessage

function NetMessage.new(name)
    local self = setmetatable({}, NetMessage)
    self.name = name
    self.data = {}
    return self
end

function NetMessage:AddParam(param)
    table.insert(self.data, param)
end

function NetMessage:Send(receiver)
    net.Start(self.name)

    for _, param in ipairs(self.data) do
        net.WriteType(param)
    end

    net.Send(receiver)
end

local EmptyNetMessage = {}
EmptyNetMessage.__index = EmptyNetMessage

function EmptyNetMessage.new(name)
    local self = setmetatable({}, EmptyNetMessage)
    self.name = name
    return self
end

function EmptyNetMessage:Send(receiver)
    net.Start(self.name)
    net.Send(receiver)
end

local function ReadNetMessage()
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

return {
    NetMessage = NetMessage,
    EmptyNetMessage = EmptyNetMessage,
    ReadNetMessage = ReadNetMessage
}


-- local NetAPI = require("netapi")
-- local message = NetAPI.NetMessage.new("example_message")
-- message:AddParam("param1")
-- message:AddParam("param2")
-- message:Send(receiver)

-- local emptyMessage = NetAPI.EmptyNetMessage.new("empty_message")
-- emptyMessage:Send(receiver)

-- local receivedMessage = NetAPI.ReadNetMessage()
-- print(receivedMessage.name)
-- for i, param in ipairs(receivedMessage.data) do
--     print("Param", i, ":", param)
-- end
