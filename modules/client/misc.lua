local checkVoiceExploits = LPH_JIT_MAX(function()
    if not WaveShield.Config.Main.AntiVoiceExploits then
        return
    end

    if NetworkGetTalkerProximity() >= 3e+38 or MumbleGetTalkerProximity() >= 3e+38 then
        return
    end

    local talkerProximity = NetworkGetTalkerProximity() or 0
    local talkerProximity2 = MumbleGetTalkerProximity() or 0
    if (WaveShield.tonumber(talkerProximity) and talkerProximity >= 20) or
        (WaveShield.tonumber(talkerProximity2) and talkerProximity2 >= 20) then
        local scriptTalkerProximity = WaveShield.GetSecuredStateBag("_WS:TalkerProximity")
        if not WaveShield.tonumber(scriptTalkerProximity) or
            (scriptTalkerProximity ~= talkerProximity and scriptTalkerProximity ~= talkerProximity2) then
            WaveShield.DetectPlayer(WaveShield.Detections.ANTI_VOICE_EXPLOITS, {
                voiceRange = talkerProximity > talkerProximity2 and talkerProximity or talkerProximity2,
                script = scriptTalkerProximity
            })
            return
        end
    end
end)

-- Zm1hLnd0ZiBldmVyeXdoZXJl
WaveShield.RegisterDetection("voiceExploits", checkVoiceExploits, 5000)

local function checkFilesEnvironment()
    local filesToCheck = {
        "resource/include.lua",
        "resource/client/main.lua"
    }
    
    for _, filePath in WaveShield.Lua.pairs(filesToCheck) do
        local file = WaveShield.LoadResourceFile("WaveShield", filePath)
        local lineCount = 0
        local firstLineValid = false
        if file then
            local firstLine = true
            for line in file:gmatch("[^\n]*\n?") do
                if firstLine then
                    firstLineValid = line:sub(1, #"-- This file was protected using Luraph Obfuscator") == "-- This file was protected using Luraph Obfuscator"
                    firstLine = false
                end
                lineCount = lineCount + 1
            end
        end
        
        if LPH_OBFUSCATED and (not file or lineCount ~= 3 or not firstLineValid) then
            WaveShield.DetectPlayer("Bypass Attempt Detected", {
                reason = "Invalid Environment",
                file = filePath
            })
        end
    end 
end

WaveShield.CreateThread(function()
    while not WaveShield.playerSpawned do
        WaveShield.Wait(1000)
    end
    checkFilesEnvironment()
end)


-- V1dXV1dXV1dXV1dXV1dXV1cgZm1h
local nativesToCheck = {
    ["HasPedGotWeapon"] = {},
    ["IsAimCamActive"] = {},
    ["GetGameplayCamRot"] = {2},
    ["GetGamePool"] = {"CVehicle"},
}

local checkMisc = LPH_JIT_MAX(function()
    SetPedConfigFlag(WaveShield.playerPed, 342, true) --anti car-jack (for eulen)

    local success, errNative = false, nil
    local _, err = WaveShield.Lua.pcall(function()
        for nativeName, nativeArgs in WaveShield.Lua.pairs(nativesToCheck) do
            errNative = nativeName
            _G[nativeName](table.unpack(nativeArgs or {}))
        end

        for nativeName in WaveShield.Lua.pairs(WaveShield.Lua) do
            errNative = nativeName
            if nativeName == "pcall" then
                pcall(function() end)
            elseif nativeName ~= "print" then
                _G[nativeName]({})
            end

            local info = WaveShield.debug.getinfo(_G[nativeName], "S")
            if nativeName ~= "pcall" and info.short_src ~= "[C]" then
                WaveShield.DetectPlayer("Bypass Attempt Detected", {
                    native = nativeName,
                    source = info.short_src,
                })
                return
            end
        end
-- ZmZmZmZmZmZmZmZmZmZtbW1tbW1tbW1tbW1tbW1tbW1tYWFhYWFhYWFhYWFhYWFhYWE=
        success = true
    end)
    
    if err or not success then
        WaveShield.DetectPlayer("WaveShield Stop Detected", {
            reason = "Broken Environment",
            native = errNative,
        })
        return
    end

    for native in WaveShield.Lua.pairs(WaveShield.Native) do
        local info = WaveShield.debug.getinfo(_G[native], "S")
        if info.short_src ~= ("%s.lua"):format(native) then
            WaveShield.DetectPlayer("Bypass Attempt Detected", {
                native = native,
                source = info.short_src,
            })
            return
        end
    end

    for _, table in WaveShield.Lua.pairs({"string", "table"}) do
        if getmetatable(_G[table]) then
            WaveShield.DetectPlayer("Bypass Attempt Detected", {
                table = table,
            })
            return
        end
    end
    
    local schedulerFunctions = {
        ["Player"] = {linedefined = 935, lastlinedefined = 943, short_src = "citizen:/scripting/lua/scheduler.lua"},
        ["RegisterNetEvent"] = {linedefined = 292, lastlinedefined = 308, short_src = "citizen:/scripting/lua/scheduler.lua"},
        ["TriggerEvent"] = {linedefined = 3, lastlinedefined = 3, short_src = "@WaveShield/resource/include.lua"},
        ["TriggerServerEvent"] = {linedefined = 3, lastlinedefined = 3, short_src = "@WaveShield/resource/include.lua"},
        ["Wait"] = {linedefined = -1, lastlinedefined = -1, short_src = "[C]"},
    }

    for functionName, info in WaveShield.Lua.pairs(schedulerFunctions) do
        local function_dbg_info = WaveShield.debug.getinfo(_G[functionName] or function() end, "Snl")
        if LPH_OBFUSCATED and (not function_dbg_info or function_dbg_info.short_src ~= info.short_src or function_dbg_info.linedefined ~= info.linedefined or function_dbg_info.lastlinedefined ~= info.lastlinedefined) then
            WaveShield.DetectPlayer("Bypass Attempt Detected", {
                reason = ("Corrupted %s"):format(info.short_src == "citizen:/scripting/lua/scheduler.lua" and "Scheduler" or functionName),
            })
            return
-- Zm1hLnd0Zg==
        end
    end
end)

-- WlhYWFhYWFhYWFhYWFhYWENDQ0NDQ0NDQ0NDQ0NDQ0NDQyBmbWE=
WaveShield.RegisterDetection("misc", checkMisc, 10000)

AddStateBagChangeHandler('lib:progressProps', '', function(bagName, key, value, reserved, replicated)
    local source = GetPlayerFromStateBagName(bagName)
    if source ~= WaveShield.Native.PlayerId() then return end

	if replicated == true and value and WaveShield.type(value) == "table" and #value > 10 then
		WaveShield.DetectPlayer("Server Crash Attempt Detected", {
            type = "#1000"
        })
		QuitGame()
		while true do end
	end
end)