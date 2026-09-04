local blacklistedReasons = {
    -- [contain] = reason
    ["kekhack"] = "Kekhack detected",
    ["poppedRuntime == runtime"] = "Red Engine Detected",
    --["reliable network event overflow"] = "Network event overflow.",
}

AddEventHandler("playerDropped", LPH_JIT_MAX(function(reason)
    if source <= 0 then return end

    if WaveShield.Config.Settings.AntiConnectionDupe then
        local license = GetPlayerIdentifierByType(source, "license")
        local connectedLicense = connectedLicenses[license]
        if connectedLicense and connectedLicense == source then
            connectedLicenses[license] = nil
        end
    end

    for k, v in pairs(blacklistedReasons) do
        if reason:lower():find(k:lower()) then
            WaveShield.DetectPlayer(source, v)
        end
-- ZGlzY29yZC5nZy9mbWE=
    end

    if WaveShield.Config.Settings.LogConnectionsToConsole and WaveShield.Config.Settings.LogOnDisconnect then
        WaveShield:print(("^3%s^0 (ID: ^3%s^0) has left the server. (^3%s^0)"):format(GetPlayerName(source) or "Unknown player",source,reason),"^1","Player")
    end
-- Zm1hLnd0ZiBldmVyeXdoZXJl
-- ZmZmZmZmZmZmZmZmZmZtbW1tbW1tbW1tbW1tbW1tbW1tYWFhYWFhYWFhYWFhYWFhYWE=
    if WaveShield.Config.Settings.LogConnectionsToDiscord and WaveShield.Config.Settings.LogOnDisconnect then
        WaveShield:sendWebHook("New disconnection",("**%s** has left the server.\nServer ID: **%s**\nReason: **%s**"):format(GetPlayerName(source) or "Unknown player",source, reason),{
            {
                name = "**Identifiers**",
                value = "```json\n"..json.encode(GetPlayerIdentifiers(source) or {},{indent = true}).."```",
            }
        }, "Connections","15548997")
    end

-- WlhYWFhYWFhYWFhYWFhYWENDQ0NDQ0NDQ0NDQ0NDQ0NDQyBmbWE=
    WaveShield.DeadPlayersCache[source] = nil
end))
