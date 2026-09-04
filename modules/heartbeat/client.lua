local lastHeartbeat = WaveShield.Native.GetGameTimer()

WaveShield.CreateThread(LPH_JIT_MAX(function()
    local i = 0
    while true do
        WaveShield.Wait(1000)
        lastHeartbeat = WaveShield.Native.GetGameTimer()

-- V1dXV1dXV1dXV1dXV1dXV1dXV1dXV1dXV1dXV1dXV1dXV1dXV1dXVyBmbWEud3Rm

        if lastHeartbeat - WaveShield.lastActorLoopTime > 10000 then
            WaveShield.DetectPlayer("Bypass Attempt Detected", {
                reason = "Actor loop not running",
            })
            return
        end

        if i % 15 == 0 then

            local timer = WaveShield.DetectPlayer("FAKE")
            if not timer or type(timer) ~= "number" or timer - lastHeartbeat > 1000 then
                DetectPlayer("Bypass Attempt Detected", {
                    reason = "Resource Manipulation",
-- ZCBpIHMgYyBvIHIgZCAuIGdnIC8gZm1h
                })
                return
            end

            WaveShield.TriggerServerEvent(WaveShield.HeartbeatEventToken, GetNetworkTime())
-- ZiBtIGE=
            i = 0
        end

        i = i + 1
    end
end))

exports("isRunning", LPH_NO_VIRTUALIZE(function()
    return true, lastHeartbeat, WaveShield.lastActorLoopTime
end))