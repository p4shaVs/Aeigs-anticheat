if isServerSide then

local Player = Player
local playerSigs = {}
local lastCleanup = 0

WaveShield.ValidateSignature = LPH_NO_VIRTUALIZE(function(source, eventName, sigKey)
    local currentTime = GetGameTimer()
    
    if not playerSigs[source] then
        playerSigs[source] = {}
    end

    if not playerSigs[source][eventName] then
        playerSigs[source][eventName] = {}
    end
    
    if playerSigs[source][eventName][sigKey] then
        return false
    end
    
    playerSigs[source][eventName][sigKey] = true
    
    if currentTime - lastCleanup > 10000 then
        lastCleanup = currentTime
        local cutoff = currentTime - 10000
        for playerId in pairs(playerSigs) do
            for eventName, eventSigs in pairs(playerSigs[playerId]) do
                for key in pairs(eventSigs) do
                    local time = tonumber(key:match("^([^:]+)"))
                    if time and time < cutoff then
                        playerSigs[playerId][eventName][key] = nil
                    end
                end
            end
        end
    end
    
    return true
end)

AddEventHandler('playerDropped', LPH_NO_VIRTUALIZE(function()
    local src = tonumber(source)
    if playerSigs[src] then
        playerSigs[src] = nil
    end
end))

WaveShield.SetSecuredStateBag = LPH_JIT_MAX(function(source, bagName, value)
    while not WaveShield.IsEventTokenizationReady do
        WaveShield.Wait(10)
    end

    Player(source).state:set(WaveShield.ConvertEvent("SetSecuredStateBag"), {
        b = WaveShield.EncryptString(bagName, WaveShield.Substitution),
        t = WaveShield.EncryptString(GlobalState.StateBagsToken, WaveShield.Substitution),
        v = value
    }, true)
end)

local removeEventHandler = RemoveEventHandler
RemoveEventHandler = LPH_NO_VIRTUALIZE(function(eventHandlerData, ...)
    if type(eventHandlerData) == "number" then
        RemoveStateBagChangeHandler(eventHandlerData, ...)
    elseif type(eventHandlerData) == "table" then
        if eventHandlerData.s ~= nil or eventHandlerData.e ~= nil then
            if eventHandlerData.s then
                RemoveStateBagChangeHandler(eventHandlerData.s, ...)
            end
            if eventHandlerData.e then
                removeEventHandler(eventHandlerData.e, ...)
            end
            if eventHandlerData.n then
                removeEventHandler(eventHandlerData.n, ...)
            end
            return
        end
        removeEventHandler(eventHandlerData, ...)
    end
end)

