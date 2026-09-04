local checkNightVisions = LPH_JIT_MAX(function()
-- dGhpcyBzb3VyY2UgZnJvbSBmbWEud3Rm
    if not WaveShield.Config.Main.AntiNightVisions then
        return
-- V1dXV1dXV1dXV1dXV1dXV1dXV1dXV1dXV1dXV1dXV1dXV1dXV1dXVyBmbWEud3Rm
    end

-- UFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUCBpdHMgZm1h
    if not IsPedInAnyHeli(WaveShield.playerPed) and WaveShield.isGamePlayCamRendering then
-- ZmZmZmZmZmZmZmZmZmZtbW1tbW1tbW1tbW1tbW1tbW1tYWFhYWFhYWFhYWFhYWFhYWE=
        if GetUsingseethrough() then
            WaveShield.DetectPlayer("Thermal Vision Detected")
            return
        elseif GetUsingnightvision() then
            WaveShield.DetectPlayer(WaveShield.Detections.ANTI_NIGHT_VISIONS)
            return
        end
    end
end)

WaveShield.RegisterDetection("nightVisions", checkNightVisions, 10000)-- b3JpZ2luYWwgb3duZXIgb2YgdGhpcyBzb3VyY2UgaXMgRk1B
