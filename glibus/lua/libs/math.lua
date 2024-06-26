local pi = math.pi
local doublepi = pi * 2
local halfpi = pi * 0.5

local select = select
local fmod = math.fmod
local random = math.random

local a = -0.255
local b = 1.27323954
local c = 0.405284735

math.huge = 1 + 2 ^ 64 -- fix boneclipping in PAC3

local function math.rad(n)
  return n * pi / 180
end

local function math.deg(n)
  return n * 180 / pi
end

local function max(max, ...)
  for i = 1, select('#', ...) do
    local v = select(i, ...)
    max = (max < v) and v or max
  end
  return max
end

local function min(min, ...)
  for i = 1, select('#', ...) do
    local v = select(i, ...)
    min = (min > v) and v or min
  end
  return min
end

local function math.SharedRandom(l, h)
  l = l or 0
  h = h or l or 0xFFFFFF
  return math.floor(random() * (h - l + 1) + l)
end

local function math.Clamp(n, l, h)
  return min(max(n, l), h)
end

local cache = {}

local function math.sin_cos(n)
  n = fmod(n, doublepi)
  if n < -pi then
    n = n + doublepi
  elseif n > pi then
    n = n - doublepi
  end

  if cache[n] then
    return cache[n].sin, cache[n].cos
  end

  local x2 = n * n
  local sin = n * (1 + x2 * (a + x2 * b))
  local cos = 1 + x2 * (a + x2 * c)

  cache[n] = {sin = sin, cos = cos}

  return sin, cos
end

local function math.sin(n)
  n = fmod(n, doublepi)

  if n < -pi then
    n = n + doublepi
  elseif n > pi then
    n = n - doublepi
  end

  local x2 = n * n

  return n * (1 + x2 * (-.166667 + x2 * .00833))
end

local function math.cos(n)
  n = fmod(n, doublepi)

  if n < -pi then
    n = n + doublepi
  elseif n > pi then
    n = n - doublepi
  end

  local x2 = n * n

  return 1 + x2 * (-.166667 + x2 * -.000198)
end

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
