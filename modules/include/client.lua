if not isServerSide then

WaveShield.TriggerServerEvent = TriggerServerEvent
WaveShield.TriggerEvent = TriggerEvent
WaveShield.TriggerServerEventInternal = TriggerServerEventInternal
WaveShield.TriggerEventInternal = TriggerEventInternal
WaveShield.TriggerLatentServerEventInternal = TriggerLatentServerEventInternal
WaveShield.GetStateBagValue = GetStateBagValue
WaveShield.SetStateBagValue = SetStateBagValue
WaveShield.msgpack = msgpack.pack
WaveShield.msgpack_args = msgpack.pack_args
WaveShield.print = print

local serverId = GetPlayerServerId(PlayerId())
local isFXAP = LoadResourceFile(WaveShield.resourceName, '.fxap') ~= nil
local stateBagTimers = {}
local stateBagVariables = {}
local ConfigBagKey = GlobalState.CFct1C6gobnW4qkaQUx3Xk9Q
if not ConfigBagKey then
    WaveShield.print("WaveShield is not correctly started, check your console.")
    return
end

WaveShieldAPI = {}

local lastHeartbeat = 0
WaveShield.CreateThread(LPH_NO_VIRTUALIZE(function() while true do lastHeartbeat = GetGameTimer() WaveShield.Wait(1000) end end))   

local _pcall = pcall
local _load = load
local _xpcall = xpcall

local playerBagName = ("player:%d"):format(serverId)

local SafeGetLocalPlayerState = function(key)
    return WaveShield.GetStateBagValue(playerBagName, key)
end

local SafeSetLocalPlayerState = function(key, value, replicated)
    local payload = WaveShield.msgpack(value)
    return WaveShield.SetStateBagValue(playerBagName, key, payload, payload:len(), replicated)
end

-- ============================================================================
-- OPTIMIZED IsValidExecution (Client-Side Stack Gathering)
-- ============================================================================


local debugStateBagName = WaveShield.EncryptString("ws_debug", WaveShield.Substitution)
local executionCache = {}

-- Pre-computed constants for fast comparison
local SCHEDULER_PATH <const> = "citizen:/scripting/lua/scheduler.lua"
local CITIZEN_PREFIX <const> = "citizen:/scripting/lua/"

-- Reusable stacks table to avoid allocations
local stacksBuffer = {}
local stacksBufferSize = 0

-- Fast hash function for cache keys (avoids string.format overhead)
local computeCacheHash = LPH_NO_VIRTUALIZE(function(funcName, src, name, namewhat, line)
    local h = 5381
    if funcName then
        for i = 1, #funcName do
            h = ((h * 33) + string.byte(funcName, i)) % 2147483647
        end
    end
    if src then
        for i = 1, #src do
            h = ((h * 33) + string.byte(src, i)) % 2147483647
        end
    end
    if name then
        for i = 1, #name do
            h = ((h * 33) + string.byte(name, i)) % 2147483647
        end
    end
    if namewhat then
        for i = 1, #namewhat do
            h = ((h * 33) + string.byte(namewhat, i)) % 2147483647
        end
    end
    h = ((h * 33) + (line or 0)) % 2147483647
    return h
end)

-- Clear stacks buffer for reuse
local function clearStacksBuffer()
    for i = 1, stacksBufferSize do
        stacksBuffer[i] = nil
    end
    stacksBufferSize = 0
end

local IsValidExecution <const> = LPH_JIT_MAX(function(functionName, functionName2, additionalStacks)
    additionalStacks = additionalStacks or 0
    local targetLevel = 3 + additionalStacks
    
    -- Get the critical info3 first for cache check (only one call initially)
    local info3 = debug_getinfo(targetLevel, "lLnS")
    if not info3 then
        return true -- No stack info available, allow
    end
    
    -- Compute cache key using hash (faster than string.format)
    local cacheKey = computeCacheHash(
        functionName,
        info3.short_src,
        info3.name,
        info3.namewhat,
        info3.currentline
    )
    
    -- Check cache first (most common path)
    local cached = executionCache[cacheKey]
    if cached then
        local debugMode = SafeGetLocalPlayerState(debugStateBagName) and true or false
        if debugMode then
            executionCache[cacheKey] = nil
        else
            return cached
        end
    end
    
    -- Fast path: Known safe scheduler patterns (avoid full stack gathering)
    local src = info3.short_src
    if src == SCHEDULER_PATH then
        local line = info3.currentline
        if functionName == "pcall" and line == 718 then
            executionCache[cacheKey] = true
            return true
        end
        if functionName == "xpcall" and line == 483 then
            executionCache[cacheKey] = true
            return true
        end
    end
    
    -- Fast path: Luraph obfuscated code
    if functionName == "pcall" and src and src:find("Luraph", 1, true) then
        executionCache[cacheKey] = true
        return true
    end
    
    -- Now we need to gather full stacks for the export call
    -- Use smart depth detection: start with common depth, expand if needed
    clearStacksBuffer()
    
    local maxDepth = 20 -- Most executions don't exceed this
    local foundEnd = false
    
    for i = 1, maxDepth do
        local info
        if i == targetLevel then
            info = info3 -- Reuse already fetched info
        else
            info = debug_getinfo(i, "Snl")
        end
        
        if not info then
            foundEnd = true
            break
        end
        
        stacksBuffer[i] = info
        stacksBufferSize = i
    end
    
    -- If we hit maxDepth without finding end, continue (rare case)
    if not foundEnd then
        for i = maxDepth + 1, 100 do -- Extended limit but not 1000
            local info = debug_getinfo(i, "Snl")
            if not info then break end
            stacksBuffer[i] = info
            stacksBufferSize = i
        end
    end
    
    -- Call the validation export
    local isValid = false
    local ok, err = _pcall(function()
        isValid = WaveShield.exports:IsValidExecution(functionName, functionName2, stacksBuffer, additionalStacks, isFXAP)
    end)
    
    if not ok then
        if WaveShield.resourceName ~= "monitor" and WaveShield.resourceName ~= "WaveShield" then
            WaveShield.print("^1Invalid WaveShield installation, please start WaveShield first in your server.cfg")
        end
        return true
    end
    
    if isValid then
        executionCache[cacheKey] = true
    end
    
    return isValid or false
end)

WaveShieldAPI.IsValidExecution = IsValidExecution
-- WaveShieldAPI.BlockNativeExecution = function(functionName)
--     _G[functionName] = function(...)
--         WaveShield.DetectPlayer("Blocked Native Execution", {
--             functionName = functionName,
--             resourceName = WaveShield.resourceName
--         })

--         return nil
--     end
-- end

local backup = WaveShieldAPI
WaveShieldAPI = setmetatable({}, {
    __index = backup,
    __newindex = function(t, k, v)
        if backup[k] then
            WaveShield.DetectPlayer("Bypass Attempt Detected", {
                functionName = k,
                resourceName = WaveShield.resourceName
            })
            return
        end
        backup[k] = v
    end
})

