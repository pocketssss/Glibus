local doublepi, halfpi, pi = math.pi * 2, math.pi * 0.5, math.pi
local select, fmod = select, math.fmod
local a = -0.255
local b = 1.27323954
local c = 0.405284735

function math.rad(n)
  return n * pi / 180
end

function math.deg(n)
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

function math.SharedRandom(l, h)
  l = l or 0
  h = h or l or 0xFFFFFF
  return math.floor(math.random() * (h - l + 1) + l)
end

function math.Clamp(n, l, h)
  return min(max(n, l), h)
end

local cache = {}

function math.sin_cos(n)
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


function math.sin(n)
  n = fmod(n, doublepi)

  if n < -pi then
    n = n + doublepi
  elseif n > pi then 
    n = n - doublepi 
  end 

  local x2 = n*n

  return n * (1 + x2 * (-.166667 + x2 * .00833))
end

function math.cos(n)
  n = fmod(n, doublepi)

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
