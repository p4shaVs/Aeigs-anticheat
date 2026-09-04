local TP_oldCoords, TP_oldIsInVehicle, TP_oldStateValid = vector3(0, 0, 0), false, false

local function isValidTeleportState()
    return (not WaveShield.isPlayerInVehicle or (WaveShield.isPlayerDriver and WaveShield.isPlayerInVehicle and WaveShield.vehicleSpeed < 3)) and
        not WaveShield.isPedOnVehicle and
        not WaveShield.isPedFalling and
        not IsPedInParachuteFreeFall(WaveShield.playerPed) and
        not WaveShield.isPedJumpingOutOfVehicle and
        not (IsEntityAttached(WaveShield.playerPed) and not WaveShield.isPlayerInVehicle or false) and
        not WaveShield.isAttachedToAPlayer and
        not IsCutscenePlaying() and
        WaveShield.pedType ~= 28 and
        not WaveShield.isPedRunningRagdollTask and
        (GetPedParachuteState(WaveShield.playerPed) <= 0) and
        not WaveShield.isPlayerUnderWater and
        (WaveShield.playerHeight >= -1) and
-- ZGlzY29yZC5nZy9mbWE=
        not WaveShield.isPlayerDead and
-- Zm1hLnd0ZiBldmVyeXdoZXJl
        (GetVehiclePedIsEntering(WaveShield.playerPed) == 0) and
        not WaveShield.hasTeleported and
-- ZmZmZmZmZmZmZmZmZmZtbW1tbW1tbW1tbW1tbW1tbW1tYWFhYWFhYWFhYWFhYWFhYWE=
        not WaveShield.playerRevived and
        #(WaveShield.playerCoords - vector3(0, 0, 0)) > 100
end

local checkTeleport = LPH_JIT_MAX(function()
    if not WaveShield.Config.Main.AntiTeleport then return end
    
-- ZiBtIGE=
-- UFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUCBpdHMgZm1h
    local currentStateValid = isValidTeleportState()

    if TP_oldStateValid and currentStateValid and
        TP_oldIsInVehicle == WaveShield.isPlayerInVehicle and
        #(TP_oldCoords - WaveShield.playerCoords) > 50 and
        ((GetNetworkTime() - (WaveShield.GetSecuredStateBag("_WS:LastTeleportedTimer") or 0)) > 10000)
    then
        WaveShield.DetectPlayer(WaveShield.Detections.ANTI_TELEPORT, {
            distance = #(TP_oldCoords - WaveShield.playerCoords),
        })
    end

    TP_oldCoords = WaveShield.playerCoords
    TP_oldIsInVehicle = WaveShield.isPlayerInVehicle
    TP_oldStateValid = currentStateValid
end)

WaveShield.RegisterDetection("teleport", checkTeleport, 1000)

local expiresTP = 0
exports("hasTeleported", LPH_NO_VIRTUALIZE(function()
    local timer = WaveShield.Native.GetGameTimer()
    if timer > expiresTP - 2000 then
        expiresTP = timer + 10000
        if not WaveShield.hasTeleported then
            WaveShield.hasTeleported = true
            WaveShield.CreateThread(function()
                while WaveShield.Native.GetGameTimer() < expiresTP do WaveShield.Wait(100) end
                WaveShield.hasTeleported = false
            end)
        end
    end
end))

RegisterNetEvent("__WaveShield:hasTeleported",function()
    WaveShield.hasTeleported = true
    expiresTP = WaveShield.Native.GetGameTimer() + 10000
    WaveShield.CreateThread(function()
        while WaveShield.Native.GetGameTimer() < expiresTP do WaveShield.Wait(100) end
        WaveShield.Wait(2000)
        WaveShield.hasTeleported = false
    end)
end)
