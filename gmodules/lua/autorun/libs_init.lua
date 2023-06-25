local function AddFilesFromFolder(folder)
	local files = file.Find(folder .. "/*.lua", "LUA")
	for _, filename in ipairs(files) do
		local filepath = folder .. "/" .. filename
		AddCSLuaFile(filepath)
		include(filepath)
	end
end

local function LibsInit()
	local folders = {
		"libs",
		"extentions",
		"modules"
	}

	for _, folder in ipairs(folders) do
		AddFilesFromFolder(folder)
	end
end

hook.Add("PostGamemodeLoaded", "LibsInit", LibsInit)
LibsInit()