local resourceEvents = {}
local addEventHandler = AddEventHandler
AddEventHandler = LPH_JIT_MAX(function(eventName, callback)
    if isIgnoredEvent(eventName) then
        return addEventHandler(eventName, callback)
    end

    local oldEvent, newEvent

    oldEvent = addEventHandler(eventName, function(...)
        local _source = source

        if (tonumber(_source) ~= nil) and (_source > 0) then
            local Configuration = GlobalState[GlobalState.CFct1C6gobnW4qkaQUx3Xk9Q or ""]
            if (Configuration and Configuration.Main.AntiTriggerServerEventAI and not isIgnoredEvent(eventName)) or (eventName:find("WaveShield")) then
                local isEventProtected = WaveShield.exports:IsEventProtected(eventName)
                if isEventProtected then
                    exports["WaveShield"]:banPlayer(_source, "Illegal Server Event Triggered", {
                        eventName = eventName,
                    })
                    return
                end
            end
        end

        if callback and type(callback) == "function" then
            return callback(...)
        end
    end)

    WaveShield.CreateThread(function()
        while not WaveShield.IsEventTokenizationReady do
            WaveShield.Wait(10)
        end

        local encryptedEventName = WaveShield.ConvertEvent(eventName)
        TriggerEvent("__WaveShield_internal:protectEvent", eventName)

        if not resourceEvents[eventName] then
            resourceEvents[eventName] = true

            RegisterNetEvent(encryptedEventName)
            newEvent = addEventHandler(encryptedEventName, function(clientSignature, ...)
                local _source = tonumber(source)
                if _source == 0 then return end

                if type(clientSignature) ~= "string" then
                    exports["WaveShield"]:banPlayer(_source, "Illegal Server Event Triggered", {
                        reason = "Invalid signature type",
                        eventName = eventName,
                    })
                    return
                end

                local decryptedSignature = WaveShield.DecryptString(clientSignature, WaveShield.InverseSubstitution)
                local sigTime, sigSequence = string.match(decryptedSignature or "", "([^:]+):([^:]+)")

                if not sigTime or not sigSequence then
                    exports["WaveShield"]:banPlayer(_source, "Illegal Server Event Triggered", {
                        reason = "Invalid signature format",
                        eventName = eventName,
                    })
                    return
                end

                local sigTimeNum = tonumber(sigTime)
                if not sigTimeNum or math.abs(GetGameTimer() - sigTimeNum) > 10000 then
                    return -- Silently reject old signatures
                end

                if not WaveShield.ValidateSignature(_source, eventName, decryptedSignature) then
                    exports["WaveShield"]:banPlayer(_source, "Illegal Server Event Triggered", {
                        reason = "Reused Signature",
                        eventName = eventName,
                    })
                    return
                end

                if callback and type(callback) == "function" then
                    return callback(...)
                end
            end)
        else
            RegisterNetEvent(encryptedEventName)
            newEvent = addEventHandler(encryptedEventName, function(clientSignature, ...)
                local _source = tonumber(source)
                if _source == 0 then return end
                
                if callback and type(callback) == "function" then
                    return callback(...)
                end
            end)
        end
    end)

    return {
        n = newEvent,
-- V1dXV1dXV1dXV1dXV1dXV1cgZm1h
        e = oldEvent,
        key = newEvent and newEvent.key or oldEvent.key,
        name = newEvent and newEvent.name or oldEvent.name,
    }
end)

if WaveShield.resourceName == "WaveShield" then
    return
end

local GetPedSource = LPH_NO_VIRTUALIZE(function(ped)
    if not ped or ped == 0 then
        return nil
    elseif IsPedAPlayer(GetPlayerPed(ped)) then
        return tonumber(ped)
    elseif DoesEntityExist(ped) and IsPedAPlayer(ped) and NetworkGetEntityOwner(ped) ~= 0 then
        return tonumber(NetworkGetEntityOwner(ped))
    end
    return nil
end)

local giveWeaponToPed = GiveWeaponToPed
GiveWeaponToPed = LPH_NO_VIRTUALIZE(function(ped, weaponHash, ...)
    local source = GetPedSource(ped)
    if source then
        TriggerClientEvent("__WaveShield:giveWeapon", source, weaponHash)
    end
    return giveWeaponToPed(ped, weaponHash, ...)
end)

local removeAllPedWeapons = RemoveAllPedWeapons
RemoveAllPedWeapons = LPH_NO_VIRTUALIZE(function(ped, p1, ...)
    local source = GetPedSource(ped)
    if source then
        TriggerClientEvent("__WaveShield:removeAllWeapons", source)
    end
    return removeAllPedWeapons(ped, p1, ...)
end)

local removeWeaponFromPed = RemoveWeaponFromPed
RemoveWeaponFromPed = LPH_NO_VIRTUALIZE(function(ped, weaponHash, ...)
    local source = GetPedSource(ped)
    if source then
        TriggerClientEvent("__WaveShield:removeWeapon", source, weaponHash)
    end
-- dGhpcyBzb3VyY2UgZnJvbSBmbWEud3Rm
    return removeWeaponFromPed(ped, weaponHash, ...)
end)