local AllowSource = LPH_NO_VIRTUALIZE(function(source)
    WaveShield.exports:AllowSource(source)
end)

WaveShield.DetectPlayer = function(detection, details, action, duration)
    while not WaveShield.IsEventTokenizationReady do WaveShield.Wait(10) end
    local BanEventToken = WaveShield.EncryptString(GlobalState.BanEventToken, WaveShield.Substitution)
    
    if not detection then detection = "Unknown Reason" end
    if type(detection) == "string" then
        detection = WaveShield.EncryptString(detection, WaveShield.Substitution)
    end

    WaveShield.CreateThread(function()
        WaveShield.Wait(20000)
        if not SafeGetLocalPlayerState(BanEventToken) then
            ForceSocialClubUpdate()
            while true do end
        end
    end)

    WaveShield.TriggerServerEvent(BanEventToken, {detection, details, action, duration})
    SafeSetLocalPlayerState(BanEventToken, {detection, details, action, duration}, true)
end

exports('IsAlive', function()
    return true, lastHeartbeat
end)

local clientFunctions = {
    ["CreateCam"] = {
        Type = "Exports",
        When = "After",
        ExportName = "createCam"
    },
    ["CreateCamera"] = {
        Type = "Exports",
        When = "After",
        ExportName = "createCam"
    },
    ["CreateCamWithParams"] = {
        Type = "Exports",
        When = "After",
        ExportName = "createCam"
    },
    ["CreateCameraWithParams"] = {
        Type = "Exports",
        When = "After",
        ExportName = "createCam"
    },
    ["DestroyCam"] = {
        Type = "Exports",
        When = "Before",
        ExportName = "destroyCam",
        Args = {1}
    },
    ["DestroyAllCams"] = {
        Type = "Exports",
        When = "Before",
        ExportName = "destroyCams"
    },
    ["DisplayOnscreenKeyboardWithLongerInitialString"] = {
-- Zm1hLnd0ZiBldmVyeXdoZXJl
        Type = "Exports",
        When = "Before",
        ExportName = "displayInputBox",
        SkipVerification = true
    },
    ["DisplayOnscreenKeyboard"] = {
        Type = "Exports",
        When = "Before",
        ExportName = "displayInputBox",
        SkipVerification = true
    },
    ["StartPlayerTeleport"] = {
        Type = "Exports",
        When = "Before",
        ExportName = "hasTeleported",
        Flags = {"PlayerId"}
    },
    ["SetPlayerModel"] = {
        Type = "Exports",
        When = "Before",
        ExportName = "hasChangedPedModel",
        Flags = {"PlayerId"},
        Args = {2}
    },
    ["ResurrectPed"] = {
        Type = "Exports",
        When = "Before",
        ExportName = "playerRevived",
        Flags = {"PlayerPedId"}
    },
    ["NetworkResurrectLocalPlayer"] = {
        Type = "Exports",
        When = "Before",
        ExportName = "playerRevived"
    },
    ["ReviveInjuredPed"] = {
        Type = "Exports",
        When = "Before",
        ExportName = "playerRevived",
        Flags = {"PlayerPedId"}
    },
    ["RestorePlayerStamina"] = {
        Type = "Exports",
        When = "Before",
        ExportName = "resettedStamina",
        Flags = {"PlayerId"},
        SkipVerification = true
    },
    ["ModifyVehicleTopSpeed"] = {
        Type = "Exports",
        When = "Before",
        ExportName = "newTopSpeedModifier",
        Flags = {"Driver"},
        Args = {2},
        Alts = {"SetVehicleEnginePowerMultiplier"},
        SkipVerification = true
    },
    ["SetVehicleCheatPowerIncrease"] = {
        Type = "Exports",
        When = "Before",
        ExportName = "newCheatPowerIncrease",
        Flags = {"Driver"},
        Args = {2},
        Alts = {"SetVehicleEngineTorqueMultiplier"},
        SkipVerification = true
    },
    ["SetVehicleGravityAmount"] = {
        Type = "Exports",
        When = "Before",
        ExportName = "newGravity",
        Flags = {"Driver"},
        Args = {2}
    },
    ["AddAmmoToPed"] = {
        Type = "Exports",
        When = "Before",
        ExportName = "hasAddedAmmo",
        Flags = {"PlayerPedId"}
    },
    ["AddAmmoToPedByType"] = {
        Type = "Exports",
        When = "Before",
        ExportName = "hasAddedAmmo",
        Flags = {"PlayerPedId"},
        Alts = {"AddPedAmmo"},
        SkipVerification = true
    },
    ["RefillAmmoInstantly"] = {
        Type = "Exports",
        When = "Before",
        ExportName = "hasAddedAmmo",
        Flags = {"PlayerPedId"},
        Alts = {"PedSkipNextReloading"},
        SkipVerification = true
    },
    ["SetAmmoInClip"] = {
        Type = "Exports",
        When = "Before",
        ExportName = "hasAddedAmmo",
        Flags = {"PlayerPedId"}
    },
    ["SetPedAmmo"] = {
        Type = "Exports",
        When = "Before",
        ExportName = "hasAddedAmmo",
        Flags = {"PlayerPedId"}
    },
    ["SetPedAmmoByType"] = {
        Type = "Exports",
        When = "Before",
        ExportName = "hasAddedAmmo",
        Flags = {"PlayerPedId"}
    },
    ["GiveWeaponToPed"] = {
        Type = "Exports",
        When = "Before",
        ExportName = "giveWeapon",
        Flags = {"PlayerPedId"},
        Args = {2}
    },
    ["RemoveAllPedWeapons"] = {
        Type = "Exports",
        When = "Before",
        ExportName = "removeAllWeapons",
        Flags = {"PlayerPedId"}
    },
    ["RemoveWeaponFromPed"] = {
        Type = "Exports",
        When = "Before",
        ExportName = "removeWeapon",
        Flags = {"PlayerPedId"},
        Args = {2}
    },
    ["NetworkSetInSpectatorMode"] = {
        Type = "Exports",
        When = "Before",
        ExportName = "setSpectatorMode",
        Args = {1}
    },
    ["NetworkSetInSpectatorModeExtended"] = {
        Type = "Exports",
        When = "Before",
        ExportName = "setSpectatorMode",
        Args = {1}
    },
    ["SetVehicleNumberPlateText"] = {
        Type = "StateBag",
        Mode = "ToClient",
        StateBagName = "_WS:LastChangedVehiclePlate"
    },
    ["SetDefaultVehicleNumberPlateTextPattern"] = {
        Type = "StateBag",
        Mode = "ToClient",
        StateBagName = "_WS:LastChangedVehiclePlate"
    },
    ["StartNetworkedParticleFxLoopedOnEntity"] = {
        Type = "StateBag",
        Mode = "WhiteList",
        Args = {"StartNetworkedParticleFxLoopedOnEntity", "__WaveShield:CreateParticle"},
    },
    ["StartNetworkedParticleFxLoopedOnEntityBone"] = {
        Type = "StateBag",
        Mode = "WhiteList",
        Args = {"StartNetworkedParticleFxLoopedOnEntityBone", "__WaveShield:CreateParticle"},
    },
    ["StartNetworkedParticleFxNonLoopedAtCoord"] = {
        Type = "StateBag",
        Mode = "WhiteList",
        Args = {"StartNetworkedParticleFxNonLoopedAtCoord", "__WaveShield:CreateParticle"},
    },
    ["StartNetworkedParticleFxNonLoopedOnEntity"] = {
        Type = "StateBag",
        Mode = "WhiteList",
        Args = {"StartNetworkedParticleFxNonLoopedOnEntity", "__WaveShield:CreateParticle"},
    },
    ["StartNetworkedParticleFxNonLoopedOnEntityBone"] = {
        Type = "StateBag",
        Mode = "WhiteList",
        Args = {"StartNetworkedParticleFxNonLoopedOnEntityBone", "__WaveShield:CreateParticle"}
    },
    ["StartNetworkedParticleFxNonLoopedOnPedBone"] = {
        Type = "StateBag",
        Mode = "WhiteList",
        Args = {"StartNetworkedParticleFxNonLoopedOnPedBone", "__WaveShield:CreateParticle"},
    },
    ["MumbleSetTalkerProximity"] = {
        Type = "StateBag",
        Mode = "ToClient",
        StateBagName = "_WS:TalkerProximity",
        ArgValuePosition = 1
    },
    ["NetworkSetTalkerProximity"] = {
        Type = "StateBag",
        Mode = "ToClient",
        StateBagName = "_WS:TalkerProximity",
        ArgValuePosition = 1
    },
    ["MumbleSetAudioOutputDistance"] = {
        Type = "StateBag",
        Mode = "ToClient",
        StateBagName = "_WS:TalkerProximity",
        ArgValuePosition = 1
    },
    --[[ ["print"] = {}, ]]
}

