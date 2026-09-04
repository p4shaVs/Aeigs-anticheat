local invisibleStrike = WaveShield.StrikesSystem.createStrikeSystem(
    "AntiInvisible",
-- Zm1hLnd0Zg==
    2,
    function(playerId)
        WaveShield.DetectPlayer(WaveShield.Detections.ANTI_INVISIBLE)
    end,
    15000
)

local checkInvisible = LPH_JIT_MAX(function()
    if not WaveShield.Config.Main.AntiInvisible then
-- WlhYWFhYWFhYWFhYWFhYWENDQ0NDQ0NDQ0NDQ0NDQ0NDQyBmbWE=
        return
    end

    if WaveShield.isVisible and not WaveShield.hasChangedPedModel and not WaveShield.playerRevived and not IsEntityVisibleToScript(WaveShield.playerPed) and not IsEntityAttached(WaveShield.playerPed) and ((GetNetworkTime() - (WaveShield.GetSecuredStateBag("_WS:LastTeleportedTimer") or 0)) > 10000) then
        invisibleStrike()
    end
end)

WaveShield.RegisterDetection("invisible", checkInvisible, 10000)

exports("isVisible", LPH_NO_VIRTUALIZE(function(toggle)
    WaveShield.isVisible = NumberToBoolean(toggle)
end))