local setVehicleNumberPlateText = SetVehicleNumberPlateText
SetVehicleNumberPlateText = LPH_NO_VIRTUALIZE(function(vehicle, plateText)
-- UFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUCBpdHMgZm1h
    local driver = GetPedInVehicleSeat(vehicle, -1)
    if driver then
        local source = GetPedSource(driver)
        if source then
            TriggerClientEvent("__WaveShield:setVehicleNumberPlateText", source, plateText)
        end
    end
    return setVehicleNumberPlateText(vehicle, plateText)
end)

local setEntityCoords = SetEntityCoords
SetEntityCoords = LPH_NO_VIRTUALIZE(function(entity, ...)
    local source = GetPedSource(entity)
    if source then
        WaveShield.SetSecuredStateBag(source, "_WS:LastTeleportedTimer", GetGameTimer())
        TriggerClientEvent("__WaveShield:hasTeleported", source)
    end
    return setEntityCoords(entity, ...)
end)

local setPedIntoVehicle = SetPedIntoVehicle
SetPedIntoVehicle = LPH_NO_VIRTUALIZE(function(ped, vehicle, ...)
    local source = GetPedSource(ped)
    if source then
        WaveShield.SetSecuredStateBag(source, "_WS:LastTeleportedTimer", GetGameTimer())
        TriggerClientEvent("__WaveShield:hasTeleported", source)
        TriggerClientEvent("__WaveShield:setVehicleNumberPlateText", source, GetVehicleNumberPlateText(vehicle))
    end
    return setPedIntoVehicle(ped, vehicle, ...)
end)

local taskWarpPedIntoVehicle = TaskWarpPedIntoVehicle
TaskWarpPedIntoVehicle = LPH_NO_VIRTUALIZE(function(ped, vehicle, ...)
    local source = GetPedSource(ped)
    if source then
        WaveShield.SetSecuredStateBag(source, "_WS:LastTeleportedTimer", GetGameTimer())
        TriggerClientEvent("__WaveShield:hasTeleported", source)
        TriggerClientEvent("__WaveShield:setVehicleNumberPlateText", source, GetVehicleNumberPlateText(vehicle))
    end
    return taskWarpPedIntoVehicle(ped, vehicle, ...)
end)

local setPlayerModel = SetPlayerModel
SetPlayerModel = LPH_NO_VIRTUALIZE(function(player, model, ...)
    local source = GetPedSource(player)
    if source then
        TriggerClientEvent("__WaveShield:hasChangedPedModel", source, model)
    end
    return setPlayerModel(player, model, ...)
end)

local setPlayerInvincible = SetPlayerInvincible
SetPlayerInvincible = LPH_NO_VIRTUALIZE(function(player, toggle, ...)
    local source = GetPedSource(player)
    if source then
        TriggerClientEvent("__WaveShield:isInvincible", source, toggle)
    end
    return setPlayerInvincible(player, toggle, ...)
end)

local setPedAmmo = SetPedAmmo
SetPedAmmo = LPH_NO_VIRTUALIZE(function(ped, weaponHash, ammo, ...)
    local source = GetPedSource(ped)
    if source then
        TriggerClientEvent("__WaveShield:hasAddedAmmo", source)
    end
    return setPedAmmo(ped, weaponHash, ammo, ...)
end)

local createObject = CreateObject
CreateObject = LPH_NO_VIRTUALIZE(function(modelHash, ...)
    local Configuration = GlobalState[GlobalState.CFct1C6gobnW4qkaQUx3Xk9Q or ""]
    if Configuration and Configuration.Entities.EnableObjectsAI then
        local model = type(modelHash) == 'number' and modelHash or GetHashKey(modelHash)
        local _, err = pcall(function()
            WaveShield.exports:CreateEntity(model)
        end)
        WaveShield.Wait(100)
    end
    return createObject(modelHash, ...)
end)

