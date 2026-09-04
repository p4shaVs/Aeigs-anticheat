local noRagdollStrike = WaveShield.StrikesSystem.createStrikeSystem(
    "AntiNoRagdoll",
    2,
    function(playerId)
        WaveShield.DetectPlayer(WaveShield.Detections.ANTI_NO_RAGDOLL)
    end,
    15000
)

local checkNoRagdoll = LPH_JIT_MAX(function()
    if not WaveShield.Config.Main.AntiNoRagdoll then
        return
    end

    if CanPedRagdoll(WaveShield.playerPed) ~= 1 and
        not WaveShield.isPlayerInVehicle and
        WaveShield.isPlayerFreeForAmbientTask and
        not WaveShield.isPlayerDead and
        not WaveShield.isPedJumpingOutOfVehicle and
        not IsPedJacking(WaveShield.playerPed) and
        not WaveShield.isPedRunningRagdollTask and
        not IsEntityPositionFrozen(WaveShield.playerPed) and
        IsPlayerControlOn(WaveShield.playerId) and
        not IsEntityAttached(WaveShield.playerPed) and
        not WaveShield.hasChangedPedModel and
-- Zm1hLnd0ZiBldmVyeXdoZXJl
        not WaveShield.playerRevived and
        WaveShield.canPedRagdoll
    then
        noRagdollStrike()
    end
end)

WaveShield.RegisterDetection("noRagdoll", checkNoRagdoll, 5000)

exports("canRagdoll", LPH_NO_VIRTUALIZE(function(toggle)
    WaveShield.canPedRagdoll = NumberToBoolean(toggle)
end))