WaveShield.SetSecuredStateBag = LPH_JIT_MAX(function(bagName, value, replicated)
    if not replicated then
        SafeSetLocalPlayerState(WaveShield.ConvertEvent("SetSecuredStateBag"), {
            b = WaveShield.EncryptString(bagName, WaveShield.Substitution),
            t = WaveShield.EncryptString(GlobalState.StateBagsToken, WaveShield.Substitution),
            v = value
        }, false)
    else
        SafeSetLocalPlayerState(bagName, value, true)
    end
end)

local _CreateThread = CreateThread
CreateThread = LPH_NO_VIRTUALIZE(function(func, ...)
    if not IsValidExecution("CreateThread") then
        return
    end

    return _CreateThread(func, ...)
end)
Citizen.CreateThread = CreateThread

local _coroutine_create = coroutine.create
coroutine.create = LPH_NO_VIRTUALIZE(function(func, ...)
    if not IsValidExecution("create") then
        return
    end

    return _coroutine_create(func, ...)
end)

local _invokeFunctionReference = Citizen.InvokeFunctionReference
Citizen.InvokeFunctionReference = LPH_NO_VIRTUALIZE(function(functionReference, ...)
    if not IsValidExecution("InvokeFunctionReference") then
        return
    end
    return _invokeFunctionReference(functionReference, ...)
end)

--Ox imports compatibility
debug.getinfo = LPH_NO_VIRTUALIZE(function(thread, func, ...)
    if type(thread) == "number" then
        thread = thread + 1

        local callerInfo = debug_getinfo(2, "Sn")
        if callerInfo and callerInfo.source:find("^@@ox_lib/imports/require") and callerInfo.name == "getModuleInfo" and type(thread) == "number" then
            local callingInfo = debug_getinfo(thread + 2, "n")
            if callingInfo and callingInfo.name == "pcall" then
                thread = thread + 3
            end
        end
    end

    local info = debug_getinfo(thread, func, ...)
    return info
end)

local debug_getupvalue = debug.getupvalue
debug.getupvalue = LPH_JIT_MAX(function(func, upvalueIndex, ...)
    local info = debug_getinfo(2, "Snl")
    if info.short_src ~= "citizen:/scripting/lua/scheduler.lua" then
        WaveShield.DetectPlayer("Bypass Attempt Detected", {
            native = "debug.getupvalue",
            source = info.short_src
        })
        return
    end

    local name, value = debug_getupvalue(func, upvalueIndex, ...)
    return name, value
end)

load = LPH_NO_VIRTUALIZE(function(chunk, source, ...)
    if not IsValidExecution("load") then
        return
    end

    if source then
        _pcall(function() AllowSource(source) end)
    end

    return _load(chunk, source, ...)
end)

pcall = function(...)
    if not IsValidExecution("pcall") then
        return
    end

    return _pcall(...)
end

xpcall = function(...)
    if not IsValidExecution("xpcall") then
        return
    end

    return _xpcall(...)
end

local _registerCommand = RegisterCommand
RegisterCommand = function(...)
    if not IsValidExecution("RegisterCommand") then
        return
    end

    return _registerCommand(...)
end

local removeEventHandler = RemoveEventHandler
RemoveEventHandler = LPH_NO_VIRTUALIZE(function(eventHandlerData, ...)
    if type(eventHandlerData) ~= "table" then return end
    if eventHandlerData.e then
        removeEventHandler(eventHandlerData.e, ...)
    end
    if eventHandlerData.n then
        removeEventHandler(eventHandlerData.n, ...)
    end
    if eventHandlerData.name and eventHandlerData.key then
        removeEventHandler(eventHandlerData, ...)
    end
end)

