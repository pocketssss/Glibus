-- Optimized Glibus Library Initialization System
-- Loads all optimization libraries in correct order

local function LibsInit()
	local files = {
		-- Configuration system (load first)
		"libs/config.lua",
		
		-- Core utilities
		"libs/math.lua",
		"libs/table.lua",
		"libs/vector.lua",
		"libs/util.lua",
		"libs/file.lua",
		
		-- Memory management (load early)
		"libs/collector.lua",
		
		-- Networking and communication
		"libs/net.lua",
		"libs/networking.lua",
		
		-- Performance systems
		"libs/hook_optimized.lua",  -- Use optimized version
		"libs/physics.lua",
		"libs/render.lua",
		"libs/entity_manager.lua",
		"libs/database.lua",
		
		-- Monitoring (load last)
		"libs/performance_monitor.lua"
	}

	local start_time = SysTime()
	local loaded_count = 0
	
	print("[GLIBUS] Starting library initialization...")

	for i = 1, #files do
		local filepath = files[i]
		local file_start = SysTime()
		
		-- Add to client download
		AddCSLuaFile(filepath)
		
		-- Include on server/client
		local success, error_msg = pcall(include, filepath)
		
		if success then
			loaded_count = loaded_count + 1
			local load_time = SysTime() - file_start
			print(string.format("[GLIBUS] ✓ Loaded %s (%.3fs)", filepath, load_time))
		else
			print(string.format("[GLIBUS] ✗ Failed to load %s: %s", filepath, error_msg))
		end
	end

	local total_time = SysTime() - start_time
	print(string.format("[GLIBUS] Library initialization complete: %d/%d files loaded in %.3fs", 
		loaded_count, #files, total_time))
	
	-- Initialize performance monitoring
	if SERVER then
		timer.Simple(1, function()
			print("[GLIBUS] Performance monitoring systems active")
			
			-- Log initial memory state
			if MemoryManager then
				local stats = MemoryManager.stats()
				print(string.format("[GLIBUS] Initial memory usage: %.2fKB", stats.current_usage_kb))
			end
		end)
	end

	files = nil
end

-- Load immediately and on gamemode load
LibsInit()
hook.Add("PostGamemodeLoaded", "GlibusLibsInit", LibsInit)
