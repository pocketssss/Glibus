-- Optimized Rendering Library for Garry's Mod
-- Maximum performance for HUD, 3D2D, and material operations

-- Cache frequently used functions
local render = render
local surface = surface
local draw = draw
local cam = cam
local Material = Material
local Color = Color
local math_floor, math_ceil = math.floor, math.ceil
local math_min, math_max = math.min, math.max

-- Material cache for better performance
local material_cache = {}
local CACHE_LIMIT = 128

-- Color cache to avoid creating new Color objects
local color_cache = {}
local COLOR_CACHE_SIZE = 64

-- Screen resolution cache
local screen_w, screen_h = ScrW(), ScrH()
local last_screen_check = 0
local SCREEN_CHECK_INTERVAL = 1 -- Check every second

-- Optimized material loading with caching
function render.GetMaterial(path, shader)
    local cache_key = path .. (shader or "")
    
    if material_cache[cache_key] then
        return material_cache[cache_key]
    end
    
    -- Clean cache if it gets too large
    if table.Count(material_cache) >= CACHE_LIMIT then
        material_cache = {}
    end
    
    local mat = Material(path, shader)
    material_cache[cache_key] = mat
    return mat
end

-- Optimized color creation with caching
function render.GetColor(r, g, b, a)
    a = a or 255
    local cache_key = (r * 16777216) + (g * 65536) + (b * 256) + a
    
    if color_cache[cache_key] then
        return color_cache[cache_key]
    end
    
    -- Clean cache if it gets too large
    if table.Count(color_cache) >= COLOR_CACHE_SIZE then
        color_cache = {}
    end
    
    local color = Color(r, g, b, a)
    color_cache[cache_key] = color
    return color
end

-- Fast screen size with caching
function render.GetScreenSize()
    local current_time = CurTime()
    if current_time - last_screen_check > SCREEN_CHECK_INTERVAL then
        screen_w, screen_h = ScrW(), ScrH()
        last_screen_check = current_time
    end
    return screen_w, screen_h
end

-- Optimized rectangle drawing
function render.DrawRect(x, y, w, h, color)
    surface.SetDrawColor(color.r, color.g, color.b, color.a)
    surface.DrawRect(x, y, w, h)
end

-- Optimized outlined rectangle
function render.DrawOutlinedRect(x, y, w, h, thickness, color)
    thickness = thickness or 1
    surface.SetDrawColor(color.r, color.g, color.b, color.a)
    
    -- Top
    surface.DrawRect(x, y, w, thickness)
    -- Bottom  
    surface.DrawRect(x, y + h - thickness, w, thickness)
    -- Left
    surface.DrawRect(x, y, thickness, h)
    -- Right
    surface.DrawRect(x + w - thickness, y, thickness, h)
end

-- Optimized circle drawing using cached points
local circle_cache = {}
function render.DrawCircle(x, y, radius, segments, color)
    segments = segments or 32
    local cache_key = radius * 1000 + segments
    
    if not circle_cache[cache_key] then
        local points = {}
        local angle_step = (math.pi * 2) / segments
        
        for i = 0, segments do
            local angle = i * angle_step
            points[i + 1] = {
                x = math.cos(angle) * radius,
                y = math.sin(angle) * radius
            }
        end
        circle_cache[cache_key] = points
    end
    
    local points = circle_cache[cache_key]
    surface.SetDrawColor(color.r, color.g, color.b, color.a)
    
    for i = 1, #points - 1 do
        surface.DrawLine(
            x + points[i].x, y + points[i].y,
            x + points[i + 1].x, y + points[i + 1].y
        )
    end
end

-- Optimized text rendering with size caching
local text_size_cache = {}
function render.DrawText(text, font, x, y, color, align_x, align_y)
    surface.SetFont(font)
    surface.SetTextColor(color.r, color.g, color.b, color.a)
    
    local cache_key = text .. font
    local text_w, text_h = text_size_cache[cache_key] and 
        text_size_cache[cache_key].w, text_size_cache[cache_key].h
    
    if not text_w then
        text_w, text_h = surface.GetTextSize(text)
        text_size_cache[cache_key] = {w = text_w, h = text_h}
    end
    
    -- Apply alignment
    if align_x == TEXT_ALIGN_CENTER then
        x = x - text_w / 2
    elseif align_x == TEXT_ALIGN_RIGHT then
        x = x - text_w
    end
    
    if align_y == TEXT_ALIGN_CENTER then
        y = y - text_h / 2
    elseif align_y == TEXT_ALIGN_BOTTOM then
        y = y - text_h
    end
    
    surface.SetTextPos(x, y)
    surface.DrawText(text)
    
    return text_w, text_h
end

-- Optimized 3D2D rendering context
local cam_start = cam.Start3D2D
local cam_end = cam.End3D2D

function render.Start3D2D(pos, angles, scale)
    cam_start(pos, angles, scale)
end

function render.End3D2D()
    cam_end()
end

-- Batch rendering for multiple similar objects
local batch_queue = {}
function render.QueueRect(x, y, w, h, color)
    table.insert(batch_queue, {
        type = "rect",
        x = x, y = y, w = w, h = h,
        color = color
    })
end

function render.FlushBatch()
    for _, item in ipairs(batch_queue) do
        if item.type == "rect" then
            render.DrawRect(item.x, item.y, item.w, item.h, item.color)
        end
    end
    batch_queue = {}
end

-- Performance monitoring
local render_stats = {
    draw_calls = 0,
    material_loads = 0,
    cache_hits = 0
}

function render.GetStats()
    return render_stats
end

function render.ResetStats()
    render_stats = {
        draw_calls = 0,
        material_loads = 0,
        cache_hits = 0
    }
end

-- Cleanup function to prevent memory leaks
function render.Cleanup()
    material_cache = {}
    color_cache = {}
    text_size_cache = {}
    circle_cache = {}
    batch_queue = {}
end