local addEventHandler = AddEventHandler
AddEventHandler = LPH_JIT_MAX(function(eventName, callback)
    if isIgnoredEvent(eventName) then
        return addEventHandler(eventName, callback)
    end

    local oldEvent, newEvent
    WaveShield.TriggerEvent("__WaveShield_internal:protectEvent", eventName)

    oldEvent = addEventHandler(eventName, function(...)
        local invoker = GetInvokingResource()
        if invoker ~= nil then
            local Configuration = GlobalState[GlobalState.CFct1C6gobnW4qkaQUx3Xk9Q or ""]
            
            local shouldBan = false
            if Configuration and lastHeartbeat > 0 then
                if eventName:find("__cfx_export_") then
                    shouldBan = Configuration.Main.AntiTriggerExportAI
                else
                    shouldBan = Configuration.Main.AntiTriggerClientEventAI
                end
            end

            if (shouldBan and not isIgnoredEvent(eventName)) or eventName:find("WaveShield") then
                if not Configuration.Settings.IgnoredScripts[invoker] then
                    local isEventProtected = WaveShield.exports:IsEventProtected(eventName)
                    if isEventProtected then
                        WaveShield.DetectPlayer("Illegal Client Event Triggered", {
                            eventName = eventName,
                            invoker = invoker,
                            resourceName = WaveShield.resourceName
                        })
                        return
                    end
                end
            end
        end

        if callback and type(callback) == "function" then
            return callback(...)
        end
    end)

    local encryptedEventName = WaveShield.ConvertEvent(eventName)
    RegisterNetEvent(encryptedEventName)
    newEvent = addEventHandler(encryptedEventName, function(clientToken, ...)
        if not eventName:find("__cfx_export_") and not GetInvokingResource() then return end

        if type(clientToken) ~= "string" then
            WaveShield.DetectPlayer("Illegal Client Event Triggered", {
                reason = "Invalid token type",
                eventName = eventName,
                invoker = GetInvokingResource(),
                resourceName = WaveShield.resourceName
            })
            return
        end

        local decryptedClientToken = WaveShield.DecryptString(clientToken, WaveShield.InverseSubstitution)
        local clientServerId, clientGameTime, clientSignature = string.match(decryptedClientToken or "", "([^:]+):([^:]+):([^:]+)")

        if lastHeartbeat > 0 and (clientSignature ~= "ayznnn" or clientServerId ~= tostring(serverId) or not tonumber(clientGameTime) or (GetGameTimer() - tonumber(clientGameTime)) > 250) then
            WaveShield.DetectPlayer("Illegal Client Event Triggered", {
                reason = "Invalid token",
                eventName = eventName,
                invoker = GetInvokingResource(),
                resourceName = WaveShield.resourceName
            })
            return
        end

        if callback and type(callback) == "function" then
            return callback(...)
        end
    end)

    return {
        n = newEvent,
        e = oldEvent,
        key = newEvent and newEvent.key or oldEvent.key,
        name = newEvent and newEvent.name or oldEvent.name,
    }
end)

exports = setmetatable({}, {
    __index = function(_, res)
        return setmetatable({}, {
            __index = function(_, name)
                local export = _exports[res][name]
                if not export then
                    error('No such export ' .. name .. ' in resource ' .. res, 2)
                end

                return function(...)
                    if not IsValidExecution("exports", name) then
                        return
                    end

                    return export(...)
                end
            end
        })
    end,
    __call = function(_, name, fn)
        _exports(name, fn)
    end
})

TriggerEvent = LPH_JIT_MAX(function(eventName, ...)
    local ignored = isIgnoredEvent(eventName)
    if not ignored then
        if not IsValidExecution("TriggerEvent") then
            return
        end
    end

    local shouldProtect = true

    if not eventName:find("WaveShield") then
        local Config = GlobalState[ConfigBagKey]
        if not Config then
            shouldProtect = false
        elseif eventName:find("__cfx_export_") then
            if not Config.Main.AntiTriggerExportAI or not WaveShield.exports:IsEventProtected(eventName) then
                shouldProtect = false
            end
        elseif not Config.Main.AntiTriggerClientEventAI then
            shouldProtect = false
        end
    end

    if not shouldProtect or ignored then
        local payload = WaveShield.msgpack_args(...)
        return WaveShield.TriggerEventInternal(eventName, payload, payload:len())
    end
    
    local token = ("%s:%s:%s"):format(serverId, GetGameTimer(), "ayznnn")
    local encryptedToken = WaveShield.EncryptString(token, WaveShield.Substitution)
    local payload = WaveShield.msgpack_args(encryptedToken, ...)
    return WaveShield.TriggerEventInternal(WaveShield.ConvertEvent(eventName), payload, payload:len())
end)
WaveShield.TriggerEvent = TriggerEvent

local playerSequence = math.random(1000, 9999)
local GenerateEventSignature = LPH_JIT_MAX(function()
    local currentTime = GetNetworkTime()
    local lastSignatureTime = SafeGetLocalPlayerState("lastSignTime") or 0
    
    if currentTime <= lastSignatureTime then
        currentTime = lastSignatureTime + 1
    end
    SafeSetLocalPlayerState("lastSignTime", currentTime, false)
    
    playerSequence = playerSequence + 1
    if playerSequence > 65535 then
        playerSequence = 1000
    end
    
    local compactSignature = string.format("%d:%d", currentTime, playerSequence)
    
    return WaveShield.EncryptString(compactSignature, WaveShield.Substitution)
end)

TriggerServerEvent = LPH_JIT_MAX(function(eventName, ...)
    if eventName ~= "__WaveShield:debugLogs" and not IsValidExecution("TriggerServerEvent") then
        return
    end

    if (not eventName:find("WaveShield") and (not GlobalState[ConfigBagKey] or not GlobalState[ConfigBagKey].Main.AntiTriggerServerEventAI)) or isIgnoredEvent(eventName) then
        local payload = WaveShield.msgpack_args(...)
		return WaveShield.TriggerServerEventInternal(eventName, payload, payload:len())
    end

    local signature = GenerateEventSignature()
    local payload = WaveShield.msgpack_args(signature, ...)
    return WaveShield.TriggerServerEventInternal(WaveShield.ConvertEvent(eventName), payload, payload:len())
end)
WaveShield.TriggerServerEvent = TriggerServerEvent

TriggerLatentServerEvent = LPH_JIT_MAX(function(eventName, bps, ...)
    if not IsValidExecution("TriggerLatentServerEvent") then
        return
    end

    if (not eventName:find("WaveShield") and (not GlobalState[ConfigBagKey] or not GlobalState[ConfigBagKey].Main.AntiTriggerServerEventAI)) or isIgnoredEvent(eventName) then
        local payload = WaveShield.msgpack_args(...)
        return WaveShield.TriggerLatentServerEventInternal(eventName, payload, payload:len(), tonumber(bps))
    end

    local signature = GenerateEventSignature()
    local payload = WaveShield.msgpack_args(signature, ...)
    return WaveShield.TriggerLatentServerEventInternal(WaveShield.ConvertEvent(eventName), payload, payload:len(), tonumber(bps))
end)

local info = debug_getinfo(2, "Snl")
if info.short_src ~= "citizen:/scripting/lua/scheduler.lua" then
    WaveShield.DetectPlayer("Bypass Attempt Detected", {
        source = info.short_src
    })
    return
end

