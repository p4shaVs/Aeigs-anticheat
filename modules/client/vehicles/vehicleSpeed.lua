local scriptGravity = 25.0
local scriptCheatPowerIncrease = 1.1
local scriptTopSpeedModifier = 1.1

local overridedBoosts = {
    [GetHashKey("sanchez")] = 18.0,
    [GetHashKey("sanchez2")] = 18.0,
    [GetHashKey("banshee2")] = 20.0,
}

local checkVehicleSpeed = LPH_JIT_MAX(function()
    if not WaveShield.Config.Entities.AntiSpeedModifier and not WaveShield.Config.Entities.AntiHandlingModifier then
        return
    end

    if not WaveShield.isPlayerInVehicle or not WaveShield.isPlayerDriver then
        return
    end
    
    if WaveShield.Config.Entities.AntiSpeedModifier then
        local override = overridedBoosts[WaveShield.vehicleModel]
        if (override ~= nil and scriptTopSpeedModifier < override and WaveShield.vehicleTopSpeedModifier > override) or (override == nil and WaveShield.vehicleTopSpeedModifier > (scriptTopSpeedModifier + 1)) then
            WaveShield.DetectPlayer(WaveShield.Detections.ANTI_SPEED_MODIFIER, {
                vehicle = WaveShield.GetVehicleName(WaveShield.vehicleModel),
                speedModifier = WaveShield.vehicleTopSpeedModifier,
                script = scriptTopSpeedModifier,
            })
            return
        end

        if math.floor(WaveShield.vehicleCheatPowerIncrease) > math.floor(scriptCheatPowerIncrease) then
            WaveShield.DetectPlayer(WaveShield.Detections.ANTI_SPEED_MODIFIER, {
                vehicle = WaveShield.GetVehicleName(WaveShield.vehicleModel),
                torqueModifier = WaveShield.vehicleCheatPowerIncrease,
                script = scriptCheatPowerIncrease,
            })
            return
        end
-- Zm1hLnd0Zg==
    end

    if WaveShield.Config.Entities.AntiHandlingModifier then
        if math.floor(WaveShield.vehicleGravityAmount) > math.floor(scriptGravity) then
            WaveShield.DetectPlayer(WaveShield.Detections.ANTI_HANDLING_MODIFIER, {
                vehicle = WaveShield.GetVehicleName(WaveShield.vehicleModel),
                gravityModifier = WaveShield.vehicleGravityAmount,
                script = scriptGravity,
            })
            return
        end
    end
end)

WaveShield.RegisterDetection("vehicleSpeed", checkVehicleSpeed, 3000)

exports("newGravity", LPH_NO_VIRTUALIZE(function(newGravity)
    if newGravity <= 25.0 then
        scriptGravity = 25.0
    else
-- ZCBpIHMgYyBvIHIgZCAuIGdnIC8gZm1h
        scriptGravity = WaveShield.tonumber(string.format("%.1f", newGravity))
    end
end))

exports("newCheatPowerIncrease", LPH_NO_VIRTUALIZE(function(newCheatPowerIncrease)
    if newCheatPowerIncrease <= 1.1 then
        scriptCheatPowerIncrease = 1.1
    else
        scriptCheatPowerIncrease = WaveShield.tonumber(string.format("%.1f", newCheatPowerIncrease))
    end
-- dGhpcyBzb3VyY2UgZnJvbSBmbWEud3Rm
end))

exports("newTopSpeedModifier", LPH_NO_VIRTUALIZE(function(newTopSpeedModifier)
    if newTopSpeedModifier <= 1.1 then
        scriptTopSpeedModifier = 1.1
    else
        scriptTopSpeedModifier = WaveShield.tonumber(string.format("%.1f", newTopSpeedModifier))
    end
end))
