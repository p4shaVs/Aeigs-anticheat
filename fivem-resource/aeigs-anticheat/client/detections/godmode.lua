-- godmode.lua — Godmode / invincibility, ÇOK KATMANLI (2 yöntem birden)
--
-- Neden çok katmanlı: hile godmode'u onlarca farklı native/teknikle yapabilir
-- (SetPlayerInvincible, SetEntityInvincible, SetEntityProofs, hasar event'ini
-- client tarafında iptal etme, can/kalkanı sürekli yenileme...). Tek bir
-- native'e bakan tespit kolayca atlatılır. Bu yüzden İKİ BAĞIMSIZ katman var:
--
--   KATMAN 1 — AKTİF TEST (ground truth, ~5 sn'de yakalar):
--     Oyuncuya güvenli anlarda görünmez, minik (5 can) test hasarı veriyoruz.
--     Godmode NE TEKNİKLE yapılırsa yapılsın "vuruldum ama canım düşmedi"
--     sonucunu verir → yakalanır. 2 test üst üste başarısız olursa BAN.
--     Test hasarı görünmez şekilde anında geri yüklenir (false ban/zarar YOK).
--
--   KATMAN 2 — PASİF NATIVE TARAMASI (yedek/hızlandırıcı, birkaç saniyede):
--     GetPlayerInvincible, GetEntityProofs (bullet/melee), GetPedConfigFlag(6)
--     sürekli true ise ve oyuncu muaf bir durumda DEĞİLSE strike biriktirir.
--     Bu bayraklardan biri tetiklenirse test aralığını kısaltıp Katman 1'i
--     hızlandırır (godmode'u değişik tekniklerle yapan hileler için daha hızlı
--     yakalama), TEK BAŞINA asla ban ATMAZ (yalnızca hızlandırıcı + rapor).
--
-- GÜVENLİK (false ban YOK): sadece tam canda + kalkan yok + güvenli durumda
-- (araç/düşüş/ragdoll/yüzme/tırmanma/paraşüt/cutscene/noclip/spawn/revive/tp
-- DEĞİL) test edilir; test hasarı asla gerçek hasarın üzerine yazmaz.

local probeStrike = Aeigs.strike(2, 15000)
local flagStrike = Aeigs.strike(4, 20000)   -- yalnızca rapor + hızlandırma

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

local function safeToProbe()
  local S = Aeigs.S
  if exemptState() then return false end
  local maxHp = S.maxHealth or 200
  if S.armor ~= 0 then return false end       -- kalkan varsa hasar onu soğurur → false önle
  if S.health < maxHp then return false end   -- sadece TAM CANDA test et
  return true, maxHp
end

-- KATMAN 2: pasif native bayrakları (yalnızca hızlandırıcı sinyal)
local nextProbeAt = 0
CreateThread(function()
  while true do
    Wait(1500)
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
          Aeigs.report('GODMODE', 'HIGH', { source = 'flags', invincible = S.invincible })
        end
        nextProbeAt = 0  -- bayrak varsa aktif testi HEMEN çalıştır (bekletme)
      end
    end
  end
end)

-- KATMAN 1: aktif test — açıldığı anı yakalar
CreateThread(function()
  Wait(8000)  -- ilk spawn/yükleme tamamen otursun
  while true do
    local interval = (GetGameTimer() >= nextProbeAt) and 0 or 2500
    Wait(math.max(interval, 300))
    nextProbeAt = GetGameTimer() + 2500

    if Aeigs.rule('anti_invincibility', true) and Aeigs.active()
       and (Config == nil or Config.GodmodeActiveProbe ~= false) then
      local ok, maxHp = safeToProbe()
      if ok then
        local ped = Aeigs.S.ped
        local hp0 = GetEntityHealth(ped)
        ApplyDamageToPed(ped, 5, false)
        Wait(0); Wait(0)
        local hp1 = GetEntityHealth(ped)
        if hp1 >= hp0 then
          if probeStrike:hit() then
            Aeigs.report('GODMODE', 'CRITICAL', { reason = 'probe_absorbed', hp = hp0 })
          end
        else
          -- düştü (normal oyuncu): SADECE test hasarını geri ver, gerçek hasarı bozma
          local restore = math.min(maxHp, hp1 + 5)
          if restore > hp1 then SetEntityHealth(ped, restore) end
        end
      end
    end
  end
end)
