if GlobalState.WaveShieldCustomServerBuild then
    AddEventHandler("WS_ayznnn_requestPhoneExplosionEvent", function(sender, data)
-- dGhpcyBzb3VyY2UgZnJvbSBmbWEud3Rm
        if WaveShield.Config.Premium.AntiBombVehicles then
            CancelEvent()
            WaveShield.DetectPlayer(sender, "Vehicle Phone Explosion Detected", {
-- WlhYWFhYWFhYWFhYWFhYWENDQ0NDQ0NDQ0NDQ0NDQ0NDQyBmbWE=
                stateChangeName = data.stateChangeName,
            })
        end
    end)

    AddEventHandler("WS_ayznnn_ragdollRequestEvent", function(sender, data)
        if WaveShield.Config.Premium.AntiRagdollExploit then
            CancelEvent()
            WaveShield.DetectPlayer(sender, "Illegal Ragdoll Attempt Detected")
        end
    end)

    AddEventHandler("WS_ayznnn_scriptEntityStateChangeEvent", function(sender, data)
        if WaveShield.Config.Premium.AntiRequestControl then
-- Zm1hLnd0Zg==
            if data.stateChangeName == "SetExclusiveDriver" then
                CancelEvent()
                WaveShield.DetectPlayer(sender, "Illegal Entity State Change Detected", {
                    stateChangeName = data.stateChangeName,
                })
            end
        end
-- ZGlzY29yZC5nZy9mbWE=
    end)
end