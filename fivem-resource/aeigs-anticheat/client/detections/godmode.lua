-- godmode.lua — Godmode / invincibility, client tarafı bayrak taraması
-- ARTIK SADECE RAPOR (ban ATMAZ) — bkz. aşağıdaki iki geçmiş hata.
--
-- GEÇMİŞ HATA #1: Aktif self-damage testi vardı — KALDIRILDI, çünkü başka
-- resource'ların (hunger/thirst, statusbar) can senkron döngüleri testi
-- her seferinde geçersiz kılıp hiç hile yokken ban atıyordu.
--
-- GEÇMİŞ HATA #2 (BUNU BULDURAN sorun): GetPlayerInvincible + GetPedConfigFlag(6)
-- bayrak taraması "uzun süre kesintisiz true" olursa TEK BAŞINA ban atıyordu.
-- Ama ESX/QBCore gibi framework'ler spawn/karakter yüklenirken oyuncuyu
-- KENDİLERİ invincible yapıyor ve bu koruma bizim 10 sn'lik muafiyetimizden
-- DAHA UZUN sürebiliyor (15-30 sn yaygın) — bu da "her girişte godmode banı"
-- olarak ortaya çıktı. GetPedConfigFlag(6)'nın da her oyuncuda normalde
-- true olabileceği doğrulanamadı (riskli/dokümante edilmemiş native).
--
-- SONUÇ: Client tarafında hiçbir bayrak/flag TEK BAŞINA artık ban atamaz.
-- Godmode'un GERÇEK ve TEK ban-atabilen yöntemi artık server/godmode_guard.lua
-- — biri GERÇEKTEN vurulup canı hiç düşmüyorsa (server'ın kendi okuduğu
-- GetEntityHealth ile) banlar. Bu, spawn/framework durumlarından TAMAMEN
-- bağımsızdır çünkü gerçek bir vuruş (weaponDamageEvent) gerektirir — kimse
-- sana ateş etmeden asla tetiklenmez.
--
-- Bu dosya sadece HIGH önemde rapor bırakır (panelde görünür, ban yok);
-- ban kararını tamamen server/godmode_guard.lua verir.

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

      if flagged then
        if flagStrike:hit() then
          -- SADECE RAPOR — ban atmaz. Panelde görünür, incelemek isteyen
          -- yönetici manuel aksiyon alabilir (Aksiyonlar sayfasından BAN'a
          -- çevirmek istersen kendi riskindir, framework'ünü tanıyorsundur).
          Aeigs.report('GODMODE', 'HIGH', { source = 'flags', invincible = S.invincible })
        end
      else
        flagStrike:resetStrike()
      end
    end
  end
end)
