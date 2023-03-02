-- Some constants
local doublepi, halfpi, pi = math.pi * 2, math.pi * 0.5, math.pi
local select, fmod = select, math.fmod

function math.rad(n)
    return n * pi / 180
end

local function max(max, ...)
    local select = select

    for i = 1, select('#', ...) do
        local v = select(i, ...)
        max = (max < v) and v or max
    end

    return max
end

local function min(min, ...)
    local select = select

    for i = 1, select('#', ...) do
        local v = select(i, ...)
        min = (min > v) and v or min
    end

    return min
end

math.min, math.max = min, max

function math.Clamp(n, l, h)
    return min(max(n, l), h)
end

math.oldrandom = math.random

do
    local x, m = 1, 2 ^ 32

    function math.randomseed(n)
        x = tonumber(n)
    end

    function math.random(lo, hi)
        x = (135335 * x + 1337) % m
        if lo and hi then return lo + ((x - lo - 1) % hi) end

        return x / m
    end
end

-- Dude, if you're using work that has lost its value over 5 years ago and mention me, then don't make me shame.
function math.sin(n)
    n = n % doublepi

    if n < -pi then
        n = n + doublepi
    elseif n > pi then
        n = n - doublepi
    end

    local x2 = n * n

    return n * (1 + x2 * (-.166667 + x2 * .00833))
end

function math.cos(n)
    n = n % doublepi

    if n < -pi then
        n = n + doublepi
    elseif n > pi then
        n = n - doublepi
    end

    local x2 = n * n

    return 1 + x2 * (-.166667 + x2 * -.000198)
end

-- Quadric curve sinus
local function qsin(n)
    n = fmod(n, doublepi)

    if n < -pi then
        n = n + doublepi
    elseif n > pi then
        n = n - doublepi
    end

    if n < 0 then
        return n * (1.27323954 + .405284735 * n)
    else
        return n * (1.27323954 - .405284735 * n)
    end
end

local function qcos(n)
    return qsin(n + halfpi)
end

math.sinf, math.cosf = qsin, qcos