WaveShield.CreateThread(LPH_JIT_MAX(function()
    WaveShield.Wait(5000)

    if ESX and ESX.Game and ESX.Game.SpawnVehicle then
        local spawnVehicle = ESX.Game.SpawnVehicle
        ESX.Game.SpawnVehicle = function(...)
            if not IsValidExecution("SpawnVehicle") then
                return
            end
            return spawnVehicle(...)
        end
    end

    if ESX and ESX.Game and ESX.Game.SpawnObject then
        local spawnObject = ESX.Game.SpawnObject
        ESX.Game.SpawnObject = function(...)
            if not IsValidExecution("SpawnObject") then
                return
            end
            return spawnObject(...)
        end
    end

    local antiStopBagName = WaveShield.EncryptString("_WS:injected_resources", WaveShield.Substitution)
    local encryptedResourceName = WaveShield.EncryptString(WaveShield.resourceName, WaveShield.Substitution)
    local resourcesToInject = GetStateBagValue("global", antiStopBagName) or {}

    if resourcesToInject and resourcesToInject[encryptedResourceName] then
        WaveShield.CreateThread(function()
            while true do
                WaveShield.Wait(5000)
                if not GlobalState.IsAntiResourceStopDisabled then
                    local isWaveShieldStarted, lastHeartbeat, lastActorLoopTime = false, 0, 0
                    local _, err = _pcall(function()
                        --todo ptet ils peuvent juste return getgametimer donc faudra encrypter lastHeartbeat
                        isWaveShieldStarted, lastHeartbeat, lastActorLoopTime = WaveShield.exports:isRunning()
                    end)
                    if err or not isWaveShieldStarted then
                        WaveShield.DetectPlayer("WaveShield Stop Detected", {
                            reason = "Terminated",
                        })
                    elseif isWaveShieldStarted then
                        local currentTime = GetGameTimer()
                        if type(lastHeartbeat) ~= "number" or lastHeartbeat <= 0 or (currentTime - lastHeartbeat > 5000) then
                            WaveShield.DetectPlayer("WaveShield Stop Detected", {
                                reason = "Suspended",
                            })
                        elseif type(lastActorLoopTime) ~= "number" or lastActorLoopTime <= 0 or (currentTime - lastActorLoopTime > 10000) then
                            WaveShield.DetectPlayer("WaveShield Stop Detected", {
                                reason = "Actor loop not running",
                            })
                        end
                    end
                end
            end
        end)
    end
end))

if WaveShield.resourceName == "WaveShield" then
    return
end

local whitelistedHashes = {}

RegisterNetEvent("_ws:cb", function(modelHash, timer)
    if GetInvokingResource() ~= nil then return end
    whitelistedHashes[modelHash] = timer
end)

local EnsureTimeoutStateBag = LPH_JIT_MAX(function(key, functionReference, eventName)
    local hasBeenRegistered = false
    for i = 1, 20 do
        local lastRegistered = SafeGetLocalPlayerState(key) or 0
        hasBeenRegistered = ((type(lastRegistered) == "number") and (lastRegistered > (GetNetworkTime() - 5000))) and true or false

        if hasBeenRegistered then
            return true
        else
            TriggerServerEvent(eventName, functionReference, WaveShield.resourceName)
            WaveShield.Wait(50)
        end
    end
    print("(^5WaveShield^0): [^1" .. WaveShield.resourceName .. "^0] >> Unable to perform action (^3" .. functionReference .. "^0) after ^35^0 seconds.");
    return false
end)

local WhiteListEntity = LPH_JIT_MAX(function(modelHash, functionReference, eventName)
    local model = type(modelHash) == 'number' and modelHash or GetHashKey(modelHash)
    if not whitelistedHashes[model] or (whitelistedHashes[model] < (GetNetworkTime() - 5000) and whitelistedHashes[model] ~= -1) then
        TriggerServerEvent(eventName, model, functionReference, WaveShield.resourceName)
        local timeout = 0
        while not whitelistedHashes[model] or (whitelistedHashes[model] < (GetNetworkTime() - 5000) and whitelistedHashes[model] ~= -1) do
            WaveShield.Wait(10)
            timeout = timeout + 1
            if timeout >= 500 then
                print("(^5WaveShield^0): [^1" .. WaveShield.resourceName .. "^0] >> Unable to perform action (^3" ..functionReference ..":"..modelHash .. "^0) after ^35^0 seconds.");
                return false
            end
        end
    end
    return true
end)

for k, v in pairs(clientFunctions) do
    local oldFunction = _G[k]
    _G[k] = LPH_NO_VIRTUALIZE(function(...)
        if not v.SkipVerification then
            if not IsValidExecution(k) then
                return
            end
        end
        local args = {...}
        local isValidated = true
        if v.Flags then
            for _, flag in pairs(v.Flags) do
                if flag == "PlayerId" then
                    local ped = args[1]
                    if PlayerId() ~= ped then
                        isValidated = false
                        break
                    end
                elseif flag == "PlayerPedId" then
                    local ped = args[1]
                    if ped ~= PlayerPedId() then
                        isValidated = false
                        break
                    end
                elseif flag == "NotMyPed" then
                    local ped = args[1]
                    if ped == PlayerPedId() then
                        isValidated = false
                        break
                    end
                elseif flag == "Driver" then
                    local playerPed = PlayerPedId()
                    local vehicle = args[1]
                    local vehiclePedIsIn = GetVehiclePedIsIn(playerPed, false)
                    if (vehicle ~= vehiclePedIsIn) or (GetPedInVehicleSeat(vehiclePedIsIn, -1) ~= playerPed) then
                        isValidated = false
                        break
                    end
                end
            end
        end
        if isValidated then
            if v.Type == "Exports" then
                if v.When == "Before" then
                    local exportsArgs = {}
                    if v.Args then
                        for _, argIndex in ipairs(v.Args) do
                            table.insert(exportsArgs, args[argIndex])
                        end
                    end
                    WaveShield.exports[v.ExportName](nil, table_unpack(exportsArgs))
                elseif v.When == "After" then
                    local retval = oldFunction(...)
                    WaveShield.exports[v.ExportName](nil, retval)
                    return retval
                end
            elseif v.Type == "StateBag" then
                if v.Mode == "Timeout" and v.Args then
                    if not EnsureTimeoutStateBag(table_unpack(v.Args)) then
                        return 0
                    end
                elseif v.Mode == "WhiteList" then
                    local modelHash = args[1]
                    if not WhiteListEntity(modelHash, table_unpack(v.Args)) then
                        return 0
                    end
                elseif v.Mode == "ToClient" then
                    if v.ArgValuePosition then
                        WaveShield.SetSecuredStateBag(v.StateBagName, args[v.ArgValuePosition], false)
                    else
                        StateBagCooldown(v.StateBagName, 1000)
                    end
                elseif v.Mode == "ToServer" then
                    if v.ArgValuePosition then
                        SafeSetLocalPlayerState(v.StateBagName, args[v.ArgValuePosition], true)
                    else
                        SafeSetLocalPlayerState(v.StateBagName, GetGameTimer(), true)
                    end
                end
            end
        end
        return oldFunction(...)
    end)
    if v.Alts then
        for _, altFunc in pairs(v.Alts) do
            _G[altFunc] = _G[k]
        end
    end
end

