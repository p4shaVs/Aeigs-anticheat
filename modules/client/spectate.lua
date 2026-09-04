local checkSpectate = LPH_JIT_MAX(function()
    if not WaveShield.Config.Main.AntiSpectate then
        return
    end
    
    if not WaveShield.isSpectating and WaveShield.isNetworkInSpectatorMode then
        WaveShield.DetectPlayer(WaveShield.Detections.ANTI_SPECTATE)
    end
end)

WaveShield.RegisterDetection("spectate", checkSpectate, 5000)

exports("setSpectatorMode", LPH_NO_VIRTUALIZE(function(toggle)
    WaveShield.isSpectating = toggle
end))
-- WFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFggZm1h
