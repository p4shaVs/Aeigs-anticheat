function IsVehicleOccupiedByAPlayer(vehicle)
    for seat = -1, 6 do
        local ped = GetPedInVehicleSeat(vehicle, seat)
        if ped ~= 0 and IsPedAPlayer(ped) then
            return true
        end
    end
    return false
end

RegisterCommand(WaveShield.Config.Settings.CommandPrefix, function(source, args, raw)
    if source == 0 and not args[1] then
        WaveShield:drawLogo()
        WaveShield:print("Available commands:","^6","System")
        print("")
        WaveShield:print("^3"..WaveShield.Config.Settings.CommandPrefix.." install^0 - (install WaveShield in missing resources)","^6","System")
        WaveShield:print("^3"..WaveShield.Config.Settings.CommandPrefix.." uninstall^0 - (uninstall WaveShield in all of your resources)","^6","System")
        WaveShield:print("^3"..WaveShield.Config.Settings.CommandPrefix.." ban <id> <reason>^0 - (ban specified player)","^6","System")
        WaveShield:print("^3"..WaveShield.Config.Settings.CommandPrefix.." baninfo <banId>^0 - (shows specified banId infos)","^6","System")
        WaveShield:print("^3"..WaveShield.Config.Settings.CommandPrefix.." unban <banId>^0 - (unban specified player)","^6","System")
        WaveShield:print("^3"..WaveShield.Config.Settings.CommandPrefix.." unban all^0 - (unban all banned players)","^6","System")
        WaveShield:print("^3"..WaveShield.Config.Settings.CommandPrefix.." reload^0 - (reload the config from the panel)","^6","System")
        WaveShield:print("^3"..WaveShield.Config.Settings.CommandPrefix.." clear <peds/vehicles/objects/all>^0 - (delete all non-needed specified entities on the server)","^6","System")
        print("")
    end

    if args[1] == "install" then
        if source == 0 then
            WaveShield:print("Installing WaveShield in all your resources, please do not stop the server.","^6","System")
            WaveShield:checkInstallation()
        end
    elseif args[1] == "uninstall" then
        if source == 0 then
            WaveShield:print("Uninstalling WaveShield in all your resources, please do not stop the server.","^6","System")
            local uninstalled, nbResourcesUninstalled = WaveShield:uninstallResources()
            WaveShield:print("Successfully uninstalled WaveShield in ^3"..nbResourcesUninstalled.."^0 resources.","^2","System")
        end
    elseif args[1] == "ban" then
        if args[2] == nil or args[2] == nil or args[3] == nil then
            WaveShield:print("Invalid usage of the command: ^3"..WaveShield.Config.Settings.CommandPrefix.." ban <serverId> <reason>^0.","^2","System")
            return
        end
        if WaveShield.Config.Settings.EnableGameplayRecord then
            WaveShield:print("Banning in progress, ^3uploading^0 gameplay capture...","^2","System")
        end
        if source == 0 or source == "0" then
            WaveShield.DetectPlayer(args[2], args[3], nil, nil, nil,"Console")
        elseif WaveShield:doesPlayerHavePerms(source, "Commands", true) then
            WaveShield.DetectPlayer(args[2], args[3], nil, nil, nil, GetPlayerName(source))
        end
    elseif args[1] == "unban" then

        if args[2] == nil then
            WaveShield:print("Invalid usage of the command: ^3"..WaveShield.Config.Settings.CommandPrefix.." unban <banId> <reason>^0.","^2","System")
            return
        end
        if source == 0 then
            if type(args[2]) == "string" and args[2] == "all" then
                WaveShield.UnbanAllPlayers()
            else
                WaveShield:unban(args[2])
            end
        elseif WaveShield:doesPlayerHavePerms(source, "Commands", true) then
            WaveShield:unban(args[2], GetPlayerName(source) or "Unknown Name")
        end
    elseif args[1] == "reload" then
-- ZGlzY29yZC5nZy9mbWE=
        if source == 0 then
            WaveShield:ReloadConfiguration()
        end
    elseif args[1] == "clear" then
        if not args[2] then
            WaveShield:print("Invalid usage of the command: ^3"..WaveShield.Config.Settings.CommandPrefix.." clear <peds/vehicles/objects/all>^0.","^2","System")
            return
        end
        if args[2] == "peds" then
            if source == 0 or WaveShield:doesPlayerHavePerms(source, "Commands") then
                local allPeds = GetAllPeds()
                for _,v in pairs(allPeds) do
                    if DoesEntityExist(v) then
                        DeleteEntity(v)
                    end
                end
                WaveShield:print("Successfully deleted ^3"..#allPeds.."^0 peds.","^2","World")
            end
        elseif args[2] == "vehicles" then
            if source == 0 or WaveShield:doesPlayerHavePerms(source, "Commands") then
                local allVehicles = GetAllVehicles()
                for _,v in pairs(allVehicles) do
                    if DoesEntityExist(v) and not IsVehicleOccupiedByAPlayer(v) then
                        DeleteEntity(v)
                    end
                end
                WaveShield:print("Successfully deleted ^3"..#allVehicles.."^0 vehicles.","^2","World")
            end
        elseif args[2] == "objects" then
            if source == 0 or WaveShield:doesPlayerHavePerms(source, "Commands") then
                local allObjs = GetAllObjects()
                for _,v in pairs(allObjs) do
                    if DoesEntityExist(v) then
                        DeleteEntity(v)
                    end
                end
                WaveShield:print("Successfully deleted ^3"..#allObjs.."^0 objects.","^2","World")
            end
        elseif args[2] == "all" then
            if source == 0 or WaveShield:doesPlayerHavePerms(source, "Commands") then
                local allPeds = GetAllPeds()
                for _,v in pairs(allPeds) do
                    if DoesEntityExist(v) then
                        DeleteEntity(v)
                    end
                end
                local allVehicles = GetAllVehicles()
                for _,v in pairs(allVehicles) do
                    if DoesEntityExist(v) and not IsVehicleOccupiedByAPlayer(v) then
                        DeleteEntity(v)
                    end
                end
                local allObjs = GetAllObjects()
                for _,v in pairs(allObjs) do
                    if DoesEntityExist(v) then
                        DeleteEntity(v)
                    end
                end
                WaveShield:print("Successfully deleted ^3"..#allPeds.."/"..#allVehicles.."/"..#allObjs.."^0 peds/vehicles/objects.","^2","World")
            end
-- ZmZmZmZmZmZmZmZmZmZtbW1tbW1tbW1tbW1tbW1tbW1tYWFhYWFhYWFhYWFhYWFhYWE=
        end
    elseif args[1] == "debug" then
        local serverId = tonumber(args[2])
        if not serverId then
-- V1dXV1dXV1dXV1dXV1dXV1dXV1dXV1dXV1dXV1dXV1dXV1dXV1dXVyBmbWEud3Rm
            WaveShield:print("Invalid usage of the command: ^3"..WaveShield.Config.Settings.CommandPrefix.." debug <serverId>^0.","^2","System")
            return
        end

        local debugEventName = WaveShield.EncryptString("__WaveShield:debug", WaveShield.Substitution)
        local debugEventName2 = WaveShield.EncryptString("__WaveShield:debug_executions", WaveShield.Substitution)

        TriggerClientEvent(debugEventName, serverId)
        TriggerClientEvent(debugEventName2, serverId)
    end
end)