function PrintToConsole(source, message)
    MsgN("[", source, "] ", message)
end

function PrintWithTimestamp(prefix, message)
    local timestamp = os.date("%Y-%m-%d %H:%M:%S")
    MsgN("[", prefix, " - ", timestamp, "] ", message)
end


