-- godmode_probe.lua — GODMODE'u AÇILDIĞI AN yakalar (aktif test)
--
-- NEDEN: Kayıtlar godmode açıkken bile invincible=false, health=197, armor=99
--   gösterdi → okunacak bir bayrak/değer YOK. Açıldığı anı yakalamanın tek yolu
--   AKTİF TEST: oyuncuya minik (5 can) test hasarı ver, bir kare sonra bak.
--   Godmode canı düşürmez → yakalanır. Normal oyuncuda 5 can anında geri yüklenir.
--
-- GÜVENLİK (false ban / oyuncuya zarar YOK):
--   • Sadece oyuncu TAM CANDA, kalkan 0, ayakta (araçta/düşerken/ragdoll/
--     yüzerken/tırmanırken/paraşütte/cutscene/noclip/spawn/revive DEĞİL) iken test.
--   • Test hasarı bir kare sonra geri yüklenir; gerçek hasar geldiyse ÜZERİNE YAZMAZ.
--   • 2 test üst üste "can düşmedi" derse ban (tek fluke değil).

local probeStrike = Aeigs.strike(2, 15000)

local function safeToProbe()
  local S = Aeigs.S
  if not S.ped or S.dead then return false end
  if S.inVeh or S.ragdoll or S.falling or S.swimming or S.climbing
    or S.jumping or S.frozen or S.cutscene or S.collisionOff then return false end
  if S.parachute > 0 or IsPedInParachuteFreeFall(S.ped) then return false end
  if IsPlayerCamControlDisabled(S.id) then return false end
  if Aeigs.spawnGuard() or Aeigs.reviveGrace() or Aeigs.tpGrace() then return false end
  -- Sadece TAM CANDA test (godmoder hep full; normal oyuncuya zarar riski en az)
  local maxHp = S.maxHealth or 200
  if S.armor ~= 0 then return false end
  if S.health < maxHp then return false end
  return true, maxHp
end

CreateThread(function()
  Wait(8000)  -- ilk spawn/yükleme tamamen bitsin
  while true do
    Wait(2500)
    if Aeigs.rule('anti_invincibility', true) and Aeigs.active()
       and (Config == nil or Config.GodmodeActiveProbe ~= false) then
      local ok, maxHp = safeToProbe()
      if ok then
        local ped = Aeigs.S.ped
        local hp0 = GetEntityHealth(ped)
        ApplyDamageToPed(ped, 5, false)
        Wait(0); Wait(0)  -- hasarın uygulanması için birkaç kare
        local hp1 = GetEntityHealth(ped)
        if hp1 >= hp0 then
          -- can HİÇ düşmedi → godmode
          if probeStrike:hit() then
            Aeigs.report('GODMODE', 'CRITICAL', { reason = 'probe_absorbed', hp = hp0 })
          end
        else
          -- düştü (normal): SADECE bizim 5 canı geri ver, gerçek hasarı bozma
          local restore = math.min(maxHp, hp1 + 5)
          if restore > hp1 then SetEntityHealth(ped, restore) end
        end
      end
    end
  end
end)
