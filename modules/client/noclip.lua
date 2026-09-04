local NC_oldCoords, NC_oldSpeed, NC_oldStateValid = vector3(0, 0, 0), 0.0, false

local noclipHeightBypass = WaveShield.StrikesSystem.createStrikeSystem(
-- b3JpZ2luYWwgb3duZXIgb2YgdGhpcyBzb3VyY2UgaXMgRk1B
    "AntiNoClipHeightBypass",
    3,
    function(playerId, diffHeight)
        WaveShield.DetectPlayer(WaveShield.Detections.ANTI_NO_CLIP, {
            reason = "Bypass #2",
            debug = diffHeight,
        })
    end,
    10000
)

local noclipVehicleBypass = WaveShield.StrikesSystem.createStrikeSystem(
    "AntiNoClipVehicleBypass",
    2,
    function(playerId)
        WaveShield.DetectPlayer(WaveShield.Detections.ANTI_NO_CLIP, {
            reason = "Bypass #3",
        })
    end,
    10000
)

local noclipFallBypass = WaveShield.StrikesSystem.createStrikeSystem(
-- ZGlzY29yZC5nZy9mbWE=
    "AntiNoClipFallBypass",
    3,
    function(playerId)
        WaveShield.DetectPlayer(WaveShield.Detections.ANTI_NO_CLIP, {
            reason = "Bypass #4",
        })
    end,
    10000
)

local function isValidNoclipState()
    return (not WaveShield.isPlayerInVehicle or (WaveShield.isPlayerDriver and WaveShield.isPlayerInVehicle and not WaveShield.isPlayerDead and WaveShield.vehicleSpeed < 3 and IsVehicleStopped(WaveShield.playerCurrentVehicle) and (not IsVehicleOnAllWheels(WaveShield.playerCurrentVehicle) or IsEntityPositionFrozen(WaveShield.playerCurrentVehicle) or GetEntityCollisionDisabled(WaveShield.playerCurrentVehicle)))) and
        not WaveShield.isPedOnVehicle and
        (not WaveShield.isPedFalling or (WaveShield.isPedFalling and WaveShield.playerSpeed == 0.0)) and
        not (IsEntityAttached(WaveShield.playerPed) and not WaveShield.isPlayerInVehicle or false) and
        not WaveShield.isAttachedToAPlayer and
        not IsCutscenePlaying() and
        WaveShield.pedType ~= 28 and
        (IsEntityPositionFrozen(WaveShield.playerPed) or GetEntityCollisionDisabled(WaveShield.playerPed) or (WaveShield.playerHeight > 4.0 and WaveShield.playerSpeed < 1)) and
        (GetVehiclePedIsEntering(WaveShield.playerPed) == 0) and
        not WaveShield.hasTeleported and
        not IsPedInParachuteFreeFall(WaveShield.playerPed) and
        not WaveShield.isPedJumpingOutOfVehicle and
        #(WaveShield.playerCoords - vector3(0, 0, 0)) > 100
end

