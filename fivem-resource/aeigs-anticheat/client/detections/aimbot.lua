-- aimbot.lua — Aimbot, ÜÇ KATMANLI
--
-- KATMAN 1 — SNAP: aimbot düşman FOV'a girince kamerayı ANINDA hedefin
--   kafasına çevirir (35°+/kare) + o anda kilitlenir + ateş eder. Yalnızca
--   SMOOTHING KAPALI (anlık) hile ayarlarını yakalar.
-- KATMAN 2 — SÜREKLİ KİLİT: bir hedefe insan-üstü hassasiyetle (kamera sapması
--   sürekli çok küçük) KESİNTİSİZ 4+ saniye kilitli kalmak insan için pratikte
--   imkânsızdır (özellikle hedef hareket ederken) — bu da aimbot'un karakteristik
--   izidir. CRITICAL/BAN.
-- KATMAN 3 — İZLEME HASSASİYETİ (yumuşatma/smoothing açık hileler için): bazı
--   hilelerde xsmooth/ysmooth ayarı kamerayı ANINDA değil KADEMELİ çevirir —
--   bu, Katman 1'in "ani snap" eşiğini es geçer. Ama yumuşatılmış bir aimbot
--   bile hedefe kilitlendiğinde nişan-hata açısı hem ÇOK KÜÇÜK hem de ÇOK
--   TUTARLI (düşük varyans) kalır — insan eli hep ufak, DÜZENSİZ düzeltmeler
--   yapar. Daha KISA pencerede (2.5 sn) çalışır ama istatistiksel bir sinyal
--   olduğundan daha YUMUŞAK bir tip olarak raporlanır (LOG varsayılan, sadece
--   tehdit skoruna düşük ağırlıkla eklenir) — tek başına asla ban atmaz.
--
-- NOT (dürüstlük): Bu üç katman + sunucudaki SILENT_AIM/WALLBANG kontrolleri
-- birlikte GÜÇLÜ bir savunma hattı oluşturur, ama HİÇBİR anti-cheat (bizimki
-- dahil, EAC/BattlEye/Vanguard dahil) "her hileden kesin" koruma garantisi
-- veremez — bu, tespit ile atlatma arasındaki sürekli yarışın (arms race)
-- doğası gereğidir. Amaç: bağımsız birden çok katmanı AYNI ANDA atlatmayı
-- pratikte çok zorlaştırmak, tek katmana güvenmemek.

local snapStrike = Aeigs.strike(3, 8000)
local precisionStrike = Aeigs.strike(2, 30000)

-- KATMAN 1: ani snap
local lastH, lastP, lastT
-- KATMAN 2/3: sürekli kilit süresi (yalnızca HAREKET EDEN hedefte — sabit bir
-- hedefi (köşe kampı vb.) uzun süre nişanlamak insan için normaldir, false
-- önlemek için hedefin bu süre boyunca gerçekten hareket etmiş olması şart)
local lockTarget, lockSince, lockMoveTicks, lockTotalTicks = nil, 0, 0, 0
-- KATMAN 3: nişan-hata açısı örnekleri (derece), ~100ms'de bir örneklenir
local errSamples, lastErrSample, precisionSince = {}, 0, 0

local function camForward()
  local r = GetGameplayCamRot(2)
  local zr, xr = math.rad(r.z), math.rad(r.x)
  local num = math.abs(math.cos(xr))
  return vector3(-math.sin(zr) * num, math.cos(zr) * num, math.sin(xr))
end

local function angleErrorDeg(camPos, fwd, targetPos)
  local dir = targetPos - camPos
  local dist = #dir
  if dist < 0.5 then return nil end
  dir = dir / dist
  local dot = fwd.x * dir.x + fwd.y * dir.y + fwd.z * dir.z
  dot = math.max(-1.0, math.min(1.0, dot))
  return math.deg(math.acos(dot))
end

local function evaluatePrecision(now)
  if #errSamples < 12 then return end
  local sum = 0
  for _, v in ipairs(errSamples) do sum = sum + v end
  local mean = sum / #errSamples
  local varsum = 0
  for _, v in ipairs(errSamples) do varsum = varsum + (v - mean) * (v - mean) end
  local stddev = math.sqrt(varsum / #errSamples)
  -- İnsan eli bu kadar küçük VE bu kadar tutarlı bir açısal hatayı sürekli
  -- koruyamaz (özellikle hedef hareket ederken) — smoothing'li aimbot izi.
  if mean <= 1.6 and stddev <= 0.8 and (now - precisionSince) >= 2500 then
    if precisionStrike:hit() then
      Aeigs.report('AIM_PRECISION_SUSPECTED', 'MEDIUM', {
        source = 'precision', mean = math.floor(mean * 100) / 100, stddev = math.floor(stddev * 100) / 100,
      }, 20000)
    end
    errSamples = {}
    precisionSince = now
  end
end

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

      -- KATMAN 2/3: kesintisiz kilit — sapma çok küçük kalarak aynı oyuncuya
      -- kopmadan kilitli kalmak (insan bunu tutarlı yapamaz)
      if onPlayer then
        if lockTarget == ent then
          if lockSince == 0 then lockSince = now; lockMoveTicks = 0; lockTotalTicks = 0; errSamples = {}; precisionSince = now end
          lockTotalTicks = lockTotalTicks + 1
          if GetEntitySpeed(ent) > 1.2 then lockMoveTicks = lockMoveTicks + 1 end
          local movingEnough = lockTotalTicks > 0 and (lockMoveTicks / lockTotalTicks) > 0.7

          -- KATMAN 3 örnekleme (~100ms'de bir, sadece hedef hareket ederken)
          if movingEnough and (now - lastErrSample) >= 100 then
            lastErrSample = now
            local err = angleErrorDeg(GetGameplayCamCoord(), camForward(), GetEntityCoords(ent) + vector3(0, 0, 0.6))
            if err then
              errSamples[#errSamples + 1] = err
              if #errSamples > 25 then table.remove(errSamples, 1) end
              evaluatePrecision(now)
            end
          end

          if (now - lockSince) >= 4000 and movingEnough then
            lockSince = now; lockMoveTicks = 0; lockTotalTicks = 0  -- pencereyi sıfırla
            Aeigs.report('AIMBOT', 'CRITICAL', { source = 'sustained_lock', ms = 4000 })
          end
        else
          lockTarget = ent
          lockSince = now
          lockMoveTicks, lockTotalTicks = 0, 0
          errSamples, precisionSince = {}, now
        end
      else
        lockTarget = nil
        lockSince = 0
        errSamples = {}
      end

      Wait(0)     -- nişan alırken kare-kare (sadece bu durumda)
    else
      lastT = nil
      lockTarget = nil
      lockSince = 0
      lockMoveTicks, lockTotalTicks = 0, 0
      errSamples = {}
      Wait(300)
    end
  end
end)
