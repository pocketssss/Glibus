local function LibsInit()
	local files = {
		"libs/hook.lua",
		"libs/angle.lua",
		"libs/math.lua",
		"libs/table.lua",
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
