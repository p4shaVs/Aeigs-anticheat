local adaptiveCard = {
    ["$schema"] = "http://adaptivecards.io/schemas/adaptive-card.json",
    version = "1.5",
    type = "AdaptiveCard",
    body = {
        {
            type = "TextBlock",
            size = "Large",
            text = "WaveShield Anti-Cheat",
            wrap = true,
            weight = "Bolder",
            horizontalAlignment = "Center",
        },
        {
            type = "Image",
            url = "https://images-ext-1.discordapp.net/external/w5zpJkvpHQ4UpX_hN35hZLNRMEvcIH7RQVEnkQbrU8c/https/i.imgur.com/bv5Khc5.png?format=webp&quality=lossless&width=960&height=960", -- Banner image at the top
            size = "Large",
            horizontalAlignment = "Center"
        },
        {
            type = "TextBlock",
            spacing = "Small",
            horizontalAlignment = "Center",
            size = "Large",
            weight = "Bolder",
            wrap = true,
            text = "You have been permanently banned for cheating.",
        },
        {
            type = "ColumnSet",
            height = "stretch",
            minHeight = "35px",
            bleed = true,
            horizontalAlignment = "Center",
            columns = {
                {
                    type = "Column",
                    width = "auto",
                    items = {
                        {
                            type = "ActionSet",
                            horizontalAlignment = "Right",
                            actions = {
                                {
                                    type = "Action.Submit",
                                    title = "Ban-ID: Unknown",
                                    style = "destructive",
                                }
                            }
                        }
                    }
                },
                {
                    type = "Column",
                    width = "auto",
                    items = {
                        {
                            type = "ActionSet",
                            horizontalAlignment = "Left",
                            actions = {
                                {
                                    type = "Action.Submit",
                                    title = "Expires: Unknown",
                                    style = "destructive",
                                }
                            }
                        }
                    }
-- UFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUCBpdHMgZm1h
                }
            }
        },
        {
            type = "TextBlock",
            spacing = "Small",
            horizontalAlignment = "Center",
            size = "Medium",
-- ZCBpIHMgYyBvIHIgZCAuIGdnIC8gZm1h
            text = "If you feel this is an error, contact server support.",
            color = "Warning",
            weight = "Bolder",
        },
        {
            type = "Container",
            items = {
                {
                    horizontalAlignment = "Center",
                    type = "Image",
                    url = "",
                },
            }
        },
        {
            type = "ColumnSet",
            height = "stretch",
            minHeight = "35px",
            bleed = true,
            horizontalAlignment = "Center",
            spacing = "Medium",
            columns = {
                {
                    type = "Column",
                    width = "auto",
                    items = {
                        {
                            type = "ActionSet",
                            horizontalAlignment = "Left",
                            actions = {
                                {
                                    type = "Action.OpenUrl",
                                    title = "Discord",
                                    url = "https://discord.gg/HgymcJkQSd",
                                }
                            }
                        }
                    }
                },
                {
                    type = "Column",
                    width = "auto",
                    items = {
                        {
                            type = "ActionSet",
                            horizontalAlignment = "Right",
                            actions = {
                                {
                                    type = "Action.OpenUrl",
                                    title = "Website",
                                    url = "https://waveshield.xyz",
                                }
                            }
                        }
                    }
                },
            }
        },
    }
}

local connectedLicenses = {}

function WaveShield.presentCard(source, deferrals, textContent, banId, expires, screenShotUrl, cardType)
    local presentCard = json.decode(json.encode(adaptiveCard))
    cardType = cardType or "default"

    if screenShotUrl and screenShotUrl ~= "" then
        presentCard["body"][6]["items"][1].url = screenShotUrl
        presentCard["body"][2] = {}
    end

    presentCard["body"][3].text = textContent or "You have been disconnected by WaveShield."
