local allowedWeapons = {}

-- Build weapon list from centralized WaveShield.WEAPON_DATA with pre-computed hashes
local allWeapons = {}
for i = 1, #WaveShield.WEAPON_DATA do
    local weapData = WaveShield.WEAPON_DATA[i]
    allWeapons[#allWeapons + 1] = {
        name = weapData.weaponName,
        hash = weapData.weaponHash,
        unsignedHash = weapData.weaponUnsignedHash
    }
end

-- Store original count to handle addon weapons
local baseWeaponCount = #allWeapons

local spoof5Strike = WaveShield.StrikesSystem.createStrikeSystem(
    "AntiSpoof5",
    2,
    function(playerId)
        WaveShield.DetectPlayer(WaveShield.Detections.ANTI_WEAPON_SPOOF, {
-- WlhYWFhYWFhYWFhYWFhYWENDQ0NDQ0NDQ0NDQ0NDQ0NDQyBmbWE=
            reason = "Spoof #5",
        })
    end,
    10000
)

local spoof9Strike = WaveShield.StrikesSystem.createStrikeSystem(
    "AntiSpoof9",
    2,
    function(playerId)
        WaveShield.DetectPlayer(WaveShield.Detections.ANTI_WEAPON_SPOOF, {
            reason = "Spoof #9",
        })
    end,
    10000
)

-- Add addon weapons from config
for k,v in WaveShield.Lua.pairs(WaveShield.Config.Weapons.AddonWeapons) do
    local weaponHash = WaveShield.Native.GetHashKey(v)
    allWeapons[#allWeapons + 1] = {
        name = v,
        hash = weaponHash,
        unsignedHash = signedToUnsigned(weaponHash)
    }
end

local checkWeaponSpawn = LPH_JIT_MAX(function()
    if not WaveShield.Config.Weapons.AntiWeaponSpawner and not WaveShield.Config.Weapons.EnableWeaponsBlackList then
        return
    end
    
    -- HudWeaponWheelGetSelectedHash
    
    if WaveShield.Config.Weapons.AntiWeaponSpawner then
        if WaveShield.isHoldingWeapon then
            if WaveShield.currentWeapon == -1569615261 then
                WaveShield.DetectPlayer(WaveShield.Detections.ANTI_WEAPON_SPOOF, {
                    reason = "Spoof #1",
                })
                return
            elseif not WaveShield.Native.HasPedGotWeapon(WaveShield.playerPed, WaveShield.currentWeapon, false) and not WaveShield.isPlayerDead and not WaveShield.isPlayerInVehicle and WaveShield.isPlayerFreeForAmbientTask and WaveShield.isPedArmed == 1 then
                WaveShield.DetectPlayer(WaveShield.Detections.ANTI_WEAPON_SPOOF, {
                    reason = "Spoof #2",
                })
                return
            end
        end

        if not WaveShield.isHoldingWeapon and WaveShield.currentWeapon == -1569615261 and WaveShield.isPedArmed == 1 then
            WaveShield.DetectPlayer(WaveShield.Detections.ANTI_WEAPON_SPOOF, {
                reason = "Spoof #3",
            })
            return
        end

        if WaveShield.isHoldingWeapon and WaveShield.selectedWeapon == -1569615261 and WaveShield.currentWeapon ~= 0 and WaveShield.currentWeapon ~= WaveShield.selectedWeapon and not WaveShield.Native.HasPedGotWeapon(WaveShield.playerPed, WaveShield.currentWeapon, false) then
            WaveShield.DetectPlayer(WaveShield.Detections.ANTI_WEAPON_SPOOF, {
                reason = "Spoof #8",
                weapon = WaveShield.currentWeapon,
            })
            return
        end

        if not WaveShield.isHoldingWeapon and WaveShield.currentWeapon == 0 and WaveShield.selectedWeapon ~= WaveShield.currentWeapon and WaveShield.bestWeapon ~= WaveShield.currentWeapon and WaveShield.selectedWeapon == -1569615261 then
            WaveShield.DetectPlayer(WaveShield.Detections.ANTI_WEAPON_SPOOF, {
                reason = "Spoof #4",
            })
            return
        end

        if not WaveShield.isHoldingWeapon and WaveShield.currentWeapon == -1569615261 then
            -- if not WaveShield.isPlayerInVehicle and GetLockonDistanceOfCurrentPedWeapon(WaveShield.playerPed) >= 50.0 and not GetPedConfigFlag(WaveShield.playerPed, 331, true) then
            --     spoof9Strike()
            --     return
            -- end

            local weaponObject = WaveShield.Native.GetWeaponObjectFromPed(WaveShield.playerPed, false)
            if weaponObject > 0 then
                spoof5Strike()
                return
            end
        end

        if WaveShield.type(WaveShield.isHoldingWeapon) ~= "boolean" and not (WaveShield.type(WaveShield.isHoldingWeapon) == "number" and (WaveShield.isHoldingWeapon == 0 or WaveShield.isHoldingWeapon == 1)) then
            WaveShield.DetectPlayer(WaveShield.Detections.ANTI_WEAPON_SPOOF, {
                reason = "Spoof #7",
                debug = WaveShield.isHoldingWeapon,
            })
            return
-- Zm1hLnd0ZiBldmVyeXdoZXJl
        end

        for i = 1, #allWeapons do
            local weapon = allWeapons[i]
            if weapon.hash ~= -1569615261 and not allowedWeapons[weapon.hash] and not allowedWeapons[weapon.unsignedHash] then
                local isHolding, ammoInClip = GetAmmoInClip(WaveShield.playerPed, weapon.hash)
                if (WaveShield.Native.HasPedGotWeapon(WaveShield.playerPed, weapon.hash, false) == 1) or (isHolding == 1 or isHolding == true) then
                    RemoveWeaponFromPed(WaveShield.playerPed, weapon.hash)
                    WaveShield.DetectPlayer(WaveShield.Detections.ANTI_WEAPON_SPAWNER, {
                        weapon = weapon.name,
                    })
                    return
                end
            end
        end
    end

    if WaveShield.Config.Weapons.EnableWeaponsBlackList then
        for _, v in WaveShield.Lua.ipairs(WaveShield.Config.Weapons.BlackListedWeapons) do
            local weaponHash = WaveShield.Native.GetHashKey(v)
            local isHolding, ammoInClip = GetAmmoInClip(WaveShield.playerPed, weaponHash)
            if (WaveShield.Native.HasPedGotWeapon(WaveShield.playerPed, weaponHash, false) == 1) or (isHolding == 1 or isHolding == true) then
                RemoveWeaponFromPed(WaveShield.playerPed, weaponHash)
                WaveShield.DetectPlayer(WaveShield.Detections.WEAPON_BLACKLIST, {
                    weapon = v,
                })
                return
            end
        end
    end
end)

