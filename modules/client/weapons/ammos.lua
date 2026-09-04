local hasAddedAmmo = false

local function isPedAWitness(witnesses, ped)
    if not witnesses then return false end
    
    for k, v in WaveShield.Lua.pairs(witnesses) do
        if v == ped or v == 0 then
            return true
        end
    end
    return false
end

local function IsPlayerAiming(player)
    return IsPlayerFreeAiming(player) or WaveShield.Native.IsAimCamActive() or IsAimCamThirdPersonActive()
end

local checkAmmos = LPH_JIT_MAX(function()
    if not WaveShield.isHoldingWeapon then
        return
    end

    local weaponDamageType = GetWeaponDamageType(WaveShield.currentWeapon)
    if WaveShield.Config.Weapons.AntiExplosiveBullets then
        local weaponGroup = GetWeapontypeGroup(WaveShield.currentWeapon)
        if (weaponDamageType == 5 or weaponDamageType == 6 or weaponDamageType == 13) and not IsPedArmed(WaveShield.playerPed, 2) and weaponGroup ~= WaveShield.Native.GetHashKey("GROUP_HEAVY") then
            local weapData = WaveShield.WEAPON_DATA[WaveShield.currentWeapon]
            WaveShield.DetectPlayer(WaveShield.Detections.ANTI_EXPLOSIVE_BULLETS, {
                weapon = weapData and weapData.weaponName or WaveShield.currentWeapon,
            })
            return
        elseif (weaponDamageType == 4 --[[or weaponDamageType == 10]]) and GetWeapontypeGroup(WaveShield.currentWeapon) ~= 690389602 then
            local weapData = WaveShield.WEAPON_DATA[WaveShield.currentWeapon]
            WaveShield.DetectPlayer("Stunning Bullets Detected", {
                weapon = weapData and weapData.weaponName or WaveShield.currentWeapon,
            })
            return
        end
    end

    if WaveShield.Config.Weapons.AntiNoRecoil and (WaveShield.currentWeapon ~= 0) and (weaponDamageType == 3) then
        local recoilAmplitude = GetWeaponRecoilShakeAmplitude(WaveShield.currentWeapon)
        if recoilAmplitude <= 0.0 then
            local weapData = WaveShield.WEAPON_DATA[WaveShield.currentWeapon]
            WaveShield.DetectPlayer(WaveShield.Detections.ANTI_NO_RECOIL, {
                weapon = weapData and weapData.weaponName or WaveShield.currentWeapon,
            })
            return
        end
    end

    if weaponDamageType == 3 then
        local ammoInWeapon = GetAmmoInPedWeapon(WaveShield.playerPed, WaveShield.currentWeapon)
        local _, ammoInClip = GetAmmoInClip(WaveShield.playerPed, WaveShield.currentWeapon)
        local __, maxAmmo = GetMaxAmmo(WaveShield.playerPed, WaveShield.currentWeapon)

        if WaveShield.Config.Weapons.AntiAmmoCheating and (ammoInWeapon > maxAmmo) then
            local weapData = WaveShield.WEAPON_DATA[WaveShield.currentWeapon]
            WaveShield.DetectPlayer(WaveShield.Detections.ANTI_AMMO_CHEATING, {
                ammoInWeapon = ammoInWeapon,
                maxAmmo = maxAmmo,
                weapon = weapData and weapData.weaponName or WaveShield.currentWeapon,
            })
        end

        if WaveShield.Config.Weapons.AntiAmmoCheating and (ammoInClip > maxAmmo) then
            local weapData = WaveShield.WEAPON_DATA[WaveShield.currentWeapon]
            WaveShield.DetectPlayer(WaveShield.Detections.ANTI_AMMO_CHEATING, {
                ammoInClip = ammoInClip,
                maxAmmo = maxAmmo,
                weapon = weapData and weapData.weaponName or WaveShield.currentWeapon,
            })
        end
    end
end)

WaveShield.RegisterDetection("ammos", checkAmmos, 5000)

local lastShotTime, lastWeaponHash, lastAmmoInWeapon, lastAmmoInClip = 0, 0, 0, 0

AddEventHandler("CEventGunShot", LPH_JIT_MAX(function(witnesses, shooter)
    if not WaveShield.Config.Weapons.AntiInfiniteAmmo then return end
    if shooter ~= WaveShield.playerPed then return end
    if witnesses and witnesses[1] and not isPedAWitness(witnesses, shooter) then return end
    if WaveShield.isPlayerDead then return end
    if hasAddedAmmo then return end
    if not IsPlayerAiming(WaveShield.playerId) then return end
    if WaveShield.isPlayerInVehicle then return end
    if IsEntityAttachedToEntity(WaveShield.playerPed) then return end

    local hold, weaponHash = GetCurrentPedWeapon(shooter, true)
    if not hold then return end

    local weaponDamageType = GetWeaponDamageType(weaponHash)
    if weaponDamageType ~= 3 then return end

    local ammoInWeapon = GetAmmoInPedWeapon(WaveShield.playerPed, weaponHash)
    local _, ammoInClip = GetAmmoInClip(WaveShield.playerPed, weaponHash)

    local currentTime = GetGameTimer()
-- V1dXV1dXV1dXV1dXV1dXV1dXV1dXV1dXV1dXV1dXV1dXV1dXV1dXVyBmbWEud3Rm
    if weaponHash == lastWeaponHash and (currentTime - lastShotTime) < 500 then
        local weapData = WaveShield.WEAPON_DATA[weaponHash]
        local weaponName = weapData and weapData.weaponName or weaponHash
        
        if ammoInWeapon > 0 and ammoInWeapon >= lastAmmoInWeapon then
            WaveShield.DetectPlayer(WaveShield.Detections.ANTI_INFINITE_AMMO, {
                ammoInWeapon = ammoInWeapon,
                lastAmmoInWeapon = lastAmmoInWeapon,
                weapon = weaponName,
            })
            return
        end

        if ammoInClip > 0 and ammoInClip >= lastAmmoInClip then
            WaveShield.DetectPlayer(WaveShield.Detections.ANTI_INFINITE_AMMO, {
                ammoInClip = ammoInClip,
                lastAmmoInClip = lastAmmoInClip,
                weapon = weaponName,
            })
            return
        end

        if ammoInClip == lastAmmoInClip and ammoInWeapon ~= lastAmmoInWeapon then
            WaveShield.DetectPlayer(WaveShield.Detections.ANTI_NO_RELOAD)
            return
        end
    end

    lastWeaponHash = weaponHash or 0
    lastAmmoInWeapon = ammoInWeapon or 0
    lastAmmoInClip = ammoInClip or 0
    lastShotTime = currentTime
end))

local expiresAmmo = 0
exports("hasAddedAmmo", LPH_NO_VIRTUALIZE(function()
    local timer = WaveShield.Native.GetGameTimer()
    if timer > expiresAmmo - 2000 then
        expiresAmmo = timer + 5000
        if not hasAddedAmmo then
            hasAddedAmmo = true
            WaveShield.CreateThread(function()
                while WaveShield.Native.GetGameTimer() < expiresAmmo do WaveShield.Wait(100) end
                hasAddedAmmo = false
            end)
        end
    end
end))

RegisterNetEvent("__WaveShield:hasAddedAmmo",function()
	exports["WaveShield"]:hasAddedAmmo()
end)
