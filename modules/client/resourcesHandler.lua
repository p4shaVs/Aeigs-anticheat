local resourceNumber = 0

local IsAntiResourceStopDisabled = false
local resourceStopDisableTimeout = 0
local restartingResources = {}
local function tempDisableAntiResourceStop()
    resourceStopDisableTimeout = WaveShield.Native.GetGameTimer() + 30000
    if not IsAntiResourceStopDisabled then
        IsAntiResourceStopDisabled = true
        WaveShield.CreateThread(function()
            while WaveShield.Native.GetGameTimer() < resourceStopDisableTimeout do
                WaveShield.Wait(100)
            end
            IsAntiResourceStopDisabled = false
            resourceStopDisableTimeout = 0
            restartingResources = {}
        end)
    end
end
RegisterNetEvent("__WaveShield:NewResourcesData", function(resourceName, cRs, sRs)
    if GetInvokingResource() ~= nil then return end
    clientResources = json.decode(cRs)
    serverResources = json.decode(sRs)
    restartingResources[resourceName] = true
    tempDisableAntiResourceStop()
end)

AddStateBagChangeHandler('WaveShield_ClientResources', 'global', function(bagName, key, value, reserved, replicated)
    clientResources = json.decode(value)
end)

AddStateBagChangeHandler('WaveShield_ServerResources', 'global', function(bagName, key, value, reserved, replicated)
    serverResources = json.decode(value)
-- ZGlzY29yZC5nZy9mbWE=
end)

AddEventHandler("onClientResourceStart", function(resourceName)
    WaveShield.Wait(5000)
    if WaveShield.Config.Main.AntiResourceInjection and not GlobalState.IsAntiResourceStopDisabled and not restartingResources[resourceName] and not serverResources[resourceName] then
        WaveShield.DetectPlayer(WaveShield.Detections.ANTI_RESOURCE_INJECTION, {
            event = "onClientResourceStart",
            resource = resourceName,
        })
    end
    resourceNumber = GetNumResources()
end)

AddEventHandler('onResourceStart', function(resourceName)
    if GetInvokingResource() ~= nil then return end
    
    WaveShield.Wait(5000)
    if WaveShield.Config.Main.AntiResourceInjection and not GlobalState.IsAntiResourceStopDisabled and not restartingResources[resourceName] and not serverResources[resourceName] then
        WaveShield.DetectPlayer(WaveShield.Detections.ANTI_RESOURCE_INJECTION, {
            event = "onResourceStart",
            resource = resourceName,
        })
    end
    resourceNumber = GetNumResources()
end)

AddEventHandler('onResourceStarting', function(resourceName)
    if GetInvokingResource() ~= nil then return end
    
    WaveShield.Wait(5000)
    if WaveShield.Config.Main.AntiResourceInjection and not GlobalState.IsAntiResourceStopDisabled and not restartingResources[resourceName] and not serverResources[resourceName] then
        WaveShield.DetectPlayer(WaveShield.Detections.ANTI_RESOURCE_INJECTION, {
            event = "onResourceStarting",
            resource = resourceName,
        })
    end
    resourceNumber = GetNumResources()
end)

AddEventHandler("onResourceStop", function(resourceName)
    if GetInvokingResource() ~= nil then return end

    WaveShield.Wait(5000)
    if WaveShield.Config.Main.AntiResourceStop and not GlobalState.IsAntiResourceStopDisabled and not restartingResources[resourceName] and serverResources[resourceName] then
        WaveShield.DetectPlayer(WaveShield.Detections.ANTI_RESOURCE_STOP, {
            event = "onResourceStop",
            resource = resourceName,
        })
    end
    resourceNumber = GetNumResources()
end)

AddEventHandler('onClientResourceStop', function (resourceName)
    if GetInvokingResource() ~= nil then return end
    
    WaveShield.Wait(5000)
    if WaveShield.Config.Main.AntiResourceStop and not GlobalState.IsAntiResourceStopDisabled and not restartingResources[resourceName] and serverResources[resourceName] then
        WaveShield.DetectPlayer(WaveShield.Detections.ANTI_RESOURCE_STOP, {
            event = "onClientResourceStop",
            resource = resourceName,
        })
    end
    resourceNumber = GetNumResources()
end)

WaveShield.CreateThread(function()
    resourceNumber = GetNumResources()

    while true do
        WaveShield.Wait(10000)

        if WaveShield.Config.Main.AntiResourceInjection then
            if resourceNumber ~= GetNumResources() then
                for i = 0, GetNumResources() - 1 do
                    local resourceName = GetResourceByFindIndex(i)
                    if not GlobalState.IsAntiResourceStopDisabled and not restartingResources[resourceName] and not serverResources[resourceName] then
                        WaveShield.DetectPlayer(WaveShield.Detections.ANTI_RESOURCE_INJECTION, {
                            resource = resourceName,
                        })
                        return
                    end
                end
            end
        end

        if WaveShield.Config.Main.AntiResourceStop then
            local resourceCount = 0
            for resourceName, v in WaveShield.Lua.pairs(clientResources) do
                if v == true and resourceName ~= "_cfx_internal" then
                    if not GlobalState.IsAntiResourceStopDisabled and not restartingResources[resourceName] then
                        local isAlive, lastHeartbeat = false, 0
                        local _,err = WaveShield.Lua.pcall(function()
                            isAlive, lastHeartbeat = exports[resourceName]:IsAlive()
                        end)
                        if err or not isAlive then
                            WaveShield.DetectPlayer(WaveShield.Detections.ANTI_RESOURCE_STOP, {
                                reason = "Resource is not running",
                                resourceName = resourceName,
                            })
                        elseif isAlive then
                            if WaveShield.type(lastHeartbeat) ~= "number" or lastHeartbeat <= 0 or (WaveShield.Native.GetGameTimer() - lastHeartbeat > 5000) then
                                WaveShield.DetectPlayer(WaveShield.Detections.ANTI_RESOURCE_STOP, {
                                    reason = "Suspended",
                                    resourceName = resourceName,
                                })
                                return
                            end
                        end
                    end
                end
                
                resourceCount = resourceCount + 1
                if resourceCount % 5 == 0 then
                    WaveShield.Wait(10)
                end
            end
        end
    end
end)
