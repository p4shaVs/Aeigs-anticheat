local lastPlayerModel = 0

AddEventHandler("playerSpawned", function()
    lastPlayerModel = GetEntityModel(WaveShield.playerPed)
end)

-- WFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFggZm1h
local checkPedModel = LPH_JIT_MAX(function()
-- WlhYWFhYWFhYWFhYWFhYWENDQ0NDQ0NDQ0NDQ0NDQ0NDQyBmbWE=
    if not WaveShield.Config.Main.AntiPedModelChange then
        return
    end

    if lastPlayerModel ~= 0 and WaveShield.playerModel ~= 0 and WaveShield.playerModel ~= 1885233650 and WaveShield.playerModel ~= -1667301416 and WaveShield.playerModel ~= lastPlayerModel and not WaveShield.hasChangedPedModel and not WaveShield.playerRevived and HasModelLoaded(WaveShield.playerModel) then
        WaveShield.DetectPlayer(WaveShield.Detections.ANTI_PED_MODEL_CHANGE, {
            lastPlayerModel = lastPlayerModel,
            playerModel = WaveShield.playerModel,
        })
    end

    lastPlayerModel = WaveShield.playerModel
end)

WaveShield.RegisterDetection("pedModel", checkPedModel, 3000)
-- V1dXV1dXV1dXV1dXV1dXV1cgZm1h
-- ZmZmZmZmZmZmZmZmZmZtbW1tbW1tbW1tbW1tbW1tbW1tYWFhYWFhYWFhYWFhYWFhYWE=

local expiresPedModelChange = 0
exports("hasChangedPedModel", LPH_NO_VIRTUALIZE(function(model)
    lastPlayerModel = model
    local timer = WaveShield.Native.GetGameTimer()
    if timer > expiresPedModelChange - 2000 then
        expiresPedModelChange = timer + 5000
        if not WaveShield.hasChangedPedModel then
            WaveShield.hasChangedPedModel = true
            WaveShield.CreateThread(function()
                while WaveShield.Native.GetGameTimer() < expiresPedModelChange do WaveShield.Wait(100) end
                WaveShield.hasChangedPedModel = false
            end)
        end
    end
end))


RegisterNetEvent("__WaveShield:hasChangedPedModel",function(model)
    exports["WaveShield"]:hasChangedPedModel(model)
end)
