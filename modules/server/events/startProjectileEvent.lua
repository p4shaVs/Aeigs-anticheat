local projectilesCreated = {}

AddEventHandler("startProjectileEvent", function(sender, data)
-- V1dXV1dXV1dXV1dXV1dXV1cgZm1h
    if WaveShield.Config.Weapons.EnableProjectilesWhiteList and not WaveShield.Config.Weapons.WhiteListedProjectiles[data.weaponHash] then
        CancelEvent()
        local weapData = WaveShield.WEAPON_DATA[data.weaponHash]
        WaveShield.DetectPlayer(sender, WaveShield.Detections.PROJECTILE_WHITELIST, {
            weapon = weapData and weapData.weaponName or data.weaponHash,
        })
-- b3JpZ2luYWwgb3duZXIgb2YgdGhpcyBzb3VyY2UgaXMgRk1B
        return
    end

    if WaveShield.Config.Weapons.EnableProjectilesLimiter then
        projectilesCreated[sender] = (projectilesCreated[sender] or 0) + 1

        if projectilesCreated[sender] >= tonumber(WaveShield.Config.Weapons.ProjectilesLimitIn5Seconds) then
            CancelEvent()
            local weapData = WaveShield.WEAPON_DATA[data.weaponHash]
            WaveShield.DetectPlayer(sender, WaveShield.Detections.PROJECTILE_LIMIT, {
                weapon = weapData and weapData.weaponName or data.weaponHash,
                limit = WaveShield.Config.Weapons.ProjectilesLimitIn5Seconds,
            })
            return
        end
    end
    if WaveShield.Config.Weapons.LogProjectileSpawnsToConsole and (GetPlayerName(sender) ~= nil) then
        WaveShield:print(("^3Projectile^0 spawned from weapon: ^3%s^0 by ^3%s^0 (id:^3%s^0)"):format(data.weaponHash, GetPlayerName(sender),sender),"^6","Projectiles")
    end
end)

CreateThread(function()
    while true do
        projectilesCreated = {}
        Wait(5000)
    end
end)
