local doublepi, halfpi, pi = math.pi * 2, math.pi * 0.5, math.pi
local a = -0.255
local b = 1.27323954
local c = 0.405284735

function math.rad(n)
  return n * pi / 180
end

function math.deg(n)
  return n * 180 / pi
end

function math.min(...)
  local t = {...}
  table.sort(t)
  return t[1]
end

function math.max(...)
  local t = {...}
  table.sort(t, function(a, b) return a > b end)
  return t[1]
end

function math.SharedRandom(l, h)
  l = l or 0
  h = h or l or 0xFFFFFF
  return math.floor(math.random() * (h - l + 1) + l)
end

function math.Clamp(n, l, h)
  return n < l and l or (n > h and h or n)
end

function math.sin_cos(n)
    n = n % doublepi
    if n < -pi then
        n = n + doublepi
    elseif n > pi then
        n = n - doublepi
    end

    local x2 = n * n
    local sin = n * (1 + x2 * (a + x2 * b))
    local cos = 1 + x2 * (a + x2 * c)

    return sin, cos
end

function math.sin(n)
    return math.sin_cos(n)
end

function math.cos(n)
    _, cos = math.sin_cos(n)
    return cos
end

function math.sinf(n)
    local n = n % doublepi

    if n < -pi then
        n = n + doublepi
    elseif n > pi then
        n = n - doublepi
    end

    if n < 0 then
        return n * (1.27323954 + 0.405284735 * n)
    else
        return n * (1.27323954 - 0.405284735 * n)
    end
end

function math.cosf(n)
    return math.sinf(n + halfpi)
end
