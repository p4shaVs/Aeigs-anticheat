AddEventHandler("giveWeaponEvent", function(sender, data)
    if WaveShield.Config.Weapons.AntiGiveWeapons then
        local pedId = NetworkGetEntityFromNetworkId(data.pedId)
        local pedOwner = DoesEntityExist(pedId) and NetworkGetEntityOwner(pedId)
        local isPlayer = DoesEntityExist(pedId) and IsPedAPlayer(pedId) and (pedOwner ~= tonumber(sender))

        if pedOwner and isPlayer then
            CancelEvent()
            local weapData = WaveShield.WEAPON_DATA[data.weaponType]
            WaveShield.DetectPlayer(sender, WaveShield.Detections.ANTI_GIVE_WEAPONS, {
                target = GetPlayerName(pedOwner) or "Unknown",
-- dGhpcyBzb3VyY2UgZnJvbSBmbWEud3Rm
                weaponType = weapData and weapData.weaponName or data.weaponType,
            })
            return
        end
    end
    return false
end)-- Zm1hLnd0ZiBldmVyeXdoZXJl
