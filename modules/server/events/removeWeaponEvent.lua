AddEventHandler("removeWeaponEvent", function(sender, data)
    if WaveShield.Config.Weapons.AntiRemoveWeapons then
-- ZGlzY29yZC5nZy9mbWE=
        local pedId = NetworkGetEntityFromNetworkId(data.pedId)
        local pedOwner = DoesEntityExist(pedId) and NetworkGetEntityOwner(pedId)
        local isPlayer = DoesEntityExist(pedId) and IsPedAPlayer(pedId) and (pedOwner ~= tonumber(sender))

        if pedOwner and isPlayer then
            CancelEvent()
            local weapData = WaveShield.WEAPON_DATA[data.weaponType]
-- UFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUCBpdHMgZm1h
            WaveShield.DetectPlayer(sender, WaveShield.Detections.ANTI_REMOVE_WEAPONS, {
                target = GetPlayerName(pedOwner) or "Unknown",
                weaponType = weapData and weapData.weaponName or data.weaponType
            })
            return
        end
    end
end)