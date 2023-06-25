local function fileRead(filename, path)
    path = path or "DATA"

    local f = file.Open(filename, "rb", path)
    if not f then return end

    local size = f:Size()
    local str = f:Read(size)

    f:Close()

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
