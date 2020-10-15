--Some constants
local doublepi, halfpi, pi = 	math.pi * 2, 
								math.pi * 0.5,
								math.pi
--Calculating degrees and radians with easier way

function math.rad(n)
	return	 (n % 360) * 0.0174533
end

function math.deg(n)
	return	 (n % doublepi) / 0.0174533
end

--Some common math functions optimisation.

function math.min( ... )	 -- No conditions. Should be faster.
	local t = {...}
	local n = t[1]

	for i = 2, #t do
		local v = t[i]
		n = n > v and v or n
	end

	return n
end

function math.max( ... )	 -- Same.
	local t = {...}
	local n = t[1]

	for i = 2, #t do
		local v = t[i]
		n = n > v and n or v
	end

	return n
end

--Warmup jit BC
local min, max, floor, ceil, round, abs = math.min, math.max, math.floor, math.ceil, math.Round, math.abs

function math.SharedRandom(l, h)
	local l, h = l or 0, h or l or 0xFFFFFF
	local d = h - l
	local x = (CurTime() * 3212377613) % d
	return floor(x + l)
end

function math.Clamp(n, l, h) 	-- Warmed jit bc. Faster than C++ library.
	return	 min(max(n, l), h)
end

function math.sqrt(n) 			-- Same.
	return	 n ^ 0.5
end
--Sine Cos optimisation by quadratic curve. Lua adaptation of http://www.mclimatiano.com/faster-sine-approximation-using-quadratic-curve/.

function math.sin(n)
	local n = n % doublepi

	if n < -pi then
		n = n + doublepi
	elseif n > pi then
		n = n - doublepi
	end

	local out = 0
	if n < 0 then
		out = n * (1.27323954 + 0.405284735 * n)

		if out < 0 then
			out = out * (-0.255 * (out + 1) + 1)
		else
			out = out * (0.255 * (out - 1) + 1)
		end
	else
		out = n * (1.27323954 - 0.405284735 * n)
 
		if out < 0 then
			out = out * (-0.255 * (out + 1) + 1)
		else
			out = out * (0.255 * (out - 1) + 1)
		end
	end
 
	return out
end

function math.cos(n)
	return math.sin(n + halfpi)
end

--Same, but not so accurate.
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
		return n * ( 1.27323954 - 0.405284735 * n)
	end
end

function math.cosf(n)
	return math.sinf(n + halfpi)
end
