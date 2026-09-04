-- Use centralized weapon data from WaveShield.WEAPON_DATA (utils.lua)
local defaultWeaponDamages = {}

-- Build default damages lookup for setNewDamage export
for i = 1, #WaveShield.WEAPON_DATA do
    local weaponData = WaveShield.WEAPON_DATA[i]
    if weaponData.weaponDamages > 0 then
        defaultWeaponDamages[weaponData.weaponHash] = weaponData.weaponDamages
    end
end

local weaponsComponents = {
    [GetHashKey('COMPONENT_COMBATPISTOL_CLIP_01')] = {ComponentName = "COMPONENT_COMBATPISTOL_CLIP_01"},
    [GetHashKey('COMPONENT_COMBATPISTOL_CLIP_02')] = {ComponentName = "COMPONENT_COMBATPISTOL_CLIP_02"},
    [GetHashKey('COMPONENT_APPISTOL_CLIP_01')] = {ComponentName = "COMPONENT_APPISTOL_CLIP_01"},
    [GetHashKey('COMPONENT_APPISTOL_CLIP_02')] = {ComponentName = "COMPONENT_APPISTOL_CLIP_02"},
    [GetHashKey('COMPONENT_MICROSMG_CLIP_01')] = {ComponentName = "COMPONENT_MICROSMG_CLIP_01"},
    [GetHashKey('COMPONENT_MICROSMG_CLIP_02')] = {ComponentName = "COMPONENT_MICROSMG_CLIP_02"},
    [GetHashKey('COMPONENT_REVOLVER_CLIP_01')] = {ComponentName = "COMPONENT_REVOLVER_CLIP_01"},
    [GetHashKey('COMPONENT_SNSPISTOL_CLIP_01')] = {ComponentName = "COMPONENT_SNSPISTOL_CLIP_01"},
    [GetHashKey('COMPONENT_HEAVYPISTOL_CLIP_01')] = {ComponentName = "COMPONENT_HEAVYPISTOL_CLIP_01"},
    [GetHashKey('COMPONENT_HEAVYPISTOL_CLIP_02')] = {ComponentName = "COMPONENT_HEAVYPISTOL_CLIP_02"},
    [GetHashKey('COMPONENT_VINTAGEPISTOL_CLIP_01')] = {ComponentName = "COMPONENT_VINTAGEPISTOL_CLIP_01"},
    [GetHashKey('COMPONENT_VINTAGEPISTOL_CLIP_02')] = {ComponentName = "COMPONENT_VINTAGEPISTOL_CLIP_02"},
    [GetHashKey('COMPONENT_CERAMICPISTOL_CLIP_01')] = {ComponentName = "COMPONENT_CERAMICPISTOL_CLIP_01"},
    [GetHashKey('COMPONENT_CERAMICPISTOL_CLIP_02')] = {ComponentName = "COMPONENT_CERAMICPISTOL_CLIP_02"},
    [GetHashKey('COMPONENT_MACHINEPISTOL_CLIP_01')] = {ComponentName = "COMPONENT_MACHINEPISTOL_CLIP_01"},
    [GetHashKey('COMPONENT_MACHINEPISTOL_CLIP_03')] = {ComponentName = "COMPONENT_MACHINEPISTOL_CLIP_03"},
    [GetHashKey('COMPONENT_HEAVYPISTOL_CLIP_02')] = {ComponentName = "COMPONENT_HEAVYPISTOL_CLIP_02"},
    [GetHashKey('COMPONENT_SMG_CLIP_01')] = {ComponentName = "COMPONENT_SMG_CLIP_01"},
    [GetHashKey('COMPONENT_SMG_CLIP_02')] = {ComponentName = "COMPONENT_SMG_CLIP_02"},
    [GetHashKey('COMPONENT_SMG_CLIP_03')] = {ComponentName = "COMPONENT_SMG_CLIP_03"},
    [GetHashKey('COMPONENT_MINISMG_CLIP_01')] = {ComponentName = "COMPONENT_MINISMG_CLIP_01"},
    [GetHashKey('COMPONENT_MINISMG_CLIP_02')] = {ComponentName = "COMPONENT_MINISMG_CLIP_02"},
    [GetHashKey('COMPONENT_ASSAULTRIFLE_CLIP_01')] = {ComponentName = "COMPONENT_ASSAULTRIFLE_CLIP_01"},
    [GetHashKey('COMPONENT_ASSAULTRIFLE_CLIP_02')] = {ComponentName = "COMPONENT_ASSAULTRIFLE_CLIP_02"},
    [GetHashKey('COMPONENT_CARBINERIFLE_CLIP_01')] = {ComponentName = "COMPONENT_CARBINERIFLE_CLIP_01"},
    [GetHashKey('COMPONENT_CARBINERIFLE_CLIP_02')] = {ComponentName = "COMPONENT_CARBINERIFLE_CLIP_02"},
    [GetHashKey('COMPONENT_ADVANCEDRIFLE_CLIP_01')] = {ComponentName = "COMPONENT_ADVANCEDRIFLE_CLIP_01"},
    [GetHashKey('COMPONENT_ADVANCEDRIFLE_CLIP_02')] = {ComponentName = "COMPONENT_ADVANCEDRIFLE_CLIP_02"},
    [GetHashKey('COMPONENT_MG_CLIP_01')] = {ComponentName = "COMPONENT_MG_CLIP_01"},
    [GetHashKey('COMPONENT_MG_CLIP_02')] = {ComponentName = "COMPONENT_MG_CLIP_02"},
    [GetHashKey('COMPONENT_COMBATMG_CLIP_01')] = {ComponentName = "COMPONENT_COMBATMG_CLIP_01"},
    [GetHashKey('COMPONENT_COMBATMG_CLIP_02')] = {ComponentName = "COMPONENT_COMBATMG_CLIP_02"},
    [GetHashKey('COMPONENT_PUMPSHOTGUN_CLIP_01')] = {ComponentName = "COMPONENT_PUMPSHOTGUN_CLIP_01"},
    [GetHashKey('COMPONENT_SAWNOFFSHOTGUN_CLIP_01')] = {ComponentName = "COMPONENT_SAWNOFFSHOTGUN_CLIP_01"},
    [GetHashKey('COMPONENT_ASSAULTSHOTGUN_CLIP_01')] = {ComponentName = "COMPONENT_ASSAULTSHOTGUN_CLIP_01"},
    [GetHashKey('COMPONENT_ASSAULTSHOTGUN_CLIP_02')] = {ComponentName = "COMPONENT_ASSAULTSHOTGUN_CLIP_02"},
    [GetHashKey('COMPONENT_SNIPERRIFLE_CLIP_01')] = {ComponentName = "COMPONENT_SNIPERRIFLE_CLIP_01"},
    [GetHashKey('COMPONENT_HEAVYSNIPER_CLIP_01')] = {ComponentName = "COMPONENT_HEAVYSNIPER_CLIP_01"},
    [GetHashKey('COMPONENT_MINIGUN_CLIP_01')] = {ComponentName = "COMPONENT_MINIGUN_CLIP_01"},
    [GetHashKey('COMPONENT_RPG_CLIP_01')] = {ComponentName = "COMPONENT_RPG_CLIP_01"},
    [GetHashKey('COMPONENT_GRENADELAUNCHER_CLIP_01')] = {ComponentName = "COMPONENT_GRENADELAUNCHER_CLIP_01"},
    [GetHashKey('COMPONENT_BULLPUPSHOTGUN_CLIP_01')] = {ComponentName = "COMPONENT_BULLPUPSHOTGUN_CLIP_01"},
    [GetHashKey('COMPONENT_ADVANCEDRIFLE_VARMOD_LUXE')] = {ComponentName = "COMPONENT_ADVANCEDRIFLE_VARMOD_LUXE"},
    [GetHashKey('COMPONENT_PISTOL_CLIP_01')] = {ComponentName = "COMPONENT_PISTOL_CLIP_01"},
    [GetHashKey('COMPONENT_PISTOL_CLIP_02')] = {ComponentName = "COMPONENT_PISTOL_CLIP_02"},
    [GetHashKey('COMPONENT_PISTOL50_CLIP_01')] = {ComponentName = "COMPONENT_PISTOL50_CLIP_01"},
    [GetHashKey('COMPONENT_PISTOL50_CLIP_02')] = {ComponentName = "COMPONENT_PISTOL50_CLIP_02"},
    [GetHashKey('COMPONENT_ASSAULTSMG_CLIP_01')] = {ComponentName = "COMPONENT_ASSAULTSMG_CLIP_01"},
    [GetHashKey('COMPONENT_ASSAULTSMG_CLIP_02')] = {ComponentName = "COMPONENT_ASSAULTSMG_CLIP_02"},
    [GetHashKey('COMPONENT_AT_RAILCOVER_01')] = {ComponentName = "COMPONENT_AT_RAILCOVER_01"},
    [GetHashKey('COMPONENT_AT_PI_FLSH')] = {ComponentName = "COMPONENT_AT_PI_FLSH"},
    [GetHashKey('COMPONENT_AT_PI_SUPP')] = {ComponentName = "COMPONENT_AT_PI_SUPP"},
    [GetHashKey('COMPONENT_AT_PI_SUPP_02')] = {ComponentName = "COMPONENT_AT_PI_SUPP_02"},
    [GetHashKey('COMPONENT_AT_AR_FLSH')] = {ComponentName = "COMPONENT_AT_AR_FLSH"},
    [GetHashKey('COMPONENT_AT_AR_AFGRIP')] = {ComponentName = "COMPONENT_AT_AR_AFGRIP"},
    [GetHashKey('COMPONENT_AT_AR_SUPP')] = {ComponentName = "COMPONENT_AT_AR_SUPP"},
    [GetHashKey('COMPONENT_AT_AR_SUPP_02')] = {ComponentName = "COMPONENT_AT_AR_SUPP_02"},
    [GetHashKey('COMPONENT_AT_SR_SUPP')] = {ComponentName = "COMPONENT_AT_SR_SUPP"},
    [GetHashKey('COMPONENT_AT_SCOPE_MACRO')] = {ComponentName = "COMPONENT_AT_SCOPE_MACRO"},
    [GetHashKey('COMPONENT_AT_SCOPE_MACRO_02')] = {ComponentName = "COMPONENT_AT_SCOPE_MACRO_02"},
    [GetHashKey('COMPONENT_AT_SCOPE_SMALL')] = {ComponentName = "COMPONENT_AT_SCOPE_SMALL"},
    [GetHashKey('COMPONENT_AT_SCOPE_SMALL_02')] = {ComponentName = "COMPONENT_AT_SCOPE_SMALL_02"},
    [GetHashKey('COMPONENT_AT_SCOPE_MEDIUM')] = {ComponentName = "COMPONENT_AT_SCOPE_MEDIUM"},
    [GetHashKey('COMPONENT_AT_SCOPE_LARGE')] = {ComponentName = "COMPONENT_AT_SCOPE_LARGE"},
    [GetHashKey('COMPONENT_AT_SCOPE_MAX')] = {ComponentName = "COMPONENT_AT_SCOPE_MAX"},
}

