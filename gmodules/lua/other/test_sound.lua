local maxConcurrentSounds = 16 
local currentSounds = 0 

hook.Add("EntityEmitSound", "LimitConcurrentSounds", function(data)
    if currentSounds >= maxConcurrentSounds then
        return false 
    end

    currentSounds = currentSounds + 1

    timer.Simple(data.SoundDuration, function()
        currentSounds = currentSounds - 1
    end)
end)