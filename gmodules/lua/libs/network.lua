net.Send = function(ply, name, data, unreliable)
    local compressedData = util.Compress(data)
    if compressedData and #compressedData < #data then
        data = compressedData
        net.WriteBool(true) 
    else
        net.WriteBool(false) 
    end
    net.WriteUInt(#data, 32)
    net.WriteData(data, #data)
end

local origReadData = net.ReadData
net.ReadData = function(len)
    local compressed = net.ReadBool()
    local dataLen = net.ReadUInt(32)
    if compressed then
        local compressedData = net.ReadData(dataLen)
        return util.Decompress(compressedData)
    else
        return origReadData(len)
    end
end