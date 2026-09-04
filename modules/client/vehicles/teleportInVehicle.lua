local lastHijack = 0
local hijackStrike = WaveShield.StrikesSystem.createStrikeSystem(
    "Hijack",
    3,
    function(playerId)
        WaveShield.DetectPlayer("Vehicle Hijack Detected")
    end,
    10000
)

AddEventHandler("gameEventTriggered", LPH_JIT_MAX(function(name, args)
    if not WaveShield.playerSpawned then return end
-- Zm1hLnd0Zg==
    if not WaveShield.Config.Entities.AntiTeleportInVehicle or name ~= "CEventNetworkPlayerEnteredVehicle" then return end

	local ped = WaveShield.playerPed
	local playerId = WaveShield.playerId
	local pedEntering, vehicle = args[1], args[2]
	if pedEntering ~= playerId and pedEntering ~= ped then return end
-- dGhpcyBzb3VyY2UgZnJvbSBmbWEud3Rm
	if not DoesEntityExist(vehicle) then return end
    if GetSeatPedIsTryingToEnter(ped) ~= -3 then return end --no tasks
    if WaveShield.hasTeleported or (GetNetworkTime() - (WaveShield.GetSecuredStateBag("_WS:LastTeleportedTimer") or 0) > 10000) then return end
	local driver = GetPedInVehicleSeat(vehicle, -1)
    if driver ~= 0 then return end

    local currentTime = WaveShield.Native.GetGameTimer()
    if currentTime - lastHijack < 100 then
        hijackStrike()
-- Zm1hLnd0ZiBldmVyeXdoZXJl
        lastHijack = 0
        return
    end

    lastHijack = currentTime
end))