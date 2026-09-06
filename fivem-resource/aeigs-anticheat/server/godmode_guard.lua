-- godmode_guard.lua — Godmode/health-armor boost, ANA YÖNTEM (sunucu tarafı)
--
-- Mantık: biri GERÇEKTEN vuruluyor (weaponDamageEvent) ama health+armor
-- TOPLAMI (efektif can havuzu) beklenen kadar düşmüyorsa = godmode/boost,
-- hangi teknikle yapılırsa yapılsın (SetEntityInvincible, SetEntityProofs,
-- health/armor sabitleme). Oyuncunun can/zırhını DOĞRUDAN sunucu okur
-- (GetEntityHealth/GetPedArmour) — client script'ler burada araya giremez.
-- client/detections/godmode.lua (native bayrak taraması) ikinci,
-- destekleyici bir katmandır (ban atmaz, sadece rapor).
--
-- DÜZELTME GEÇMİŞİ: Önceki sürüm "armor>0 ise meşru absorbe" varsayıp her
-- isabette pencereyi sıfırlıyordu — bu, zırhı sürekli >0 (ör. 1) sabit tutan
-- bir hilenin bu tespiti SONSUZA KADAR atlatmasına izin veriyordu (her
-- isabet reset olduğu için hiç yeterli örnek birikmiyordu). Artık zırh
-- "meşru çıkış" sayılmıyor, can+zırh havuzunun bir parçası olarak izleniyor.

local function ruleOn(key)
  local r = Aeigs.getRules()
  return r[key] == true
end

local function playerFromPed(ped)
  local owner = NetworkGetEntityOwner(ped)
  if owner and owner > 0 and GetPlayerName(owner) then return owner end
  for _, pid in ipairs(GetPlayers()) do
    pid = tonumber(pid)
    if pid and GetPlayerPed(pid) == ped then return pid end
  end
  return nil
end

local win = {}              -- [vid] = { accum, hits, first, poolStart, poolMin }
local strikes = {}          -- [vid] = strike sayısı
local spawnGraceUntil = {}  -- [vid] = GetGameTimer() + grace (spawn/respawn hemen sonrası muaf)

local function reset(vid) win[vid] = nil end

-- NOT: 'playerSpawned' CLIENT-yerel bir event'tir, sunucuya otomatik
-- ULAŞMAZ — burada dinlemek ölü kod olurdu. Bunun yerine client/core.lua'nın
-- zaten (multichar/respawn/ölüp-dirilme için) sunucuya bildirdiği gerçek
-- ağ köprüsünü (aeigs:respawnAnchor, server/live.lua'da tanımlı) kullanıyoruz.
RegisterNetEvent('aeigs:respawnAnchor')
AddEventHandler('aeigs:respawnAnchor', function()
  local vid = source
  spawnGraceUntil[vid] = GetGameTimer() + (Config.GodmodeSpawnGraceMs or 6000)
  win[vid] = nil
  strikes[vid] = nil
end)

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

      if vid and spawnGraceUntil[vid] and now < spawnGraceUntil[vid] then goto next end

      if vid and not (Aeigs.isWhitelisted and Aeigs.isWhitelisted(vid)) then
        local ped = GetPlayerPed(vid)
        if ped and ped ~= 0 then
          if GetVehiclePedIsIn(ped, false) ~= 0 then goto next end  -- hasar araca gidebilir

          local hp = GetEntityHealth(ped)
          local armor = GetPedArmour(ped) or 0
          if hp and hp > 0 then
            local pool = hp + armor   -- zırh artık havuzun parçası, "meşru çıkış" değil

            local w = win[vid]
            if not w or (now - w.first) > (Config.GodmodeWindowMs or 7000) then
              w = { accum = 0, hits = 0, first = now, poolStart = pool, poolMin = pool }
              win[vid] = w
            end
            w.accum = w.accum + dmg
            w.hits = w.hits + 1
            if pool < w.poolMin then w.poolMin = pool end

            local tol = Config.GodmodePoolTolerance or 10
            local dropRatio = Config.GodmodeExpectedDropRatio or 0.0
            local expectedDrop = w.accum * dropRatio
            local actualDrop = w.poolStart - w.poolMin

            if w.hits >= (Config.GodmodeMinHits or 3)
              and w.accum >= (Config.GodmodeMinDamage or 80)
              and actualDrop <= math.max(tol, expectedDrop) then
              reset(vid)
              strikes[vid] = (strikes[vid] or 0) + 1
              if strikes[vid] >= (Config.GodmodeStrikes or 1) then
                strikes[vid] = 0
                TriggerEvent('aeigs:serverReport', vid, 'GODMODE', 'CRITICAL', {
                  reason = 'pool_not_dropping', hits = w.hits, dmg = math.floor(w.accum),
                  poolStart = w.poolStart, poolMin = w.poolMin, hp = hp, armor = armor,
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
  win[s] = nil; strikes[s] = nil; spawnGraceUntil[s] = nil
end)

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