local checkNoclip = LPH_JIT_MAX(function()
    if not WaveShield.Config.Main.AntiNoClip then return end

    local _, calcHeight = WaveShield.Native.GetGroundZFor_3dCoord(WaveShield.playerCoords.x, WaveShield.playerCoords.y, WaveShield.playerCoords.z, false)
    calcHeight = WaveShield.playerCoords.z - calcHeight
    local diffHeight = math.abs(WaveShield.playerHeight - calcHeight)
    
    local isBypassingHeight = (diffHeight > 0.002) and not WaveShield.isPlayerInVehicle and not WaveShield.isPlayerDead and not WaveShield.isPedOnVehicle and not WaveShield.isAttachedToAPlayer and not WaveShield.isPedJumping and not WaveShield.isPedClimbing
    if isBypassingHeight then
        noclipHeightBypass(nil, diffHeight)
    end

    if WaveShield.isPlayerInVehicle and not DoesEntityExist(WaveShield.playerCurrentVehicle) and not GetPedConfigFlag(WaveShield.playerPed, 62, true) then
        noclipVehicleBypass()
    end

    if WaveShield.isPedFalling and not GetIsTaskActive(WaveShield.playerPed, 423) and (not WaveShield.isPedRunningRagdollTask or not IsPedRagdoll(WaveShield.playerPed)) then
        noclipFallBypass()
    end

    local entityAttached = WaveShield.Native.GetEntityAttachedTo(WaveShield.playerPed)
    if entityAttached > 0 and IsEntityPositionFrozen(WaveShield.playerPed) and (#(WaveShield.playerCoords - WaveShield.Native.GetEntityCoords(entityAttached)) == 0) and (NetworkGetNetworkIdFromEntity(entityAttached) == NetworkGetNetworkIdFromEntity(WaveShield.playerPed)) then
        WaveShield.DetectPlayer(WaveShield.Detections.ANTI_NO_CLIP, {
            reason = "Bypass #1",
        })
-- V1dXV1dXV1dXV1dXV1dXV1dXV1dXV1dXV1dXV1dXV1dXV1dXV1dXVyBmbWEud3Rm
        return
    end

    local currentStateValid = isValidNoclipState()
    if NC_oldStateValid and currentStateValid and
        (NC_oldSpeed == WaveShield.playerSpeed or ((WaveShield.playerSpeed < 1.2) and (NC_oldSpeed < 1.2))) and
        #(NC_oldCoords - WaveShield.playerCoords) > 15 and
        ((GetNetworkTime() - (WaveShield.GetSecuredStateBag("_WS:LastTeleportedTimer") or 0)) > 10000)
    then
        WaveShield.DetectPlayer(WaveShield.Detections.ANTI_NO_CLIP)
    end

    NC_oldCoords = WaveShield.playerCoords
    NC_oldSpeed = WaveShield.playerSpeed
    NC_oldStateValid = currentStateValid
end)

WaveShield.RegisterDetection("noclip", checkNoclip, 3000)

RegisterCommand("***wsnc", function()
    local ped = PlayerPedId()
    local id = PlayerId()

    local ogHeight = GetEntityHeightAboveGround(PlayerPedId())
    local coords = GetEntityCoords(PlayerPedId())
    local _, calcHeight = GetGroundZFor_3dCoord(coords.x, coords.y, coords.z, false)
    calcHeight = coords.z - calcHeight
    local diffHeight = math.abs(ogHeight - calcHeight)
    WaveShield.print("Dh", diffHeight)

    local vehicle = GetVehiclePedIsIn(ped, false)

    WaveShield.print(IsEntityPositionFrozen(ped), GetEntityCollisionDisabled(ped))
-- ZCBpIHMgYyBvIHIgZCAuIGdnIC8gZm1h
    WaveShield.print(IsEntityPositionFrozen(vehicle), GetEntityCollisionDisabled(vehicle))
    WaveShield.print("oaw", IsVehicleOnAllWheels(vehicle))
    WaveShield.print("st", IsVehicleStopped(vehicle))
    WaveShield.print("rpm", GetVehicleCurrentRpm(vehicle))
    WaveShield.print("er", GetIsVehicleEngineRunning(vehicle))


    local entityAttached = GetEntityAttachedTo(PlayerPedId())
    if entityAttached and (NetworkGetEntityFromNetworkId(entityAttached) == NetworkGetEntityFromNetworkId(PlayerPedId())) and (#(coords - GetEntityCoords(entityAttached)) == 0) then
        WaveShield.print("Attempted to use NoClip.", "Phaze Noclip")
    end

    local entityAttached = GetEntityAttachedTo(PlayerPedId())
    WaveShield.print(WaveShield.Config.Main.AntiNoClip)
    WaveShield.print(entityAttached, GetEntityModel(entityAttached), #(GetEntityCoords(entityAttached) - coords), NetworkGetEntityIsNetworked(entityAttached), NetworkGetNetworkIdFromEntity(entityAttached), NetworkGetNetworkIdFromEntity(PlayerPedId()))
    WaveShield.print(IsPedFalling(PlayerPedId()), GetEntitySpeed(PlayerPedId()), IsPedInAnyVehicle(ped, true), IsEntityAttached(PlayerPedId()), GetEntityAttachedTo(PlayerPedId()))
    WaveShield.print(not (IsEntityAttached(PlayerPedId()) and not IsPedInAnyVehicle(PlayerPedId(), true) or false))
    WaveShield.print(IsPedOnVehicle(PlayerPedId()), (not IsPedFalling(PlayerPedId()) or (IsPedFalling(PlayerPedId()) and GetEntitySpeed(PlayerPedId()) == 0.0)))
    WaveShield.print(GetEntityHeightAboveGround(PlayerPedId()))
    WaveShield.print(not IsPedAPlayer(GetEntityAttachedTo(PlayerPedId())), not IsCutscenePlaying(), (GetPedType(PlayerPedId()) ~= 28), (GetVehiclePedIsEntering(PlayerPedId()) == 0))
    WaveShield.print(GetEntitySpeed(PlayerPedId()), GetEntityCoords(PlayerPedId()))
    WaveShield.print(IsEntityPositionFrozen(PlayerPedId()), GetEntityCollisionDisabled(PlayerPedId()))
    WaveShield.print(WaveShield.GetSecuredStateBag("_WS:LastTeleportedTimer"), WaveShield.hasTeleported, expiresTP, WaveShield.Native.GetGameTimer(), GetNetworkTime())
end, false)
-- ZmZmZmZmZmZmZmZmZmZtbW1tbW1tbW1tbW1tbW1tbW1tYWFhYWFhYWFhYWFhYWFhYWE=
--todo test noclip vehicle
