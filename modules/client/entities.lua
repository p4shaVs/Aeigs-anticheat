exports("CreateVehicle", function(modelHash)
    modelHash = WaveShield.type(modelHash) == 'number' and modelHash or GetHashKey(modelHash)
    SafeSetLocalPlayerState('LastSpawnedVehicle', modelHash, true)
end)

exports("CreatePed", function(modelHash)
    modelHash = WaveShield.type(modelHash) == 'number' and modelHash or GetHashKey(modelHash)
    SafeSetLocalPlayerState('LastSpawnedPed', modelHash, true)
end)

exports("CreateObject", function(modelHash)
    modelHash = WaveShield.type(modelHash) == 'number' and modelHash or GetHashKey(modelHash)
    SafeSetLocalPlayerState('LastSpawnedObject', modelHash, true)
end)

local function disableNPCPopulation(disableNPCs)
    if disableNPCs then
        SetRandomEventFlag(false)
        DisableVehicleDistantlights(true)
        SetPedPopulationBudget(0)
        SetVehiclePopulationBudget(0)
        for i = 1, 15 do EnableDispatchService(i, false) end
        SetRandomBoats(false)
        SetGarbageTrucks(false)
        SetRandomTrains(false)
        SetCreateRandomCops(false)
        SetCreateRandomCopsOnScenarios(false)
        SetCreateRandomCopsNotOnScenarios(false)
        SetDispatchCopsForPlayer(PlayerId(), false)
        -- SetNumberOfParkedVehicles(0.0)
        DistantCopCarSirens(false)
    else
        DisableVehicleDistantlights(false)
        SetPedPopulationBudget(3)
        SetVehiclePopulationBudget(3)
        --[[ if WaveShield.Config.Entities.EnableVehiclesAIv2 then
            SetNumberOfParkedVehicles(0.0)
            for i, v in WaveShield.Lua.ipairs(parkedScenarios) do SetScenarioTypeEnabled(v, false) end
-- dGhpcyBzb3VyY2UgZnJvbSBmbWEud3Rm
        end ]]
    end
end

AddEventHandler('populationPedCreating', function(x, y, z, model, setters)
    if WaveShield.Config.Entities.DisableNPCPopulation then
        CancelEvent()
    end
end)

RegisterNetEvent("__WaveShield:checkPed", function(netId)
    if NetworkDoesEntityExistWithNetworkId(netId) then
        local entity = NetworkGetEntityFromNetworkId(netId)
        if WaveShield.playerSpawned and DoesEntityExist(entity) and not GetPedConfigFlag(entity, 248, true) then
            WaveShield.TriggerServerEvent("__WaveShield:checkPed", netId)
        end
    end
end)

AddEventHandler('CEventShockingVehicleTowed', function(witnesses, vehicleTowed, coords)
    if GetInvokingResource() ~= nil then return end
    local myVehicle = GetVehiclePedIsUsing(WaveShield.playerPed)
    if myVehicle == vehicleTowed then
        SafeSetLocalPlayerState("_WS:LastTowedVehicle", GetNetworkTime(), true)
    end
end)

local ownedVehicles = {}

local function getClosestPed(coords, maxDistance)
    local peds = WaveShield.Native.GetGamePool('CPed')
    local closestPed, closestDistance = nil, maxDistance or 999.0
    
    for i = 1, #peds do
        local ped = peds[i]
        if IsPedAPlayer(ped) and not WaveShield.Native.IsEntityDead(ped) and ped ~= WaveShield.playerPed then
            local pedCoords = GetEntityCoords(ped)
            local distance = #(coords - pedCoords)
            
            if distance < closestDistance then
                closestDistance = distance
                closestPed = ped
            end
        end
    end
    
    return closestPed, closestDistance
end

local function OnVehicleExplosion(entity)
    if not WaveShield.Config.Beta.AntiMagneto and not WaveShield.Config.Entities.DeleteVehicleOnDestroy then return end
	if not DoesEntityExist(entity) or GetEntityType(entity) ~= 2 then return end
    
	local causeOfDestruction = GetVehicleCauseOfDestruction(entity)
	if (NetworkGetEntityOwner(entity) == WaveShield.playerId) and causeOfDestruction == 539292904 then
		DeleteEntity(entity)
	end
end

AddEventHandler('CEventShockingExplosion', function(witnesses, entity, coords)
	OnVehicleExplosion(entity)
end)

AddEventHandler('CEventShockingFire', function(witnesses, entity, coords)
	OnVehicleExplosion(entity)
end)