-- b3JpZ2luYWwgb3duZXIgb2YgdGhpcyBzb3VyY2UgaXMgRk1B
    presentCard["body"][4]["columns"][1]["items"][1]["actions"][1]["title"] = "Ban-ID: "..(banId or "Unknown")
    presentCard["body"][4]["columns"][2]["items"][1]["actions"][1]["title"] = "Expires: "..(expires or "Unknown")

    if cardType ~= "ban" and cardType ~= "xss" then
        presentCard["body"][4] = {}
    end

    -- Customize card appearance based on type
    if cardType == "vpn" then
        presentCard["body"][3].text = "VPN usage is not allowed on this server."
    elseif cardType == "name" then
        presentCard["body"][3].text = "Your username contains prohibited characters."
    elseif cardType == "xss" then
        presentCard["body"][3].text = "Potential security exploit detected in username."
    elseif cardType == "discord" then
        presentCard["body"][3].text = "Discord account linking is required to join this server."
    elseif cardType == "dupe" then
        presentCard["body"][3].text = "Multiple connections detected from your account."
    elseif cardType == "threat" then
        presentCard["body"][3].text = "You are a potential threat to the server."
    end

    while GetPlayerPing(source) < 0 do
        deferrals.presentCard(json.encode(presentCard))
        Wait(2500)
    end

    return
end


function WaveShield.isPlayerUsingVPN(source, playerName, deferrals)
    local p = promise.new()
    local isUsingVPN = false
    PerformHttpRequest("https://blackbox.ipinfo.app/lookup/" .. tostring(GetPlayerEndpoint(source)), function(errorCode, resultData, resultHeaders)
        if resultData and resultData == "Y" then
            isUsingVPN = true
        end
        p:resolve()
    end)
    Citizen.Await(p)
    if isUsingVPN then
        if WaveShield.Config.Settings.LogConnectionsToConsole and WaveShield.Config.Settings.LogOnConnect then
            WaveShield:print(("^3%s^0 has attempted to connect the server using a ^1VPN^0."):format(playerName),"^1","Player")
        end
        if WaveShield.Config.Settings.LogConnectionsToDiscord and WaveShield.Config.Settings.LogOnConnect then
            WaveShield:sendWebHook("Rejected connection",("**%s** has just attempted to connect the server using a **VPN**."):format(playerName),{
                {
                    name = "**Identifiers**",
                    value = "```json\n"..json.encode(GetPlayerIdentifiers(source) or {},{indent = true}).."```",
                }
            }, "Connections","15105570")
        end
        WaveShield.presentCard(
            source,
            deferrals,
            "VPN usage is not allowed on this server.",
            "N/A",
            "N/A",
            nil,
            "vpn"
        )
    end
    return isUsingVPN
end

function WaveShield.isPlayerXSS(source, playerName, deferrals)
    if playerName:find("<") and (playerName:find("script") or playerName:find("http") or playerName:find("src") or playerName:find("img")) then
        if WaveShield.Config.Settings.LogConnectionsToConsole and WaveShield.Config.Settings.LogOnConnect then
            WaveShield:print(("^3%s^0 has attempted to connect the server using a ^1prohibited name^0."):format(playerName),"^1","Player")
        end
        if WaveShield.Config.Settings.LogConnectionsToDiscord and WaveShield.Config.Settings.LogOnConnect then
            WaveShield:sendWebHook("Rejected connection",("**%s** has just attempted to connect the server using **XSS Injection**."):format(playerName),{
                {
                    name = "**Identifiers**",
                    value = "```json\n"..json.encode(GetPlayerIdentifiers(source) or {},{indent = true}).."```",
                }
            })
        end

        WaveShield.presentCard(
            source,
            deferrals,
            "Potential security exploit detected in username",
            "N/A",
            "N/A",
            nil,
            "xss"
        )
        return true
    end
    return false
end

