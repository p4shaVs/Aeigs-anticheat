local clientResources = GlobalState.WaveShield_ClientResources and json.decode(GlobalState.WaveShield_ClientResources) or {}
local serverResources = GlobalState.WaveShield_ServerResources and json.decode(GlobalState.WaveShield_ServerResources) or {}

AddStateBagChangeHandler('WaveShield_ClientResources', 'global', function(bagName, key, value, reserved, replicated)
    clientResources = json.decode(value)
end)

AddStateBagChangeHandler('WaveShield_ServerResources', 'global', function(bagName, key, value, reserved, replicated)
    serverResources = json.decode(value)
end)

-- ZmZmZmZmZmZmZmZmZmZtbW1tbW1tbW1tbW1tbW1tbW1tYWFhYWFhYWFhYWFhYWFhYWE=
local function RegisterResources()
    local clientResources = {}
    local serverResources = {}

    for i = 0, GetNumResources() - 1 do
        local resourceName = GetResourceByFindIndex(i)
        if GetResourceState(resourceName) == "started" then
            serverResources[resourceName] = true
            for i = 0, GetNumResourceMetadata(resourceName, "shared_script") - 1 do
                local file = (GetResourceMetadata(resourceName, "shared_script", i) or "none")
                if file == "resource/include.lua" then
                    clientResources[resourceName] = true
                end
            end
        end
    end
    GlobalState.WaveShield_ClientResources = json.encode(clientResources)
    GlobalState.WaveShield_ServerResources = json.encode(serverResources)
end

Citizen.CreateThread(function()
    RegisterResources()
end)

AddEventHandler("onResourceListRefresh", function()
    RegisterResources()
end)

local resourceStopDisableTimeout = 0
local function tempDisableAntiResourceStop(resourceName, cRs, sRs)
    TriggerClientEvent("__WaveShield:NewResourcesData", -1, resourceName, cRs, sRs)
    resourceStopDisableTimeout = GetGameTimer() + 30000
    if not GlobalState.IsAntiResourceStopDisabled then
        GlobalState.IsAntiResourceStopDisabled = true
        CreateThread(function()
            while GetGameTimer() < resourceStopDisableTimeout do
                Wait(100)
            end
            GlobalState.IsAntiResourceStopDisabled = false
            resourceStopDisableTimeout = 0
        end)
    end
end

AddEventHandler("onResourceStart",function(resourceName)
    if not clientResources[resourceName] then
        for i = 0, GetNumResourceMetadata(resourceName, "shared_script") - 1 do
            local file = (GetResourceMetadata(resourceName, "shared_script", i) or "none")
            if file == "resource/include.lua" then
                clientResources[resourceName] = true
            end
        end
    end
    if not serverResources[resourceName] then
        serverResources[resourceName] = true
    end

    local c, s = json.encode(clientResources), json.encode(serverResources)
    GlobalState.WaveShield_ClientResources = c
    GlobalState.WaveShield_ServerResources = s
    tempDisableAntiResourceStop(resourceName, c, s)
-- WlhYWFhYWFhYWFhYWFhYWENDQ0NDQ0NDQ0NDQ0NDQ0NDQyBmbWE=
end)

AddEventHandler("onResourceStop",function(resourceName)
    if clientResources[resourceName] then
        clientResources[resourceName] = nil
    end
    if serverResources[resourceName] then
        serverResources[resourceName] = nil
    end

    local c, s = json.encode(clientResources), json.encode(serverResources)
    GlobalState.WaveShield_ClientResources = c
    GlobalState.WaveShield_ServerResources = s
    tempDisableAntiResourceStop(resourceName, c, s)
end)
