local function LibsInit()
	local files = {
		"libs/file.lua",
		"libs/hook.lua",
		"libs/math.lua",
		"libs/net.lua",
		"libs/table.lua",
		"libs/util.lua",
		"libs/collector.lua",
		"libs/vector.lua" 
	}

	for i = 1, #files do
		local filepath = files[i]
		AddCSLuaFile(filepath)
		include(filepath)
	end

	files = nil
end

hook.Add("PostGamemodeLoaded", "LibsInit", LibsInit)
LibsInit()