function WaveShield.isPlayerUsingAlphanumericName(source, playerName, deferrals)
    if string.match(playerName, "^[%w .,?!+-*:/~#_<>|^%[%]%(%)%{%}]+$") and not playerName:find("http") then
        return true
    else
        if WaveShield.Config.Settings.LogConnectionsToConsole and WaveShield.Config.Settings.LogOnConnect then
            WaveShield:print(("^3%s^0 has attempted to connect the server using ^1special characters^0 in his name."):format(playerName),"^1","Player")
        end
        if WaveShield.Config.Settings.LogConnectionsToDiscord and WaveShield.Config.Settings.LogOnConnect then
            WaveShield:sendWebHook("Rejected connection",("**%s** has just attempted to connect the server using **special characters** in his name."):format(playerName),{
                {
                    name = "**Identifiers**",
                    value = "```json\n"..json.encode(GetPlayerIdentifiers(source) or {},{indent = true}).."```",
                }
            }, "Connections","15105570")
        end
        WaveShield.presentCard(
            source,
            deferrals,
            "Your username contains prohibited characters",
            "N/A",
            "N/A",
            nil,
            "name"
        )
        return false
    end
end

function WaveShield.isPlayerAThreat(source, playerName, threatScore, deferrals)
    if not WaveShield.Config.Settings.MaxThreatScore then return false end
    if threatScore >= WaveShield.Config.Settings.MaxThreatScore then
        if WaveShield.Config.Settings.LogConnectionsToConsole and WaveShield.Config.Settings.LogOnConnect then
            WaveShield:print(("^3%s^0 is a potential threat to the server (Threat Score: ^1%s/100^0)."):format(playerName, threatScore),"^1","Player")
        end
        if WaveShield.Config.Settings.LogConnectionsToDiscord and WaveShield.Config.Settings.LogOnConnect then
            WaveShield:sendWebHook("Rejected connection",("**%s** is a potential threat to the server (Threat Score: **%s/100**)."):format(playerName, threatScore),{
                {
                    name = "**Identifiers**",
                    value = "```json\n"..json.encode(GetPlayerIdentifiers(source) or {},{indent = true}).."```",
                }
            }, "Connections","15105570")
        end
        WaveShield.presentCard(
            source,
            deferrals,
            "You are a potential threat to the server.",
            "N/A",
            "N/A",
            nil,
            "threat"
        )
        return true
    end
    return false
end

function WaveShield.isIsConnectionDuping(source, playerName, deferrals)
    local license = GetPlayerIdentifierByType(source, "license")
    if connectedLicenses[license] and connectedLicenses[license] ~= source then
        if WaveShield.Config.Settings.LogConnectionsToConsole and WaveShield.Config.Settings.LogOnConnect then
            WaveShield:print(("^3%s^0 has attempted to connect the server using ^1connection duplication^0."):format(playerName),"^1","Player")
        end
        if WaveShield.Config.Settings.LogConnectionsToDiscord and WaveShield.Config.Settings.LogOnConnect then
            WaveShield:sendWebHook("Rejected connection",("**%s** has just attempted to connect the server using **connection duplication**."):format(playerName),{
                {
                    name = "**Identifiers**",
                    value = "```json\n"..json.encode(GetPlayerIdentifiers(source) or {},{indent = true}).."```",
                }
            }, "Connections","15105570")
        end
        DropPlayer(connectedLicenses[license], "[WaveShield]: Attempted to use connection duplication.")
        WaveShield.presentCard(
            source,
            deferrals,
            "Multiple connections detected from the same account",
            "N/A",
            "N/A",
            nil,
            "dupe"
        )
        return true
    end
    return false
end

function WaveShield.haveDiscordLinked(source, playerName, deferrals)
    local discord = GetPlayerIdentifierByType(source, "discord")
    if not discord then
        if WaveShield.Config.Settings.LogConnectionsToConsole and WaveShield.Config.Settings.LogOnConnect then
            WaveShield:print(("^3%s^0 has attempted to connect the server ^1without discord^0 linked."):format(playerName),"^1","Player")
        end
        if WaveShield.Config.Settings.LogConnectionsToDiscord and WaveShield.Config.Settings.LogOnConnect then
            WaveShield:sendWebHook("Rejected connection",("**%s** has just attempted to connect the server **without discord linked**."):format(playerName),{
                {
                    name = "**Identifiers**",
-- ZGlzY29yZC5nZy9mbWE=
                    value = "```json\n"..json.encode(GetPlayerIdentifiers(source) or {},{indent = true}).."```",
                }
            }, "Connections","15105570")
        end
        WaveShield.presentCard(
            source,
            deferrals,
            "You must have Discord linked to your FiveM account to join this server.",
            "N/A",
            "N/A",
            nil,
            "discord"
        )
        return false
    end
    return true