exports("setNewDamage", LPH_NO_VIRTUALIZE(function(weaponHash, modifier)
    if not weaponHash then return end
    local baseDamage = defaultWeaponDamages[weaponHash]
    if not baseDamage then
        baseDamage = math.floor(GetWeaponDamage(weaponHash, false) / (modifier or 1))
-- ZiBtIGE=
        defaultWeaponDamages[weaponHash] = baseDamage
    end
    
    -- Update the centralized weapon data
    local weapData = WaveShield.WEAPON_DATA[weaponHash]
    if weapData then
        weapData.weaponDamages = math.floor(baseDamage * modifier)
    end
end))

local checkWeaponDamages = LPH_JIT_MAX(function()
    if WaveShield.Config.Entities.NoCarKill then
        SetWeaponDamageModifier(GetHashKey("WEAPON_RAMMED_BY_CAR"), 0.0)
        SetWeaponDamageModifier(GetHashKey("WEAPON_RUN_OVER_BY_CAR"), 0.0)
    end
    
    if WaveShield.Config.Weapons.AntiWeaponComponentModifier then
        for componentHash,component in WaveShield.Lua.pairs(weaponsComponents) do
            local doesComponentExist, ___ = GetWeaponComponentHudStats(componentHash)
            if doesComponentExist then
                local damagesModifier = GetWeaponComponentDamageModifier(componentHash)
                local accuracyModifier = GetWeaponComponentAccuracyModifier(componentHash)
                local rangeDamagesModifier = GetWeaponComponentRangeDamageModifier(componentHash)
                local RangeModifier = GetWeaponComponentRangeModifier(componentHash)
                if damagesModifier > 1.1 then
                    WaveShield.DetectPlayer(WaveShield.Detections.ANTI_WEAPON_DAMAGES_MODIFIER, {
                        component = component.ComponentName,
                        modifier = damagesModifier,
                    })
                    return
                elseif accuracyModifier > 1.2 then
                    WaveShield.DetectPlayer(WaveShield.Detections.ANTI_WEAPON_COMPONENT_MODIFIER, {
                        type = "Accuracy",
                        component = component.ComponentName,
                        modifier = accuracyModifier,
                    })
                    return
                elseif rangeDamagesModifier > 1.0 then
                    WaveShield.DetectPlayer(WaveShield.Detections.ANTI_WEAPON_COMPONENT_MODIFIER, {
                        type = "Range Damages",
                        component = component.ComponentName,
                        modifier = rangeDamagesModifier,
                    })
                    return
                elseif RangeModifier > 1.0 then
                    WaveShield.DetectPlayer(WaveShield.Detections.ANTI_WEAPON_COMPONENT_MODIFIER, {
                        type = "Range",
                        component = component.ComponentName,
                        modifier = RangeModifier,
                    })
                    return
                end
            end
        end
    end

    if WaveShield.Config.Weapons.AntiWeaponDamagesModifier then
        if WaveShield.currentWeapon ~= -1569615261 then
            local weapDamages = math.floor(GetWeaponDamage(WaveShield.currentWeapon, false))
            local weapDamagesModifier = GetWeaponDamageModifier(WaveShield.currentWeapon)
            local weapData = WaveShield.WEAPON_DATA[WaveShield.currentWeapon]
            
            if weapData and weapData.weaponDamages > 0 and (weapDamages > weapData.weaponDamages + 1) then
                WaveShield.DetectPlayer(WaveShield.Detections.ANTI_WEAPON_DAMAGES_MODIFIER, {
                    weapon = weapData.weaponName or WaveShield.currentWeapon,
                    damages = weapDamages,
                    defaultDamages = weapData.weaponDamages,
                })
                return
            end

            if weapDamagesModifier > 1.1 then
                WaveShield.DetectPlayer(WaveShield.Detections.ANTI_WEAPON_DAMAGES_MODIFIER, {
                    weapon = weapData and weapData.weaponName or WaveShield.currentWeapon,
                    multiplier = weapDamagesModifier,
                })
                return
            end

            if GetPlayerWeaponDamageModifier(WaveShield.playerId) > 1.0 then
                WaveShield.DetectPlayer(WaveShield.Detections.ANTI_WEAPON_DAMAGES_MODIFIER, {
                    type = "Weapon Damages",
                    multiplier = GetPlayerWeaponDamageModifier(WaveShield.playerId),
                })
                return
            elseif GetPlayerWeaponDefenseModifier(WaveShield.playerId) > 1.0 then
                WaveShield.DetectPlayer(WaveShield.Detections.ANTI_WEAPON_DAMAGES_MODIFIER, {
                    type = "Weapon Defense",
                    multiplier = GetPlayerWeaponDefenseModifier(WaveShield.playerId),
                })
                return
            elseif GetPlayerWeaponDefenseModifier_2(WaveShield.playerId) > 1.0 then
                WaveShield.DetectPlayer(WaveShield.Detections.ANTI_WEAPON_DAMAGES_MODIFIER, {
                    type = "Weapon Defense 2",
                    multiplier = GetPlayerWeaponDefenseModifier_2(WaveShield.playerId),
                })
                return
            elseif GetPlayerMeleeWeaponDefenseModifier(WaveShield.playerId) > 1.0 then
                WaveShield.DetectPlayer(WaveShield.Detections.ANTI_WEAPON_DAMAGES_MODIFIER, {
                    type = "Melee Defense",
                    multiplier = GetPlayerMeleeWeaponDefenseModifier(WaveShield.playerId),
                })
                return
            elseif GetPlayerMeleeWeaponDamageModifier(WaveShield.playerId) > 1.0 then
                WaveShield.DetectPlayer(WaveShield.Detections.ANTI_WEAPON_DAMAGES_MODIFIER, {
                    type = "Melee Damage",
                    multiplier = GetPlayerMeleeWeaponDamageModifier(WaveShield.playerId),
                })
                return
            end
        end
    end
end)