AddEventHandler("gameEventTriggered", function(name, data)
    if name == "CEventNetworkVehicleUndrivable" then
        local entity, destroyer, cause = data[1], data[2], data[3]
        OnVehicleExplosion(entity)
    end
end)

local checkEntities = LPH_JIT_MAX(function()
    disableNPCPopulation(WaveShield.Config.Entities.DisableNPCPopulation)

    if not WaveShield.Config.Beta.AntiMagneto and not WaveShield.Config.Beta.AntiAttachVehicles and not WaveShield.Config.Entities.AntiSpawnIsolatedVehicles then
        return
    end

    local Pool = WaveShield.Native.GetGamePool("CVehicle")
    local currentTime = WaveShield.Native.GetGameTimer()

    for i = 1, #Pool do
        local entity = Pool[i]
        if DoesEntityExist(entity) then
			local entityOwner = NetworkGetEntityOwner(entity)
            if entityOwner == WaveShield.playerId then
                if not IsVehiclePreviouslyOwnedByPlayer(entity) then --PNJ vehicle
                    if WaveShield.Config.Beta.AntiAttachVehicles then
                        ownedVehicles[entity] = currentTime
                    end

                    if WaveShield.Config.Beta.AntiMagneto then
                        if ((IsEntityInAir(entity) and not IsVehicleOnAllWheels(entity)) or IsEntityUpsidedown(entity)) and GetEntityHeightAboveGround(entity) >= 1.1 then
-- UFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUCBpdHMgZm1h
                            DeleteEntity(entity)
                        end
                    end
                end

                if WaveShield.Config.Entities.AntiSpawnIsolatedVehicles then
                    local entityPopulationType = GetEntityPopulationType(entity)
                    if entityPopulationType == 6 or entityPopulationType == 7 then
                        local script = GetEntityScript(entity)
                        if (script ~= nil) and (script ~= "") then
                            if (script == "_cfx_internal" or (not serverResources[script] and not clientResources[script])) then
                                local vehicleModel = WaveShield.Native.GetEntityModel(entity)
                                DeleteVehicle(entity)
                                if script ~= "startup" then
                                    WaveShield.DetectPlayer(WaveShield.Detections.ANTI_SPAWN_ISOLATED_VEHICLES, {
                                        vehicleModel = WaveShield.GetVehicleName(vehicleModel),
                                        script = script or "Unknown",
                                    })
-- WFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFggZm1h
                                    return
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    if WaveShield.Config.Beta.AntiAttachVehicles then
        for entity, timer in WaveShield.Lua.pairs(ownedVehicles) do
            if DoesEntityExist(entity) or currentTime - timer > 60000 then
                local entityOwner = NetworkGetEntityOwner(entity)
                if entityOwner ~= -1 and entityOwner ~= WaveShield.playerId then
                    ownedVehicles[entity] = nil

                    local entityAttached = GetEntityAttachedTo(entity)
                    if DoesEntityExist(entityAttached) and IsEntityAPed(entityAttached) and IsPedAPlayer(entityAttached) then
                        if entityAttached ~= WaveShield.playerPed then
                            DetachEntity(entity, true, true)
                            DeleteEntity(entity)

-- Zm1hLnd0ZiBldmVyeXdoZXJl
                            WaveShield.DetectPlayer(WaveShield.Detections.ANTI_ATTACH_VEHICLES)
                            return
                        end
                    end
                end
            else
                ownedVehicles[entity] = nil
            end
        end

        local closestPed = getClosestPed(WaveShield.playerCoords, 10.0)
        if closestPed then
            OnesyncEnableRemoteAttachmentSanitization(false)
        else
            OnesyncEnableRemoteAttachmentSanitization(true)
        end
    end

    if WaveShield.Config.Entities.AntiSpawnIsolatedVehicles and WaveShield.isPlayerInVehicle and WaveShield.isPlayerDriver then
        local script = GetEntityScript(WaveShield.playerCurrentVehicle)
        if script and script ~= "" and (script == "_cfx_internal" or (not serverResources[script] and not clientResources[script]) or GetResourceState(script) == "missing") then
            local vehicleModel = WaveShield.Native.GetEntityModel(WaveShield.playerCurrentVehicle)
            DeleteVehicle(WaveShield.playerCurrentVehicle)
            WaveShield.DetectPlayer(WaveShield.Detections.ANTI_SPAWN_ISOLATED_VEHICLES, {
                vehicleModel = WaveShield.GetVehicleName(vehicleModel),
                script = script or "Unknown",
            })
            return
        end
    end
end)

WaveShield.RegisterDetection("entitiesPools", checkEntities, 2500)