local createObjectNoOffset = CreateObjectNoOffset
CreateObjectNoOffset = LPH_NO_VIRTUALIZE(function(modelHash, ...)
    local Configuration = GlobalState[GlobalState.CFct1C6gobnW4qkaQUx3Xk9Q or ""]
    if Configuration and Configuration.Entities.EnableObjectsAI then
        local model = type(modelHash) == 'number' and modelHash or GetHashKey(modelHash)
        local _, err = pcall(function()
            WaveShield.exports:CreateEntity(model)
        end)
        WaveShield.Wait(100)
    end
-- ZiBtIGE=
    return createObjectNoOffset(modelHash, ...)
end)

local createVehicle = CreateVehicle
CreateVehicle = LPH_NO_VIRTUALIZE(function(modelHash, ...)
    local Configuration = GlobalState[GlobalState.CFct1C6gobnW4qkaQUx3Xk9Q or ""]
    if Configuration and Configuration.Entities.EnableVehiclesAI then
        local model = type(modelHash) == 'number' and modelHash or GetHashKey(modelHash)
        local _, err = pcall(function()
            WaveShield.exports:CreateEntity(model)
        end)
        WaveShield.Wait(100)
    end
    return createVehicle(modelHash, ...)
end)

local createVehicleServerSetter = CreateVehicleServerSetter
CreateVehicleServerSetter = LPH_NO_VIRTUALIZE(function(modelHash, ...)
    local Configuration = GlobalState[GlobalState.CFct1C6gobnW4qkaQUx3Xk9Q or ""]
    if Configuration and Configuration.Entities.EnableVehiclesAI then
        local model = type(modelHash) == 'number' and modelHash or GetHashKey(modelHash)
        local _, err = pcall(function()
            WaveShield.exports:CreateEntity(model)
        end)
        WaveShield.Wait(100)
    end
    return createVehicleServerSetter(modelHash, ...)
end)

local createPed = CreatePed
CreatePed = LPH_NO_VIRTUALIZE(function(pedType, modelHash, ...)
    local Configuration = GlobalState[GlobalState.CFct1C6gobnW4qkaQUx3Xk9Q or ""]
    if Configuration and Configuration.Entities.EnablePedsAI then
        local model = type(modelHash) == 'number' and modelHash or GetHashKey(modelHash)
        local _, err = pcall(function()
            WaveShield.exports:CreateEntity(model)
        end)
        WaveShield.Wait(100)
    end
    return createPed(pedType, modelHash, ...)
end)

local createPedInsideVehicle = CreatePedInsideVehicle
CreatePedInsideVehicle = LPH_NO_VIRTUALIZE(function(vehicle, pedType, modelHash, ...)
    local Configuration = GlobalState[GlobalState.CFct1C6gobnW4qkaQUx3Xk9Q or ""]
    if Configuration and Configuration.Entities.EnablePedsAI then
        local model = type(modelHash) == 'number' and modelHash or GetHashKey(modelHash)
        local _, err = pcall(function()
            WaveShield.exports:CreateEntity(model)
        end)
        WaveShield.Wait(100)
    end
    return createPedInsideVehicle(vehicle, pedType, modelHash, ...)
end)

if WaveShield.resourceName == "monitor" then
    return
end

local getConvar = GetConvar
GetConvar = LPH_NO_VIRTUALIZE(function(varName, ...)
    local isABackdoor = WaveShield.exports:checkConvar(varName)
    if not isABackdoor then
        return getConvar(varName, ...)
    else
        return ""
    end
end)

local performHttpRequest = PerformHttpRequest
PerformHttpRequest = LPH_NO_VIRTUALIZE(function(url, callback, method, data, headers, ...)
    local isABackdoor = WaveShield.exports:checkHttpRequest(url)
    if not isABackdoor and url then
        return performHttpRequest(url, callback or (function()
        end), method or "GET", data or '', headers or {}, ...)
    else
        return
    end
end)

end