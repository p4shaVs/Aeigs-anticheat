-- godmode.lua — Godmode / invincibility (native bayrak taraması)
--
-- GEÇMİŞ HATA (kayda geçsin): Daha önce burada "aktif test" katmanı vardı —
-- oyuncuya görünmez 5 canlık test hasarı verip can düşmüyorsa godmode
-- sayıyordu. Bu KALDIRILDI çünkü GERÇEK FALSE BAN'A SEBEP OLDU: FiveM
-- sunucularının neredeyse tamamında (ESX/QBCore/ox_core fark etmez) başka
-- resource'lar (hunger/thirst, statusbar, hp senkron döngüleri) oyuncunun
-- canını kendi tuttuğu değere her tick geri yazar. Testimiz 1-2 kare içinde
-- can düştü mü diye bakıyordu; o anda başka bir script canı eski değere geri
-- yazarsa HİÇ HİLE YOKKEN "can düşmedi" görünüp 2 test sonra ban atıyordu.
-- Bu tek sunucuya özel bir edge-case değil, HER FiveM sunucusunda er ya da
-- geç gerçek oyuncuları vuracak bir tasarım hatasıydı — bu yüzden tamamen
-- çıkarıldı. Godmode artık SADECE aşağıdaki iki güvenli yöntemle yakalanır:
--
--   1) Bu dosya — native bayrak taraması: GetPlayerInvincible / GetEntityProofs
--      (bullet/melee) / GetPedConfigFlag(6) UZUN SÜRE (25 sn, 6 doğrulama)
--      kesintisiz true ise ve oyuncu muaf değilse → ban. Uzun pencere, tek
--      karelik/geçici bir motor durumunun (ör. spawn sırasında GTA'nın kendi
--      kısa invincible flicker'ı) yanlışlıkla ban atmasını engeller.
--   2) server/godmode_guard.lua — sunucu tarafı hasar-emilimi: gerçek bir
--      PvP çatışmasında "vuruldu ama canı düşmedi" (server-authoritative,
--      client script'lerin senkron döngüleri buraya KARIŞAMAZ, çünkü sunucu
--      GetEntityHealth'i doğrudan kendisi okur). Değişik tekniklerle yapılan
--      (bayrak set etmeyen) godmode hileleri PvP sırasında bu katmanla yakalanır.

local flagStrike = Aeigs.strike(6, 25000)

local function exemptState()
  local S = Aeigs.S
  if not S.ped or S.dead then return true end
  if S.inVeh or S.ragdoll or S.falling or S.swimming or S.climbing
    or S.jumping or S.frozen or S.cutscene or S.collisionOff then return true end
  if S.parachute > 0 or IsPedInParachuteFreeFall(S.ped) then return true end
  if IsPlayerCamControlDisabled(S.id) then return true end
  if Aeigs.spawnGuard() or Aeigs.reviveGrace() or Aeigs.tpGrace() then return true end
  return false
end

CreateThread(function()
  while true do
    Wait(2000)
    if Aeigs.rule('anti_invincibility', true) and Aeigs.active() and not exemptState() then
      local S = Aeigs.S
      local flagged = false
      if S.invincible then flagged = true end
      local ok1, bulletProof, _, _, _, meleeProof = pcall(GetEntityProofs, S.ped)
      if ok1 and (bulletProof or meleeProof) then flagged = true end
      local ok2, cfg6 = pcall(GetPedConfigFlag, S.ped, 6, true)
      if ok2 and cfg6 then flagged = true end

      if flagged then
        if flagStrike:hit() then
          Aeigs.report('GODMODE', 'CRITICAL', { source = 'flags', invincible = S.invincible })
        end
      else
        flagStrike:resetStrike()
      end
    end
  end
end)
