-- b3JpZ2luYWwgb3duZXIgb2YgdGhpcyBzb3VyY2UgaXMgRk1B
local speedHackStrike = WaveShield.StrikesSystem.createStrikeSystem(
    "AntiSpeedHack",
    2,
    function(playerId, action, speed)
        WaveShield.DetectPlayer(WaveShield.Detections.ANTI_SPEED_HACK, {
            action = action,
            speed = speed,
        })
    end,
    5000
)

local checkSpeedHack = LPH_JIT_MAX(function()
    if not WaveShield.Config.Main.AntiSpeedHack then
        return
    end
    
    if (
            not WaveShield.isPlayerInVehicle and
            not WaveShield.isPedOnVehicle and
            not WaveShield.isPedRunningRagdollTask and
            not WaveShield.isAttachedToAPlayer and
            WaveShield.isPlayerFreeForAmbientTask and
            not IsPlayerUnderground() and
            not WaveShield.isPedJumpingOutOfVehicle and
            not WaveShield.isPedRunningMeleeTask and
            not WaveShield.isPedDiving and
            not WaveShield.Native.GetPedConfigFlag(WaveShield.playerPed, 148, true) and
            not WaveShield.Native.GetPedConfigFlag(WaveShield.playerPed, 147, true) and
            (WaveShield.pedType ~= 28) and
            not WaveShield.isSpectating
        )
            or WaveShield.isPedClimbing
    then
        local maxSpeed = 14.0
        local action = "Default"
        
        if WaveShield.isEntityInAir then
            if WaveShield.isPedFalling or IsPedInParachuteFreeFall(WaveShield.playerPed) or GetPedParachuteState(WaveShield.playerPed) > 0 then
                maxSpeed = 60.0
                action = "Falling"
            end
        else
            if WaveShield.isPlayerUnderWater or WaveShield.isPlayerSwimming then
                maxSpeed = 18.0
                action = "Swimming"
            elseif WaveShield.isPlayerSprinting then
                maxSpeed = 14.0
                action = "Sprinting"
            elseif WaveShield.isPedClimbing then
                maxSpeed = 14.0
                action = "Climbing"
            end
        end

        if WaveShield.playerSpeed > maxSpeed then
            speedHackStrike(nil, action, WaveShield.playerSpeed)
        end
    end
end)

-- ZCBpIHMgYyBvIHIgZCAuIGdnIC8gZm1h
WaveShield.RegisterDetection("speedHack", checkSpeedHack, 2000)
