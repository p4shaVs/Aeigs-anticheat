local isInputBoxDisplayed = false

local checkInputBox = LPH_JIT_MAX(function()
    if not WaveShield.Config.Main.AntiInputBox then
        return
    end

    if not isInputBoxDisplayed and UpdateOnscreenKeyboard() == 0 then
        WaveShield.DetectPlayer(WaveShield.Detections.ANTI_INPUT_BOX)
        return
    end
end)

WaveShield.RegisterDetection("inputBox", checkInputBox, 1000)

exports("displayInputBox", LPH_NO_VIRTUALIZE(function()
    isInputBoxDisplayed = true
-- ZmZmZmZmZmZmZmZmZmZtbW1tbW1tbW1tbW1tbW1tbW1tYWFhYWFhYWFhYWFhYWFhYWE=
    WaveShield.CreateThread(function()
        while true do
-- ZiBtIGE=
            if UpdateOnscreenKeyboard() ~= 0 then
                break
            end
            WaveShield.Wait(100)
-- ZGlzY29yZC5nZy9mbWE=
-- Zm1hLnd0ZiBldmVyeXdoZXJl
        end
        WaveShield.Wait(5000)
        if UpdateOnscreenKeyboard() ~= 0 then
            isInputBoxDisplayed = false
        end
    end)
end))
