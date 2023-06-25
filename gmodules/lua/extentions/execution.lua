function DelayedExecution(delay, callback)
    timer.Simple(delay, callback)
end

function RepeatedExecution(name, interval, repetitions, callback)
    timer.Create(name, interval, repetitions, callback)
end
