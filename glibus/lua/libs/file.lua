local function sanitizePath(input)
    return input:gsub("[^%w%-_]", "")
end

local function fileRead(filename, path)
    path = path or "DATA"
    path = sanitizePath(path)
    filename = sanitizePath(filename)

    local f = file.Open(filename, "rb", path)
    if not f then
        ErrorNoHalt("Failed to open file for reading: " .. filename)
        return
    end

    local size = f:Size()
    local str
    local success, err = pcall(function()
        str = f:Read(size)
    end)

    f:Close()

    if not success then
        ErrorNoHalt("Error reading file: " .. err)
    end

    return str or ""
end

local function fileWrite(filename, contents)
    local f = file.Open(filename, "wb", "DATA")
    if not f then return end
    f:Write(contents)
    f:Close()
end
  
local function fileAppend(filename, contents)
    local f = file.Open(filename, "ab", "DATA")
    if not f then return end
    f:Write(contents)
    f:Close()
end
