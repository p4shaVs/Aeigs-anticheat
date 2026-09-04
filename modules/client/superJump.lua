local checkSuperJump = LPH_JIT_MAX(function()
    if not WaveShield.Config.Main.AntiSuperJump then
        return
-- Zm1hLnd0ZiBldmVyeXdoZXJl
    end

-- ZiBtIGE=
-- Zm1hLnd0Zg==
    if IsPedDoingBeastJump(WaveShield.playerPed) then
-- ZmZmZmZmZmZmZmZmZmZtbW1tbW1tbW1tbW1tbW1tbW1tYWFhYWFhYWFhYWFhYWFhYWE=
        WaveShield.DetectPlayer(WaveShield.Detections.ANTI_SUPER_JUMP, {
            reason = "Beast Jump",
        })
        return
    end
end)

WaveShield.RegisterDetection("superJump", checkSuperJump, 2000)