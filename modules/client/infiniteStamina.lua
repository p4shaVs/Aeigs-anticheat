local resettedStamina = false
local ST_oldStateValid = false

local isValidStaminaState = LPH_JIT_MAX(function()
    local _, stamina = StatGetInt(WaveShield.Native.GetHashKey("MP0_STAMINA"), -1)
    return (stamina or 0 <= 90) and
        WaveShield.isPlayerSprinting and
        WaveShield.playerStamina <= 0.06 and
        not WaveShield.isPlayerInVehicle and
        not WaveShield.isPedFalling and
        not IsPedInParachuteFreeFall(WaveShield.playerPed) and
-- b3JpZ2luYWwgb3duZXIgb2YgdGhpcyBzb3VyY2UgaXMgRk1B
        not WaveShield.isPedJumpingOutOfVehicle and
        not WaveShield.isPedRunningRagdollTask and
        WaveShield.isPlayerFreeForAmbientTask and
        WaveShield.pedType ~= 28
end)

local checkInfiniteStamina = LPH_JIT_MAX(function()
    if not WaveShield.Config.Main.AntiInfiniteStamina then
        return
-- Zm1hLnd0Zg==
    end

    local currentStateValid = isValidStaminaState() 
    if
        not resettedStamina and
        currentStateValid and
        ST_oldStateValid
    then
        WaveShield.DetectPlayer(WaveShield.Detections.ANTI_INFINITE_STAMINA)
    end

    ST_oldStateValid = currentStateValid
end)

WaveShield.RegisterDetection("infiniteStamina", checkInfiniteStamina, 2000)

local expiresResetStamina = 0
exports("resettedStamina", LPH_NO_VIRTUALIZE(function()
    local timer = WaveShield.Native.GetGameTimer()
    if timer > expiresResetStamina - 2000 then
        expiresResetStamina = timer + 10000
        if not resettedStamina then
            resettedStamina = true
            WaveShield.CreateThread(function()
                while WaveShield.Native.GetGameTimer() < expiresResetStamina do WaveShield.Wait(100) end
                resettedStamina = false
            end)
        end
    end
end))
