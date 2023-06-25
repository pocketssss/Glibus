function IncludeFolder(folderPath)
    local files = file.Find(folderPath .. "/*.lua", "LUA")

    for _, fileName in ipairs(files) do
        include(folderPath .. "/" .. fileName)
    end
end
