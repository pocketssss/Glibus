local pi, doublepi, halfpi, fmod, random, abs, floor = math.pi, math.pi * 2, math.pi * 0.5, math.fmod, math.random, math.abs, math.floor
local a_sin, b_sin, a_cos, b_cos, qsin_coeff1, qsin_coeff2 = -0.166667, 0.00833, -0.166667, -0.000198, 1.27323954, 0.405284735

local function normalize_angle(n)
    return n - doublepi * floor((n + pi) / doublepi)
end

local function max(...)
    local m = select(1, ...)
    for i = 2, select('#', ...) do
        local v = select(i, ...)
        if v > m then m = v end
    end
    return m
end

local function min(...)
    local m = select(1, ...)
    for i = 2, select('#', ...) do
        local v = select(i, ...)
        if v < m then m = v end
    end
    return m
end

function math.Clamp(n, l, h)
    return n < l and l or (n > h and h or n)
end

local CACHE_SIZE = 1024
local sin_cache = {}
local cos_cache = {}
local cache_keys = {}

local function add_to_cache(n, sin, cos)
    local key = n % CACHE_SIZE
    sin_cache[key] = sin
    cos_cache[key] = cos
    cache_keys[key] = n
end

local function get_from_cache(n)
    local key = n % CACHE_SIZE
    return cache_keys[key] == n and sin_cache[key] or nil
end

function math.sincos(n)
    n = normalize_angle(n)
    
    local cached_sin = get_from_cache(n)
    if cached_sin then
        return cached_sin, cos_cache[n % CACHE_SIZE]
    end
    
    local x = n
    local x2 = x * x
    local sin = x * (1 + x2 * (a_sin + x2 * b_sin))
    local cos = 1 + x2 * (a_cos + x2 * b_cos)
    
    add_to_cache(n, sin, cos)
    return sin, cos
end

function math.qsin(n)
    n = normalize_angle(n)
    local x = n * (qsin_coeff1 - qsin_coeff2 * abs(n))
    return x - 0.225 * x * (abs(x) - x)
end

function math.qcos(n)
    return math.qsin(n + halfpi)
end

local rad_coeff = pi / 180
local deg_coeff = 180 / pi

function math.rad(n)
    return n * rad_coeff
end

function math.deg(n)
    return n * deg_coeff
end

local rand_state = 1
function math.SharedRandom(l, h)
    l = l or 0
    h = h or l or 0xFFFFFF
    rand_state = (rand_state * 1103515245 + 12345) % 0x7FFFFFFF
    return l + (rand_state % (h - l + 1))
end