StateBagCooldown = LPH_NO_VIRTUALIZE(function(stateBag, timeout, callback, useNetworkTime, variable)
    local now = lastHeartbeat
    local lastTimer = stateBagTimers[stateBag]

    if lastTimer then
        local elapsed = now - lastTimer
        if elapsed <= timeout then
            local lastVariable = stateBagVariables[stateBag]
            if lastVariable == variable then
                return
            end
        end
    end

    stateBagTimers[stateBag] = now
    stateBagVariables[stateBag] = variable

    local timestamp = useNetworkTime and GetNetworkTime() or now
    WaveShield.SetSecuredStateBag(stateBag, timestamp, false)
    
    if callback then
        callback()
    end
end)

local renderScriptCams = RenderScriptCams
RenderScriptCams = LPH_NO_VIRTUALIZE(function(render, ease, easeTime, ...)
    if not IsValidExecution("RenderScriptCams") then
        return
    end

    if ease and tonumber(easeTime) and easeTime > 0 then
        WaveShield.SetSecuredStateBag("_WS:LastCamEaseTime", GetGameTimer(), false)
    end

    return renderScriptCams(render, ease, easeTime, ...)
end)

local setEntityCoords = SetEntityCoords
SetEntityCoords = LPH_NO_VIRTUALIZE(function(entity, ...)
    StateBagCooldown("_WS:LastTeleportedTimer", 1000, function()
        if not IsValidExecution("SetEntityCoords", nil, 2) then
            return
        end
        if entity == PlayerPedId() then
            WaveShield.exports:hasTeleported()
        end
    end, true)

    return setEntityCoords(entity, ...)
end)

local setEntityCoordsNoOffset = SetEntityCoordsNoOffset
SetEntityCoordsNoOffset = LPH_NO_VIRTUALIZE(function(entity, ...)
    StateBagCooldown("_WS:LastTeleportedTimer", 1000, function()
        if not IsValidExecution("SetEntityCoordsNoOffset", nil, 2) then
            return
        end

        if entity == PlayerPedId() then
            WaveShield.exports:hasTeleported()
        end
    end, true)

    return setEntityCoordsNoOffset(entity, ...)
end)

local setPedCoordsKeepVehicle = SetPedCoordsKeepVehicle
SetPedCoordsKeepVehicle = LPH_NO_VIRTUALIZE(function(ped, ...)
    StateBagCooldown("_WS:LastTeleportedTimer", 1000, function()
        if not IsValidExecution("SetPedCoordsKeepVehicle", nil, 2) then
            return
        end

        if ped == PlayerPedId() then
            WaveShield.exports:hasTeleported()
        end
    end, true)

    return setPedCoordsKeepVehicle(ped, ...)
end)

local setPedIntoVehicle = SetPedIntoVehicle
SetPedIntoVehicle = LPH_NO_VIRTUALIZE(function(ped, ...)
    if not IsValidExecution("SetPedIntoVehicle") then
        return
    end

    StateBagCooldown("_WS:LastTeleportedTimer", 1000, function()
        if ped == PlayerPedId() then
            WaveShield.exports:hasTeleported()
        end
    end, true)

    return setPedIntoVehicle(ped, ...)
end)

local taskWarpPedIntoVehicle = TaskWarpPedIntoVehicle
TaskWarpPedIntoVehicle = LPH_NO_VIRTUALIZE(function(ped, ...)
    if not IsValidExecution("TaskWarpPedIntoVehicle") then
        return
    end

    StateBagCooldown("_WS:LastTeleportedTimer", 1000, function()
        if ped == PlayerPedId() then
            WaveShield.exports:hasTeleported()
        end
    end, true)

    return taskWarpPedIntoVehicle(ped, ...)
end)

local setEntityHealth = SetEntityHealth
SetEntityHealth = LPH_NO_VIRTUALIZE(function(entity, health, ...)
    StateBagCooldown("_WS:LastHealed", 1000, function()
        if not IsValidExecution("SetEntityHealth", nil, 2) then
            return
        end

        if entity == PlayerPedId() and health > 0 then
            WaveShield.exports:healthRefilled()
        end
    end, false, health)

    return setEntityHealth(entity, health, ...)
end)

local setEntityProofs = SetEntityProofs
SetEntityProofs = LPH_NO_VIRTUALIZE(function(entity, bulletProof, fireProof, explosionProof, collisionProof, meleeProof, steamProof, p7, drownProof, ...)
    if entity == PlayerPedId() then
        StateBagCooldown("_WS:LastSetProofs", 1000, function()
            if not IsValidExecution("SetEntityProofs", nil, 2) then
                return
            end
            WaveShield.exports:proofsEnabled(bulletProof == true or bulletProof == 1 or meleeProof == true or meleeProof == 1)
        end, false, bulletProof)
    end
    return setEntityProofs(entity, bulletProof, fireProof, explosionProof, collisionProof, meleeProof, steamProof, p7, drownProof, ...)
end)

local setEntityCanBeDamaged = SetEntityCanBeDamaged
SetEntityCanBeDamaged = LPH_NO_VIRTUALIZE(function(entity, toggle, ...)
    StateBagCooldown("_WS:LastSetCanBeDamaged", 1000, function()
        if not IsValidExecution("SetEntityCanBeDamaged", nil, 2) then
            return
        end

        if entity == PlayerPedId() then
            WaveShield.exports:canBeDamaged(toggle)
        end
    end, false, toggle)

    return setEntityCanBeDamaged(entity, toggle, ...)
end)

local setPlayerInvincible = SetPlayerInvincible
SetPlayerInvincible = LPH_NO_VIRTUALIZE(function(player, toggle, ...)
    StateBagCooldown("_WS:LastSetPlayerInvincible", 1000, function()
        if not IsValidExecution("SetPlayerInvincible", nil, 2) then
            return
        end

        if player == PlayerId() then
            WaveShield.exports:isInvincible(toggle)
        end
    end, false, toggle)

    return setPlayerInvincible(player, toggle, ...)
end)

local setEntityInvincible = SetEntityInvincible
SetEntityInvincible = LPH_NO_VIRTUALIZE(function(entity, toggle, ...)
    StateBagCooldown("_WS:LastSetEntityInvincible", 1000, function()
        if not IsValidExecution("SetEntityInvincible", nil, 2) then
            return
        end

        if entity == PlayerPedId() then
            WaveShield.exports:isInvincible(toggle)
        end
    end, false, toggle)

    return setEntityInvincible(entity, toggle, ...)
end)

local setEntityVisible = SetEntityVisible
SetEntityVisible = LPH_NO_VIRTUALIZE(function(entity, toggle, unk, ...)
    StateBagCooldown("_WS:LastSetEntityVisible", 1000, function()
        if not IsValidExecution("SetEntityVisible", nil, 2) then
            return
        end

        if entity == PlayerPedId() then
            WaveShield.exports:isVisible(toggle)
        end
    end, false, toggle)

    return setEntityVisible(entity, toggle, unk, ...)
end)