WaveShield.RegisterDetection("weaponDamages", checkWeaponDamages, 10000)

RegisterNetEvent("__WaveShield:CheckSpoofedBullets", function(selectedWeapon, spoofedWeapon, damageTime)
    local hold, weaponHash = GetCurrentPedWeapon(WaveShield.playerPed, true)
    local myWeapon = signedToUnsigned(weaponHash)
    if
        (not IsPedDeadOrDying(WaveShield.playerPed, true))
        and (not IsPedRunningMeleeTask(WaveShield.playerPed))
        and ((myWeapon ~= selectedWeapon) or (myWeapon ~= spoofedWeapon))
        and not WaveShield.Native.HasPedGotWeapon(WaveShield.playerPed, spoofedWeapon, false)
        and (not IsPedDoingDriveby(WaveShield.playerPed))
        and (not IsPedInFlyingVehicle(WaveShield.playerPed))
        and (GetWeaponDamageType(spoofedWeapon) == 3 or GetWeaponDamageType(spoofedWeapon) == 10) and
        ((GetNetworkTime() - (WaveShield.GetSecuredStateBag("_WS:LastTeleportedTimer") or 0)) > 10000)
    then
        WaveShield.TriggerServerEvent("__WaveShield:CheckSpoofedBullets", myWeapon, selectedWeapon, spoofedWeapon, damageTime)
    end
end)

-- AddEventHandler("gameEventTriggered", function(name, data)
--     if name == "CEventNetworkEntityDamage" then
--         local ped = PlayerPedId()
--         local victim = data[1]
--         local attacker = data[2]
--         local damageHash = data[3]
--         local isFatal = data[6]
--         local weaponHash = data[7]

--         if ped == attacker and victim ~= ped and IsPedAPlayer(victim) then
--             if not HasEntityBeenDamagedByWeapon(victim, weaponHash, 0) then return end
--             if GetWeaponDamageType(weaponHash) ~= 3 then return end
--         end
--     else
--         WaveShield.print(name, json.encode(data, {indent = true}))
--     end
-- end)
