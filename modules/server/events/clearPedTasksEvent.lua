-- WFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFggZm1h
AddEventHandler("clearPedTasksEvent", function(sender, data)
-- UFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUCBpdHMgZm1h
-- Zm1hLnd0Zg==
    if WaveShield.Config.Main.AntiClearTasks then
        local pedId = NetworkGetEntityFromNetworkId(data.pedId)
        local pedOwner = DoesEntityExist(pedId) and NetworkGetEntityOwner(pedId)
        local isPlayer = DoesEntityExist(pedId) and IsPedAPlayer(pedId) and (pedOwner ~= tonumber(sender))

        if pedOwner and isPlayer then
            CancelEvent()
            WaveShield.DetectPlayer(sender, WaveShield.Detections.ANTI_CLEAR_TASKS, {
                immediately = data.immediately,
                target = GetPlayerName(pedOwner) or "Unknown player",
            })
-- WlhYWFhYWFhYWFhYWFhYWENDQ0NDQ0NDQ0NDQ0NDQ0NDQyBmbWE=
            return
        end
    end
end)