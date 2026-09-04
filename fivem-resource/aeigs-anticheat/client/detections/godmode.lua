-- godmode.lua — Godmode / invincibility (SADECE RAPOR — client'ta oto-ban YOK)
-- ÖNEMLİ: Godmode client tespiti false-pozitife çok açık. Oyuncu spawn/yükleme,
-- revive, araç, cutscene, paraşüt, NoClip vb. sırasında motor tarafından geçici
-- invincible yapılır. Bu yüzden burada ASLA CRITICAL/ban atmıyoruz — yalnızca
-- SÜREKLI (uzun süre kesintisiz) invincible durumunu HIGH olarak RAPOR ederiz.
-- Gerçek/imkânsız godmode kararı ve ban sunucuda verilir (armor>100 → live.lua).
-- Böylece "sunucuya girmeden godmode ban" ve "noclip'te godmode" false'ları biter.

local function exempt()
  local S = Aeigs.S
  return S.dead or S.frozen or S.ragdoll or S.inVeh or S.cutscene
    or S.parachute > 0 or S.collisionOff              -- NoClip invincible yapar → godmode sayma
    or Aeigs.spawnGuard() or Aeigs.reviveGrace() or Aeigs.tpGrace()
    or IsPlayerCamControlDisabled(S.id)
end

CreateThread(function()
  local sustained = 0
  while true do
    Wait(2000)
    if Aeigs.rule('anti_invincibility', true) and Aeigs.active() and not exempt() then
      local S = Aeigs.S
      if S.ped and S.invincible then
        sustained = sustained + 1
        -- ~20 sn (10 örnek) kesintisiz invincible ve muaf değil → sadece RAPOR
        if sustained >= 10 then
          sustained = 0
          Aeigs.report('GODMODE', 'HIGH', { source = 'invincible', sustained = true })
        end
      else
        sustained = 0
      end
    else
      sustained = 0
    end
  end
end)
