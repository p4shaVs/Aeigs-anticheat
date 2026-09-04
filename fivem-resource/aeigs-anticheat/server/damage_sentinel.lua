-- damage_sentinel.lua (sunucu) — Godmode / Health hack (GENEL, false'suz)
--
-- NEDEN: Test kayıtları (aeigs_rec_*) godmode açıkken bile client'ta
--   invincible=false, health=197, armor=99 gösterdi. Yani hile ne
--   GetPlayerInvincible'ı tetikliyor ne de değeri yasal sınırın üstüne
--   çıkarıyor → değere/flag'e bakan tespit KÖR. Tek gerçek sinyal:
--   "oyuncu gerçekten vuruldu ama canı/kalkanı düşmedi".
--
-- NASIL: weaponDamageEvent bir OYUNCUYU hedef aldığında, sunucu o oyuncunun
--   ped canını DOĞRUDAN okur (GetEntityHealth — client sahtekârlık yapamaz).
--   Kısa bir pencerede (7 sn) toplam amaçlanan hasar >=150 ve isabet >=5
--   olmasına rağmen can HİÇ düşmediyse (<=8) ve kalkan da düşmediyse →
--   imkânsız → godmode/health-hack. Tek fluke ban atmasın diye 2 pencere strike.
--
-- Bu yöntem hileyi NASIL yaptığından bağımsızdır (SetEntityInvincible,
--   hasar iptali, anlık can/kalkan yenileme — hepsi "vuruldu ama düşmedi"
--   sonucunu verir), o yüzden bu tek hileye değil TÜM godmode/health
--   hilelerine karşı çalışır.

local function ruleOn(key)
  local r = Aeigs.getRules()
  return r[key] == true
end

local function name(src) return GetPlayerName(src) or ('Player#' .. src) end

-- Ped entity'sinden oyuncu server id'sini bul
local function playerFromPed(ped)
  local owner = NetworkGetEntityOwner(ped)
  if owner and owner > 0 and GetPlayerName(owner) then return owner end
  -- yedek: ped == oyuncu ped'i mi diye tara
  for _, pid in ipairs(GetPlayers()) do
    pid = tonumber(pid)
    if pid and GetPlayerPed(pid) == ped then return pid end
  end
  return nil
end

-- victim server id → pencere durumu
local win = {}       -- [vid] = { accum, hits, first, hpMin, dead }
local strikes = {}   -- [vid] = strike sayısı

local function reset(vid)
  win[vid] = nil
end

AddEventHandler('weaponDamageEvent', function(sender, data)
  if not ruleOn('anti_invincibility') then return end
  if not data then return end
  local dmg = data.weaponDamage
  if not dmg or dmg <= 0 or dmg > 2000 then return end

  local ids = data.hitGlobalIds or (data.hitGlobalId and { data.hitGlobalId }) or nil
  if not ids then return end

  local now = GetGameTimer()
  for _, nid in ipairs(ids) do
    local ent = NetworkGetEntityFromNetworkId(nid)
    if ent and ent ~= 0 and DoesEntityExist(ent) and GetEntityType(ent) == 1 and IsPedAPlayer(ent) then
      local vid = playerFromPed(ent)
      if vid and not (Aeigs.isWhitelisted and Aeigs.isWhitelisted(vid)) then
        local ped = GetPlayerPed(vid)
        if ped and ped ~= 0 then
          -- Araçtaysa atla (hasar araca gidebilir → false önle)
          if GetVehiclePedIsIn(ped, false) ~= 0 then goto next end
          local hp = GetEntityHealth(ped)
          local armor = GetPedArmour(ped)
          -- Kalkan varsa ve emiyorsa: bu hit meşru soğurulmuş olabilir → sıfırla
          if armor and armor > 0 then reset(vid); goto next end
          if hp and hp > 0 then
            local w = win[vid]
            if not w or (now - w.first) > (Config.GodmodeWindowMs or 7000) then
              -- yeni pencere: referans = ilk isabetteki can
              w = { accum = 0, hits = 0, first = now, hpStart = hp, hpMin = hp }
              win[vid] = w
            end
            w.accum = w.accum + dmg
            w.hits = w.hits + 1
            if hp < w.hpMin then w.hpMin = hp end

            -- Değerlendir: bol hasar + çok isabet ama can pencere boyunca HİÇ düşmedi
            local tol = Config.GodmodeHpTolerance or 8
            if w.hits >= (Config.GodmodeMinHits or 5)
              and w.accum >= (Config.GodmodeMinDamage or 150)
              and w.hpMin >= (w.hpStart - tol) then
              reset(vid)
              strikes[vid] = (strikes[vid] or 0) + 1
              if strikes[vid] >= (Config.GodmodeStrikes or 2) then
                strikes[vid] = 0
                TriggerEvent('aeigs:serverReport', vid, 'GODMODE', 'CRITICAL', {
                  reason = 'damage_absorbed',
                  hits = w.hits, dmg = math.floor(w.accum), hp = hp,
                })
              end
            end
          end
        end
      end
      ::next::
    end
  end
end)

AddEventHandler('playerDropped', function()
  local s = source
  win[s] = nil; strikes[s] = nil
end)

-- Ölen oyuncunun strike/pencere durumunu temizle (godmode kapalı → ölebilir)
CreateThread(function()
  while true do
    Wait(3000)
    for _, pid in ipairs(GetPlayers()) do
      pid = tonumber(pid)
      local ped = pid and GetPlayerPed(pid)
      if ped and ped ~= 0 and GetEntityHealth(ped) <= 0 then
        win[pid] = nil; strikes[pid] = nil
      end
    end
  end
end)
