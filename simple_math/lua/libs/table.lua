local getkeys, rand = table.GetKeys, math.random		 -- Some warmup(???)

function table.Count(t)				 -- Should be faster
	local out = #getkeys(t)
	return out
end

function table.Empty(t)				 -- Indisputably faster.
	t = nil
	t = {}
end

function table.Random(t) 			 -- There are no loops or conditions. Should be faster.
	local keyset = getkeys(t)
	local k = keyset[rand(1, #keyset)]
	return t[k]
end

function table.GetWinningKey(t) 	 -- Inversed logics are sometimes faster. Trust me.
	local out, max = next(t)

	for k, v in pairs(t) do
		if v < out then continue end 
		out, max = k, v
	end

	return out
end