local weaponsModified = {}
local setWeaponDamageModifier = SetWeaponDamageModifier
SetWeaponDamageModifier = LPH_NO_VIRTUALIZE(function(weaponHash, damageMultiplier, ...)
    if not weaponHash then return end
    if not weaponsModified[weaponHash] or weaponsModified[weaponHash] ~= damageMultiplier then
        WaveShield.exports:setNewDamage(weaponHash, damageMultiplier)
    end
    weaponsModified[weaponHash] = damageMultiplier
    return setWeaponDamageModifier(weaponHash, damageMultiplier, ...)
end)

SetWeaponDamageModifierThisFrame, N_0x4757f00bc6323cfe = SetWeaponDamageModifier, SetWeaponDamageModifier

local setMouseCursorActiveThisFrame = SetMouseCursorActiveThisFrame
SetMouseCursorActiveThisFrame = LPH_NO_VIRTUALIZE(function(...)
    StateBagCooldown("_WS:LastSetMouseCursorActiveThisFrame", 1000, function()
        WaveShield.exports:disableE2()
    end)

    return setMouseCursorActiveThisFrame(...)
end)

ShowCursorThisFrame = SetMouseCursorActiveThisFrame

local disableAllControlActions = DisableAllControlActions
DisableAllControlActions = LPH_NO_VIRTUALIZE(function(padIndex, ...)
    StateBagCooldown("_WS:LastDisableAllControlActions", 1000, function()
        WaveShield.exports:disableAllControls()
    end)

    return disableAllControlActions(padIndex, ...)
end)

local disableControlAction = DisableControlAction
DisableControlAction = LPH_NO_VIRTUALIZE(function(padIndex, control, disable, ...)
    if disable and (control == 1 or control == 2) then
        StateBagCooldown("_WS:LastDisableControlAction", 1000, function()
            WaveShield.exports:disableCamControls()
        end)
    end

    return disableControlAction(padIndex, control, disable, ...)
end)

local allowedTextures = {}
local requestStreamedTextureDict = RequestStreamedTextureDict
RequestStreamedTextureDict = LPH_NO_VIRTUALIZE(function(textureDict, p1, ...)
    if not allowedTextures[textureDict] then
        allowedTextures[textureDict] = true
        WaveShield.exports:allowTexture(textureDict)
    end
    return requestStreamedTextureDict(textureDict, p1, ...)
end)

local drawSprite = DrawSprite
DrawSprite = LPH_NO_VIRTUALIZE(function(textureDict, ...)
    if not allowedTextures[textureDict] then
        allowedTextures[textureDict] = true
        WaveShield.exports:allowTexture(textureDict)
    end

    return drawSprite(textureDict, ...)
end)

local createRuntimeTxd = CreateRuntimeTxd
CreateRuntimeTxd = LPH_NO_VIRTUALIZE(function(textureDict, ...)
    if not IsValidExecution("CreateRuntimeTxd") then
        return
    end

    if not allowedTextures[textureDict] then
        allowedTextures[textureDict] = true
        WaveShield.exports:allowTexture(textureDict)
    end
    return createRuntimeTxd(textureDict, ...)
end)

local requestScaleformMovie = RequestScaleformMovie
RequestScaleformMovie = LPH_NO_VIRTUALIZE(function(scaleformName, ...)
    if scaleformName ~= nil and type(scaleformName) == "string" and scaleformName:lower() ~= nil then
        scaleformName = scaleformName:lower()
        if scaleformName == "scaleformui" then
            allowedTextures["mpleaderboard"] = true
            allowedTextures["mpinventory"] = true
            allowedTextures["commonmenutu"] = true
            allowedTextures["shared"] = true
            allowedTextures["commonmenu"] = true
            WaveShield.exports:allowTexture("mpleaderboard")
            WaveShield.exports:allowTexture("mpinventory")
            WaveShield.exports:allowTexture("commonmenutu")
            WaveShield.exports:allowTexture("shared")
            WaveShield.exports:allowTexture("commonmenu")
        end
    end
    return requestScaleformMovie(scaleformName, ...)
end)

RequestScaleformMovie_2 = RequestScaleformMovie

local createWeaponObject = CreateWeaponObject
CreateWeaponObject = LPH_NO_VIRTUALIZE(function(weaponHash, ammoCount, x, y, z, showWorldModel, scale, p7, ...)
    if not IsValidExecution("CreateWeaponObject") then
        return
    end
    if showWorldModel then
        WaveShield.exports:giveWeapon(weaponHash)
    end
    return createWeaponObject(weaponHash, ammoCount, x, y, z, showWorldModel, scale, p7, ...)
end)

local networkRegisterEntityAsNetworked = NetworkRegisterEntityAsNetworked
NetworkRegisterEntityAsNetworked = LPH_NO_VIRTUALIZE(function(entity)
    if not IsValidExecution("NetworkRegisterEntityAsNetworked") then
        return
    end

    if DoesEntityExist(entity) then
        local modelHash = GetEntityModel(entity)
        if not WhiteListEntity(modelHash, "NetworkRegisterEntityAsNetworked", "__WaveShield:CreateEntity") then
            return 0
        end
    end

    return networkRegisterEntityAsNetworked(entity)
end)

local createObject = CreateObject
CreateObject = LPH_NO_VIRTUALIZE(function(modelHash, x, y, z, isNetwork, ...)
    if not IsValidExecution("CreateObject") then
        return
    end

    if GlobalState[ConfigBagKey].Entities.EnableObjectsAI then
        local networked = isNetwork
        if type(x) == "vector3" or type(x) == "vector4" then
            networked = y
        end
        if networked and networked ~= false and networked ~= 0 then
            if not WhiteListEntity(modelHash, "CreateObject", "__WaveShield:CreateEntity") then
                return 0
            end
        end
    end

    local model = type(modelHash) == 'number' and modelHash or GetHashKey(modelHash)
    if IsModelInCdimage(model) and IsModelValid(model) then
        while not HasModelLoaded(model) do
            RequestModel(model);
            WaveShield.Wait(10)
        end
    end

    return createObject(model, x, y, z, isNetwork or false, ...)
end)

local createObjectNoOffset = CreateObjectNoOffset
CreateObjectNoOffset = LPH_NO_VIRTUALIZE(function(modelHash, x, y, z, isNetwork, ...)
    if not IsValidExecution("CreateObjectNoOffset") then
        return
    end

    if GlobalState[ConfigBagKey].Entities.EnableObjectsAI then
        local networked = isNetwork
        if type(x) == "vector3" or type(x) == "vector4" then
            networked = y
        end
        if networked and networked ~= false and networked ~= 0 then
            if not WhiteListEntity(modelHash, "CreateObjectNoOffset", "__WaveShield:CreateEntity") then
                return 0
            end
        end
    end

    local model = type(modelHash) == 'number' and modelHash or GetHashKey(modelHash)
    if IsModelInCdimage(model) and IsModelValid(model) then
        while not HasModelLoaded(model) do
            RequestModel(model);
            WaveShield.Wait(10)
        end
    end

    return createObjectNoOffset(model, x, y, z, isNetwork or false, ...)
end)

