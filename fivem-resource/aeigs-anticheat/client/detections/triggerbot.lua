-- triggerbot.lua — Triggerbot şüphesi (ZAYIF SİNYAL, rapor-only)
--
-- Gerçek bir triggerbot, oyuncunun nişangahı bir düşman oyuncuya girer girmez
-- SABİT bir gecikmeden sonra otomatik ateş eder (bilinen dış hilelerde varsayılan
-- ~50ms). İnsan tepki süresi hem daha uzundur (~150-300ms) hem de atıştan atışa
-- doğal olarak DALGALANIR; triggerbot'ta ise ardışık örnekler hem çok kısa hem
-- de aşırı TUTARLI (düşük varyans) olur.
--
-- Bu yüzden TEK bir hızlı atış ASLA yeterli değildir (iyi refleksli/aim-assist'li
-- oyuncu tek seferde hızlı ateş edebilir) — birden fazla ÖRNEK birikip ortalama
-- VE tutarlılık (standart sapma) birlikte eşiği geçerse raporlanır. Sadece
-- threat_engine'e beslenir, tek başına asla ban/kick üretmez (bkz. WEIGHTS).

local SAMPLE_MIN   = 5      -- en az bu kadar örnek toplanmadan hiç değerlendirme yok
local DT_MAX_MS     = 260   -- örneğin "aday" sayılması için üst sınır (insan ort. tepki üstü elenir)
local MEAN_MAX_MS   = 190   -- ortalama bu değerin altındaysa şüpheli
local STDDEV_MAX_MS = 30    -- tutarlılık bu kadar yüksekse (sapma düşükse) şüpheli

local samples = {}
local acquireT = nil
local wasOnPlayer = false
local wasShooting = false

local function reset() acquireT = nil; wasOnPlayer = false; wasShooting = false end

local function evaluate()
  if #samples < SAMPLE_MIN then return end
  local sum = 0
  for _, v in ipairs(samples) do sum = sum + v end
  local mean = sum / #samples
  local varsum = 0
  for _, v in ipairs(samples) do varsum = varsum + (v - mean) * (v - mean) end
  local stddev = math.sqrt(varsum / #samples)
  if mean <= MEAN_MAX_MS and stddev <= STDDEV_MAX_MS then
    Aeigs.report('TRIGGERBOT_SUSPECTED', 'LOW', {
      mean = math.floor(mean), stddev = math.floor(stddev), samples = #samples,
    }, 30000)
    samples = {}  -- tekrar aynı pencereden spam raporlamayı önle
  elseif #samples > 12 then
    table.remove(samples, 1)  -- kayan pencere, eskiyi at
  end
end

CreateThread(function()
  while true do
    local S = Aeigs.S
    if Aeigs.rule('anti_triggerbot', true) and Aeigs.active() and S.ped and IsPlayerFreeAiming(S.id) then
      local now = GetGameTimer()
      local aiming, ent = GetEntityPlayerIsFreeAimingAt(S.id)
      local onPlayer = aiming and ent and ent ~= 0 and IsEntityAPed(ent) and IsPedAPlayer(ent)
      local shooting = IsPedShooting(S.ped)

      -- Nişangah az önce bir oyuncuya GİRDİ (önceki karede değildi) → tepki
      -- süresi ölçümü için referans an.
      if onPlayer and not wasOnPlayer then
        acquireT = now
      elseif not onPlayer then
        acquireT = nil
      end

      -- İlk ateş (bu edinim penceresinde) → örneği kaydet, aynı edinimde
      -- sonraki atışları (full-auto tekrar) SAYMA — sadece ilk tepki geçerli.
      if shooting and not wasShooting and acquireT and onPlayer then
        local dt = now - acquireT
        if dt > 0 and dt <= DT_MAX_MS then
          samples[#samples + 1] = dt
          evaluate()
        end
        acquireT = nil  -- bu edinim tüketildi
      end

      wasOnPlayer = onPlayer
      wasShooting = shooting
      Wait(0)
    else
      reset()
      samples = {}
      Wait(300)
    end
  end
end)