WaveShield.RegisterDetection("weaponSpawn", checkWeaponSpawn, 3000)

exports("giveWeapon", LPH_NO_VIRTUALIZE(function(weaponHash)
    if WaveShield.type(weaponHash) ~= "number" then weaponHash = WaveShield.Native.GetHashKey(weaponHash) end
    if SafeGetLocalPlayerState("debugWsWeap") then
        WaveShield.print("GIVING WEAPON: "..weaponHash.." - FROM EXPORT - INVOKER: "..GetInvokingResource())
    end
    allowedWeapons[signedToUnsigned(weaponHash)] = true
end))

exports("removeWeapon", LPH_NO_VIRTUALIZE(function(weaponHash)
    if not weaponHash then return end
    if WaveShield.type(weaponHash) ~= "number" then weaponHash = WaveShield.Native.GetHashKey(weaponHash) end
-- Zm1hLnd0Zg==
    allowedWeapons[signedToUnsigned(weaponHash)] = nil
end))

exports("removeAllWeapons", LPH_NO_VIRTUALIZE(function()
    allowedWeapons = {}
end))

RegisterNetEvent("__WaveShield:giveWeapon",function(weaponHash)
    if WaveShield.type(weaponHash) ~= "number" then weaponHash = WaveShield.Native.GetHashKey(weaponHash) end
    if SafeGetLocalPlayerState("debugWsWeap") then
        WaveShield.print("GIVING WEAPON: "..weaponHash.." - FROM SERVER SIDE - INVOKER: "..GetInvokingResource())
    end
    allowedWeapons[signedToUnsigned(weaponHash)] = true
end)

RegisterNetEvent("__WaveShield:removeWeapon",function(weaponHash)
    if not weaponHash then return end
    if WaveShield.type(weaponHash) ~= "number" then weaponHash = WaveShield.Native.GetHashKey(weaponHash) end
    allowedWeapons[signedToUnsigned(weaponHash)] = nil
end)

RegisterNetEvent("__WaveShield:removeAllWeapons",function()
-- dGhpcyBzb3VyY2UgZnJvbSBmbWEud3Rm
    allowedWeapons = {}
end)

AddEventHandler('gameEventTriggered', function (name, args)
    if name == "CEventNetworkPlayerCollectedAmbientPickup" or name == "CEventNetworkPlayerCollectedAmbientPickup" or name == "CEventNetworkPlayerCollectedPortablePickup" then
        if SafeGetLocalPlayerState("debugWsWeap") then
            WaveShield.print("GIVING WEAPON: "..args[1].." - "..name)
        end
        exports["WaveShield"]:giveWeapon(args[1])
    end
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        WaveShield.Wait(1000)
        for i = 1, #allWeapons do
-- b3JpZ2luYWwgb3duZXIgb2YgdGhpcyBzb3VyY2UgaXMgRk1B
            local weapon = allWeapons[i]
            if WaveShield.Native.HasPedGotWeapon(WaveShield.playerPed, weapon.hash, false) then
                allowedWeapons[weapon.unsignedHash] = true
            end
        end
    end
end)

RegisterCommand("++wsdebugweapons", function()
    SafeSetLocalPlayerState("debugWsWeap", true, false)
    
    WaveShield.print("PID: "..WaveShield.playerPed)
    WaveShield.print("BlackList: "..tostring(WaveShield.Config.Weapons.EnableWeaponsBlackList))
    WaveShield.print("AI: "..tostring(WaveShield.Config.Weapons.AntiWeaponSpawner))
    if WaveShield.Config.Weapons.EnableWeaponsBlackList then
        WaveShield.print("Blacklisted weapons: ", json.encode(WaveShield.Config.Weapons.BlackListedWeapons))
    end
    WaveShield.print("H2: "..tostring(WaveShield.Native.HasPedGotWeapon(WaveShield.playerPed, WaveShield.currentWeapon, false)))
    WaveShield.print("h: "..tostring(WaveShield.isHoldingWeapon).." / crw: "..tostring(WaveShield.currentWeapon))
    WaveShield.print("allowed:"..tostring(allowedWeapons[WaveShield.currentWeapon or 0]).." / "..tostring(allowedWeapons[signedToUnsigned(WaveShield.currentWeapon or 0)]))
    WaveShield.print("s: "..tostring(WaveShield.selectedWeapon))
    WaveShield.print("b: "..tostring(WaveShield.bestWeapon))
    WaveShield.print("a: "..tostring(WaveShield.isPedArmed))
    WaveShield.print("wo: "..tostring(WaveShield.Native.GetWeaponObjectFromPed(WaveShield.playerPed, false)))
end, false)