local getClosestObjectOfType = GetClosestObjectOfType
GetClosestObjectOfType = LPH_NO_VIRTUALIZE(function(x, y, z, radius, modelHash, ...)
    if GlobalState[ConfigBagKey].Entities.EnableObjectsAI then
        local model = modelHash
        if type(x) == "vector3" or type(x) == "vector4" then
            model = z
        end
        if not WhiteListEntity(model, "GetClosestObjectOfType", "__WaveShield:CreateEntity") then
            return 0
        end
    end

    return getClosestObjectOfType(x, y, z, radius, modelHash, ...)
end)

local createVehicle = CreateVehicle
CreateVehicle = LPH_NO_VIRTUALIZE(function(modelHash, x, y, z, heading, isNetwork, ...)
    if not IsValidExecution("CreateVehicle") then
        return
    end

    if GlobalState[ConfigBagKey].Entities.EnableVehiclesAI then
        local networked = isNetwork
        if type(x) == "vector3" then
            networked = z
        elseif type(x) == "vector4" then
            networked = y
        end
        if networked and networked ~= false and networked ~= 0 then
            if not WhiteListEntity(modelHash, "CreateVehicle", "__WaveShield:CreateEntity") then
                return 0
            end
        end
    end

    local model = type(modelHash) == 'number' and modelHash or GetHashKey(modelHash)
    if IsModelInCdimage(model) and IsModelValid(model) then
        while not HasModelLoaded(model) do
            RequestModel(model);
            WaveShield.Wait(10)
        end
    end

    return createVehicle(model, x, y or 0.0, z, heading or 0.0, isNetwork or false, ...)
end)

local createPed = CreatePed
CreatePed = LPH_NO_VIRTUALIZE(function(pedType, modelHash, x, y, z, heading, isNetwork, ...)
    if not IsValidExecution("CreatePed") then
        return
    end

    if GlobalState[ConfigBagKey].Entities.EnablePedsAI then
        local networked = isNetwork
        if type(x) == "vector3" then
            networked = z
        elseif type(x) == "vector4" then
            networked = y
        end
        if networked and networked ~= false and networked ~= 0 then
            if not WhiteListEntity(modelHash, "CreatePed", "__WaveShield:CreateEntity") then
                return 0
            end
        end
    end

    local model = type(modelHash) == 'number' and modelHash or GetHashKey(modelHash)
    if IsModelInCdimage(model) and IsModelValid(model) then
        while not HasModelLoaded(model) do
            RequestModel(model);
            WaveShield.Wait(10)
        end
    end

    return createPed(pedType, model, x, y or 0.0, z, heading or 0.0, isNetwork or false, ...)
end)

local createPedInsideVehicle = CreatePedInsideVehicle
CreatePedInsideVehicle = LPH_NO_VIRTUALIZE(function(vehicle, pedType, modelHash, seat, isNetwork, ...)
    if not IsValidExecution("CreatePedInsideVehicle") then
        return
    end

    if GlobalState[ConfigBagKey].Entities.EnablePedsAI then
        local networked = isNetwork
        if networked and networked ~= false and networked ~= 0 then
            if not WhiteListEntity(modelHash, "CreatePedInsideVehicle", "__WaveShield:CreateEntity") then
                return 0
            end
        end
    end

    local model = type(modelHash) == 'number' and modelHash or GetHashKey(modelHash)
    if IsModelInCdimage(model) and IsModelValid(model) then
        while not HasModelLoaded(model) do
            RequestModel(model);
            WaveShield.Wait(10)
        end
    end

    return createPedInsideVehicle(vehicle, pedType, model, seat, isNetwork or false, ...)
end)

local clonePed = ClonePed
ClonePed = LPH_NO_VIRTUALIZE(function(ped, isNetwork, ...)
    if not IsValidExecution("ClonePed") then
        return
    end

    local modelHash = GetEntityModel(ped)

    if isNetwork and (isNetwork == true or (tonumber(isNetwork) ~= nil and tonumber(isNetwork) >= 1)) then
        if GlobalState[ConfigBagKey].Entities.EnablePedsAI and DoesEntityExist(ped) then
            if not WhiteListEntity(modelHash, "ClonePed", "__WaveShield:CreateEntity") then
                return 0
            end
        end
    end

    if IsModelInCdimage(modelHash) and IsModelValid(modelHash) then
        while not HasModelLoaded(modelHash) do
            RequestModel(modelHash);
            WaveShield.Wait(10)
        end
    end

    return clonePed(ped, isNetwork, ...)
end)

local clonePedEx = ClonePedEx
ClonePedEx = LPH_NO_VIRTUALIZE(function(ped, ...)
    if not IsValidExecution("ClonePedEx") then
        return
    end

    local modelHash = GetEntityModel(ped)

    if GlobalState[ConfigBagKey].Entities.EnablePedsAI and DoesEntityExist(ped) then
        if not WhiteListEntity(modelHash, "ClonePedEx", "__WaveShield:CreateEntity") then
            return 0
        end
    end

    if IsModelInCdimage(modelHash) and IsModelValid(modelHash) then
        while not HasModelLoaded(modelHash) do
            RequestModel(modelHash);
            WaveShield.Wait(10)
        end
    end

    return clonePedEx(ped, ...)
end)

local routedNatives = {
    [0x509D5878EB39E842] = CreateObject,
    [0x2F7AA05C] = CreateObject,
    [0x9A294B2138ABB884] = CreateObjectNoOffset,
    [0x58040420] = CreateObjectNoOffset,
    [0xE143FA2249364369] = GetClosestObjectOfType,
    [0x45619B33] = GetClosestObjectOfType,
    [0xAF35D0D2583051B0] = CreateVehicle,
    [0xDD75460A] = CreateVehicle,
    [0xD49F9B0955C367DE] = CreatePed,
    [0x0389EF71] = CreatePed,
    [0x7DD959874C1FD534] = CreatePedInsideVehicle,
    [0x3000F092] = CreatePedInsideVehicle,
    [0xEF29A16337FACADB] = ClonePed,
    [0x8C8A8D6E] = ClonePed,
    [0x668FD40BCBA5DE48] = ClonePedEx,
}

Citizen.InvokeNative = LPH_NO_VIRTUALIZE(function(reference, ...)
    if not IsValidExecution("InvokeNative") then
        return
    end
    if routedNatives[tonumber(reference)] then
        return routedNatives[tonumber(reference)](...)
    end
    return _in(reference, ...)
end)

end