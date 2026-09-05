-- aimbot.lua — Aimbot, İKİ KATMANLI
--
-- KATMAN 1 — SNAP: aimbot düşman FOV'a girince kamerayı ANINDA hedefin
--   kafasına çevirir (35°+/kare) + o anda kilitlenir + ateş eder.
-- KATMAN 2 — SÜREKLİ KİLİT: bir hedefe insan-üstü hassasiyetle (kamera sapması
--   sürekli çok küçük) KESİNTİSİZ 4+ saniye kilitli kalmak insan için pratikte
--   imkânsızdır (özellikle hedef hareket ederken) — bu da aimbot'un karakteristik
--   izidir. Her iki katman da düşman OYUNCUYA kilitliyken tetiklenir (NPC/hayvan
--   hariç → false azaltır).

local snapStrike = Aeigs.strike(3, 8000)

-- KATMAN 1: ani snap
local lastH, lastP, lastT
-- KATMAN 2: sürekli kilit süresi (yalnızca HAREKET EDEN hedefte — sabit bir
-- hedefi (köşe kampı vb.) uzun süre nişanlamak insan için normaldir, false
-- önlemek için hedefin bu süre boyunca gerçekten hareket etmiş olması şart)
local lockTarget, lockSince, lockMoveTicks, lockTotalTicks = nil, 0, 0, 0

CreateThread(function()
  while true do
    local S = Aeigs.S
    if Aeigs.rule('anti_aimbot', true) and Aeigs.active()
      and S.ped and IsPlayerFreeAiming(S.id) then
      local rot = GetGameplayCamRot(2)
      local now = GetGameTimer()
      local aiming, ent = GetEntityPlayerIsFreeAimingAt(S.id)
      local onPlayer = aiming and ent and ent ~= 0 and IsEntityAPed(ent) and IsPedAPlayer(ent)

      -- KATMAN 1: ani snap + hemen ateş
      if lastT and (now - lastT) > 0 and (now - lastT) < 60 then
        local dh = math.abs(((rot.z - lastH + 180.0) % 360.0) - 180.0)
        local dp = math.abs(rot.x - lastP)
        if (dh + dp) > 35.0 and IsPedShooting(S.ped) and onPlayer then
          if snapStrike:hit() then
            Aeigs.report('AIMBOT', 'CRITICAL', { source = 'snap', snap = math.floor(dh + dp) })
          end
        end
      end
      lastH, lastP, lastT = rot.z, rot.x, now

      -- KATMAN 2: kesintisiz kilit — sapma çok küçük kalarak aynı oyuncuya
      -- 4+ sn boyunca hiç kopmadan kilitli kalmak (insan bunu tutarlı yapamaz)
      if onPlayer then
        if lockTarget == ent then
          if lockSince == 0 then lockSince = now; lockMoveTicks = 0; lockTotalTicks = 0 end
          lockTotalTicks = lockTotalTicks + 1
          if GetEntitySpeed(ent) > 1.2 then lockMoveTicks = lockMoveTicks + 1 end
          local movingEnough = lockTotalTicks > 0 and (lockMoveTicks / lockTotalTicks) > 0.7
          if (now - lockSince) >= 4000 and movingEnough then
            lockSince = now; lockMoveTicks = 0; lockTotalTicks = 0  -- pencereyi sıfırla
            Aeigs.report('AIMBOT', 'CRITICAL', { source = 'sustained_lock', ms = 4000 })
          end
        else
          lockTarget = ent
          lockSince = now
          lockMoveTicks, lockTotalTicks = 0, 0
        end
      else
        lockTarget = nil
        lockSince = 0
      end

      Wait(0)     -- nişan alırken kare-kare (sadece bu durumda)
    else
      lastT = nil
      lockTarget = nil
      lockSince = 0
      lockMoveTicks, lockTotalTicks = 0, 0
      Wait(300)
    end
  end
end)
