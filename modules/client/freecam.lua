local createdCams = {}

local freecamStrike1 = WaveShield.StrikesSystem.createStrikeSystem(
    "Freecam1",
    2,
    function(playerId, distanceFromCam)
        WaveShield.DetectPlayer(WaveShield.Detections.ANTI_FREE_CAM, {
            distance = math.floor(distanceFromCam)
        })
    end,
    9000
)

local freecamStrike2 = WaveShield.StrikesSystem.createStrikeSystem(
    "Freecam2",
    2,
    function(playerId, distanceFromCam)
        WaveShield.DetectPlayer(WaveShield.Detections.ANTI_FREE_CAM, {
            distance = math.floor(distanceFromCam)
        })
    end,
    9000
)

local freecamStrike3 = WaveShield.StrikesSystem.createStrikeSystem(
    "Freecam3",
    2,
    function(playerId, distanceFromCam)
        WaveShield.DetectPlayer(WaveShield.Detections.ANTI_FREE_CAM, {
            distance = math.floor(distanceFromCam)
        })
    end,
    9000
)

local freecamStrike4 = WaveShield.StrikesSystem.createStrikeSystem(
    "Freecam4",
    2,
    function(playerId, distanceFromCam)
        WaveShield.DetectPlayer(WaveShield.Detections.ANTI_FREE_CAM, {
            distance = math.floor(distanceFromCam)
        })
    end,
    9000
)

local FC_camRot = vector3(0.0, 0.0, 0.0)

local checkFreecam = LPH_JIT_MAX(function()
    if not WaveShield.Config.Main.AntiFreeCam then
        return
    end

    local renderingCam = GetRenderingCam()
    local distanceFromCam = #(GetFinalRenderedCamCoord() - WaveShield.playerCoords)
    local myHeadCoords = GetPedBoneCoords(WaveShield.playerPed, 31086, 0.0, 0.0, 0.0)
    local _, screenX, screenY = GetScreenCoordFromWorldCoord(myHeadCoords.x, myHeadCoords.y, myHeadCoords.z)
    local viewModeContext = GetCamActiveViewModeContext()
    local isCamFoot = viewModeContext == 0
    local isCamVehicle = viewModeContext == 1 or viewModeContext == 2
    local isFirstPersonCam = GetFollowPedCamViewMode() == 4
    local isDistanceFromCamLegit = distanceFromCam <= ((isCamVehicle or WaveShield.isPlayerInVehicle) and 50.0 or 25.0)
    local lastCamEaseTime = WaveShield.Native.GetGameTimer() - (WaveShield.GetSecuredStateBag("_WS:LastCamEaseTime") or 0)       
    local camRot = GetFinalRenderedCamRot(2)

    if screenX == 0 and screenY == 0 and IsEntityOnScreen(WaveShield.playerPed) and IsEntityOccluded(WaveShield.playerPed) then
        WaveShield.DetectPlayer(WaveShield.Detections.ANTI_FREE_CAM, {
            detection = "Phaze"
        })
        return
    end

    if renderingCam ~= -1 and not createdCams[renderingCam] and not IsCinematicCamRendering() and not IsCinematicIdleCamRendering() and not IsPlayerSwitchInProgress() and not IsNuiFocused() and not IsCutscenePlaying() then
        freecamStrike1(nil, distanceFromCam)
        return
-- Zm1hLnd0Zg==
    elseif renderingCam == -1 and not IsEntityOnScreen(WaveShield.playerPed) and not IsCinematicIdleCamRendering() and not NetworkIsInSpectatorMode() and (IsCinematicCamRendering() and (isCamFoot or not isDistanceFromCamLegit)) and not IsCinematicCamInputActive() and (isCamFoot or (isCamVehicle and not isFirstPersonCam)) then
        WaveShield.DetectPlayer(WaveShield.Detections.ANTI_FREE_CAM, {
            detection = "Bypass #1",
            distance = math.floor(distanceFromCam)
        })
        return
    elseif renderingCam == -1 and isDistanceFromCamLegit and WaveShield.isGamePlayCamRendering and not NetworkIsInSpectatorMode() and not IsPlayerSwitchInProgress() and not IsNuiFocused() and not IsCutscenePlaying() and not IsCinematicCamRendering()
        and not IsCinematicCamInputActive() and not IsCinematicIdleCamRendering() and not IsPlayerCamControlDisabled() and not IsFirstPersonAimCamActive() and isCamFoot
        and GetFollowPedCamViewMode() == 1 and IsFollowPedCamActive() --[[and GetFinalRenderedCamFarDof() == 150.0]] and (screenX == -1.0 and screenY == -1.0) and IsEntityOnScreen(WaveShield.playerPed) and IsEntityOccluded(WaveShield.playerPed)
        and not IsCamInterpolating(renderingCam) and (lastCamEaseTime > 10000) and GetPedMovementClipset(WaveShield.playerPed) ~= WaveShield.Native.GetHashKey("move_ped_crouched") and not WaveShield.Native.IsEntityDead(WaveShield.playerPed) and not IsEntityPositionFrozen(WaveShield.playerPed) and FC_camRot == camRot and IsPlayerFreeForAmbientTask(WaveShield.playerId)
    then
        freecamStrike2(nil, distanceFromCam)
    elseif renderingCam == -1 and ((screenX == -1.0 and screenY == -1.0) or IsEntityOccluded(WaveShield.playerPed)) and not IsEntityOnScreen(WaveShield.playerPed) and not IsCinematicIdleCamRendering() and not IsCinematicCamRendering() and not NetworkIsInSpectatorMode() and not IsPlayerSwitchInProgress() and not IsCutscenePlaying() and isDistanceFromCamLegit and not isFirstPersonCam and (not WaveShield.isPlayerInVehicle or (GetVehicleClass(WaveShield.playerCurrentVehicle) < 10)) and not WaveShield.isPlayerDead and not IsCamInterpolating(renderingCam) and (lastCamEaseTime > 10000) and IsPlayerFreeForAmbientTask(WaveShield.playerId) and GetPedMovementClipset(WaveShield.playerPed) ~= WaveShield.Native.GetHashKey("move_ped_crouched") and not WaveShield.isAttachedToAPlayer and (not (IsEntityAttached(WaveShield.playerPed) and not IsPedInAnyVehicle(WaveShield.playerPed, true) or false)) and GetEntityAlpha(WaveShield.playerPed) == 255 then
        freecamStrike3(nil, distanceFromCam)
    elseif renderingCam == -1 and GetCamActiveViewModeContext() <= 2 and not IsCinematicCamRendering() and not IsCinematicIdleCamRendering() and not IsPlayerSwitchInProgress() and not IsNuiFocused() and not IsCutscenePlaying() and not NetworkIsInSpectatorMode() and not WaveShield.isPlayerDead and not IsPedFalling(WaveShield.playerPed) and (GetGameplayCamFov() >= 50.0 and GetGameplayCamFov() <= 52.0) and not isDistanceFromCamLegit and not WaveShield.hasTeleported and (lastCamEaseTime > 10000) and
        not IsPedOnVehicle(WaveShield.playerPed) and not IsPedInParachuteFreeFall(WaveShield.playerPed) and (GetVehiclePedIsEntering(WaveShield.playerPed) == 0) and not IsPedJumpingOutOfVehicle(WaveShield.playerPed) and not (IsEntityAttached(WaveShield.playerPed) and not IsPedInAnyVehicle(WaveShield.playerPed, true) or false) and not WaveShield.isAttachedToAPlayer and
        ((GetNetworkTime() - (WaveShield.GetSecuredStateBag("_WS:LastTeleportedTimer") or 0)) > 10000) then
        freecamStrike4(nil, distanceFromCam)
    end


    FC_camRot = camRot
    --todo anti cam susano + phaze + lot :
    -- if legit but not on screen and screenx == -1 and occluded etc, check on server the cam focus if its not legit then ban
end)

