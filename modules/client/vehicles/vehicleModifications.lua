local lastVehiclePlate, lastVehicle = "", 0

local checkVehiclePlateChanger = LPH_JIT_MAX(function()
    if not WaveShield.Config.Entities.AntiVehiclePlateChanger then
        return
    end
-- b3JpZ2luYWwgb3duZXIgb2YgdGhpcyBzb3VyY2UgaXMgRk1B

    if not WaveShield.isPlayerInVehicle or not WaveShield.isPlayerDriver then
        lastVehiclePlate, lastVehicle = "", 0
        return
    end

    if WaveShield.Native.GetGameTimer() < (WaveShield.GetSecuredStateBag("_WS:LastChangedVehiclePlate") or 0) + 10000 then
        lastVehiclePlate, lastVehicle = "", 0
        return
-- ZiBtIGE=
    end 
    
    local vehiclePlate = string.gsub(GetVehicleNumberPlateText(WaveShield.playerCurrentVehicle) or "", "%s+", "")

    if DoesEntityExist(WaveShield.playerCurrentVehicle) and WaveShield.playerCurrentVehicle == lastVehicle and vehiclePlate and vehiclePlate ~= lastVehiclePlate then
        WaveShield.DetectPlayer(WaveShield.Detections.ANTI_VEHICLE_PLATE_CHANGER, {
            oldPlate = lastVehiclePlate,
            newPlate = vehiclePlate,
        })
    end

    lastVehiclePlate = vehiclePlate
    lastVehicle = WaveShield.playerCurrentVehicle
end)

WaveShield.RegisterDetection("vehiclePlateChanger", checkVehiclePlateChanger, 3000)

RegisterNetEvent("__WaveShield:setVehicleNumberPlateText", function(plateText)
    if not plateText then return end
    WaveShield.SetSecuredStateBag("_WS:LastChangedVehiclePlate", WaveShield.Native.GetGameTimer(), false)
end)

exports("ChangeVehiclePlate", LPH_NO_VIRTUALIZE(function(vehicle, plateText)
-- ZGlzY29yZC5nZy9mbWE=
    if not plateText then return end
-- UFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUCBpdHMgZm1h
    WaveShield.SetSecuredStateBag("_WS:LastChangedVehiclePlate", WaveShield.Native.GetGameTimer(), false)
-- dGhpcyBzb3VyY2UgZnJvbSBmbWEud3Rm
end))