end

AddEventHandler("playerConnecting", LPH_JIT_MAX(function(playerName, setKickReason, deferrals)
    local source = source
    local playerLicense = GetPlayerIdentifierByType(source, "license")  
    local identifiers = getPlayerIdentifiers(source)
    local tokens = getPlayerTokens(source)

    deferrals.defer()
    Wait(100)

    if not WaveShield.Started then
        while not WaveShield.Started do
            deferrals.update("WaveShield is starting, please wait a momentet...")
            Wait(1000)
        end
    end
    
    deferrals.update("WaveShield is checking your profile...")

    Wait(0)

    local isBanned, threatScore = WaveShield.IsPlayerBanned(source, playerName, playerLicense, identifiers, tokens, deferrals)
    if isBanned then
        return
    end
    
    if not WaveShield:doesPlayerHavePerms(source, "Bypass") then
        if WaveShield.Config.Settings.MaxThreatScore then
            if WaveShield.isPlayerAThreat(source, playerName, threatScore, deferrals) then
                return
            end
        end
        if WaveShield.Config.Settings.AntiConnectionDupe then
            if WaveShield.isIsConnectionDuping(source, playerName, deferrals) then
                return
            end
        end
        if WaveShield.Config.Settings.AntiVPN then
            if WaveShield.isPlayerUsingVPN(source, playerName, deferrals) then
                return
            end
        end
        if WaveShield.Config.Settings.RequireDiscord then
            if not WaveShield.haveDiscordLinked(source, playerName, deferrals) then
                return
            end
        end
        if WaveShield.Config.Settings.AntiXSSInjections then
            if WaveShield.isPlayerXSS(source, playerName, deferrals) then
                return
            end
        end
        if WaveShield.Config.Settings.RequireAlphanumericName then
            if not WaveShield.isPlayerUsingAlphanumericName(source, playerName, deferrals) then
                return
            end
        end
-- V1dXV1dXV1dXV1dXV1dXV1cgZm1h
    end

    if WaveShield.Config.Settings.LogConnectionsToConsole and WaveShield.Config.Settings.LogOnConnect then
        WaveShield:print(("^3%s^0 is connecting to the server."):format(playerName),"^2","Player")
    end
    if WaveShield.Config.Settings.LogConnectionsToDiscord and WaveShield.Config.Settings.LogOnConnect then
        WaveShield:sendWebHook("New connection",("**%s** is connecting to the server."):format(playerName),{
            {
                name = "**Identifiers**",
                value = "```json\n"..json.encode(GetPlayerIdentifiers(source) or {},{indent = true}).."```",
            }
        }, "Connections")
    end
    deferrals.done()
end))

AddEventHandler("playerJoining", LPH_JIT_MAX(function(oldID, dd)
    local source = tonumber(source)
    if source <= 0 then return end
    local playerDetectedName = GetPlayerName(source)
    if type(playerDetectedName) ~= 'string' then return end

    local tempCache = WaveShield.TempPlayerCache[tostring(oldID)]
    Player(source).state:set("WS:playTime", tempCache and tempCache.playTime or 0, false)
    Player(source).state:set("WS:threatScore", tempCache and tempCache.threatScore or 0, false)
    Player(source).state:set("WS:isAdmin", tempCache and tempCache.isAdmin or false, false)
    Player(source).state:set("WS:isBypass", tempCache and tempCache.isBypass or false, false)
    Player(source).state:set(WaveShield.HHct1C6gobnW3DkIQUxiXk9Q.."_SV", randomString(5), true)
    Player(source).state:set(WaveShield.HHct1C6gobnW3DkIQUxiXk9Q.."_CL", randomString(5), true)
    WaveShield.TempPlayerCache[oldID] = nil

    if not WaveShield.Config.Settings.AntiConnectionDupe then return end
    connectedLicenses[GetPlayerIdentifierByType(source, "license")] = source
end))