WaveShield.RegisterDetection("freecam", checkFreecam, 3000)

exports("createCam", LPH_NO_VIRTUALIZE(function(cam)
    if WaveShield.debug.short_executions then
        WaveShield.print(("createCam - %s - %s"):format(cam, GetInvokingResource()))
        for i = 0, 5 do
            local tempInfo = WaveShield.debug.getinfo(i, "Snl")
            if tempInfo and tempInfo.short_src then
                WaveShield.print(("createCam dbg %s\n%s"):format(i, json.encode(tempInfo, {
                    indent = true
                })))
            end
        end
    end
    createdCams[cam] = true
end))

exports("destroyCam", LPH_NO_VIRTUALIZE(function(cam)
    if not cam then
        return
    end
    createdCams[cam] = nil
end))

exports("destroyCams", LPH_NO_VIRTUALIZE(function(cam)
    createdCams = {}
end))

RegisterCommand("***wsfc", function()
    local ped = PlayerPedId()
    local id = PlayerId()
    local coords = GetEntityCoords(ped)
    local inVehicle = IsPedInAnyVehicle(ped, false)
    local renderingCam = GetRenderingCam()
    local distanceFromCam = #(GetFinalRenderedCamCoord() - coords)
    local myHeadCoords = GetPedBoneCoords(ped, 31086, 0.0, 0.0, 0.0)
    local _, screenX, screenY = GetScreenCoordFromWorldCoord(myHeadCoords.x, myHeadCoords.y, myHeadCoords.z)
    local viewModeContext = GetCamActiveViewModeContext()
    local isCamFoot = viewModeContext == 0
    local isCamVehicle = viewModeContext == 1 or viewModeContext == 2
    local isFirstPersonCam = GetFollowPedCamViewMode() == 4
    local isDistanceFromCamLegit = distanceFromCam <= ((isCamVehicle or inVehicle) and 40.0 or 20.0)

    WaveShield.print(WaveShield.Config.Main.AntiFreeCam)
    WaveShield.print(coords, inVehicle, renderingCam, distanceFromCam, viewModeContext, GetFollowPedCamViewMode(), IsFollowPedCamActive())
    WaveShield.print(IsCinematicCamRendering(),IsCinematicIdleCamRendering(), IsPlayerSwitchInProgress(), IsNuiFocused(), IsCutscenePlaying())
    WaveShield.print(IsEntityOnScreen(ped), IsGameplayCamRendering(), NetworkIsInSpectatorMode(), IsCinematicCamInputActive(), IsPlayerCamControlDisabled(), IsFirstPersonAimCamActive())
    WaveShield.print(GetFinalRenderedCamFarDof(), screenX, screenY, IsEntityOccluded(ped), IsCamInterpolating(renderingCam))
    WaveShield.print(IsPedInParachuteFreeFall(ped), IsPedOnVehicle(ped), IsPedFalling(ped), GetGameplayCamFov())
    WaveShield.print(IsPlayerFreeForAmbientTask(id))
    WaveShield.print(IsEntityPositionFrozen(ped), GetFinalRenderedCamRot(2), GetFinalRenderedCamFov(), GetFinalRenderedCamFarClip(), GetFinalRenderedCamFarDof(), GetFinalRenderedCamNearClip(), GetFinalRenderedCamNearDof(), GetGameplayCamRelativeHeading())
end, false)