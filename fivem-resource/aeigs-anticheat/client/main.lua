-- Aeigs Anti-Cheat — client tespit + canlı veri modülü
-- Client tespiti bariyeri yükseltir, panele rapor eder ve canlı konum/can/kalkan
-- verisini gönderir. Kritik tespitler (noclip, teleport, super jump, godmode)
-- lisansta auto_ban açıksa ve oyuncu bypass'lı değilse otomatik ban ile sonuçlanır.

local lastReport = {}
local WeaponBlacklist = {}          -- [weaponHash] = 'REMOVE'|'KICK'|'BAN'
AeigsTpGrace = 0                    -- yetkili ışınlama sonrası teleport tespiti muafiyeti (ms)
local spawnGuardUntil = 0           -- bağlanma/spawn sonrası kısa muafiyet (invincibility vb.)

local function report(dtype, severity, details)
  local now = GetGameTimer()
  if lastReport[dtype] and now - lastReport[dtype] < 20000 then return end
  lastReport[dtype] = now
  TriggerServerEvent('aeigs:report', dtype, severity, details or {})
end

-- İlk spawn / resource başlangıcında kısa muafiyet (yanlış pozitif önler)
AddEventHandler('onClientResourceStart', function(res)
  if GetCurrentResourceName() ~= res then return end
  spawnGuardUntil = GetGameTimer() + 30000
  AeigsTpGrace = GetGameTimer() + 30000
end)
AddEventHandler('playerSpawned', function()
  spawnGuardUntil = GetGameTimer() + 15000
  AeigsTpGrace = GetGameTimer() + 15000
end)

-- ---------------------------------------------------------------------------
-- Aktivite tespiti (harita etiketi için)
-- ---------------------------------------------------------------------------
local function currentActivity(ped)
  if IsPedInAnyVehicle(ped, false) then return 'driving' end
  if IsPedSwimming(ped) then return 'swimming' end
  if GetPedParachuteState(ped) > 0 then return 'parachuting' end
  if IsPedShooting(ped) then return 'shooting' end
  if IsPedRagdoll(ped) then return 'ragdoll' end
  if IsPedFalling(ped) then return 'falling' end
  if GetEntitySpeed(ped) > 1.0 then return 'walking' end
  return 'idle'
end

-- ---------------------------------------------------------------------------
-- Canlı konum / can / kalkan gönderimi
-- ---------------------------------------------------------------------------
CreateThread(function()
  while true do
    Wait((Config.PositionInterval or 3) * 1000)
    local ped = PlayerPedId()
    local c = GetEntityCoords(ped)
    TriggerServerEvent('aeigs:pos', {
      x = c.x, y = c.y, z = c.z,
      heading = GetEntityHeading(ped),
      health = GetEntityHealth(ped),
      armor = GetPedArmour(ped),
      activity = currentActivity(ped),
    })
  end
end)

-- ---------------------------------------------------------------------------
-- Kritik tespitler: godmode / no-clip / super jump / teleport
-- ---------------------------------------------------------------------------
-- Kurallar (aeigs:rules ile gelir) — weapons.lua'daki cRule ile aynı mantık
local function cRule(key, defaultOn)
  local v = (AeigsRules or {})[key]
  if v == nil then return defaultOn end
  return v == true
end

local noclipTicks = 0
local jumpConfirm = 0

-- TELEPORT sunucu tarafında (server/live.lua) tespit edilir; client'ta yapılmaz
-- (client kandırılabilir + noclip'le karışır). NoClip yalnızca "çarpışma kapalı"
-- gibi GÜVENİLİR sinyalle otomatik banlanır. Godmode/invisible RAPOR edilir
-- (client'ta yanlış-pozitifsiz tespit edilemez → asla otomatik ban yok).
CreateThread(function()
  while true do
    Wait(500)
    local ped = PlayerPedId()
    local now = GetGameTimer()
    local guard = now < spawnGuardUntil
    local inVeh = IsPedInAnyVehicle(ped, false)

    -- ---- NO-CLIP (GÜVENİLİR): çarpışma kapalı + KONTROLLÜ hareket ----
    -- Yüksekten düşerken oyun çarpışmayı bir an "kapalı" okuyabilir; bu yüzden
    -- yerçekimiyle DÜŞÜŞ (aşağı hız) varsa ASLA noclip sayılmaz. NoClip = kontrollü
    -- hareket (düşmüyor, ragdoll değil, araçta değil) + çarpışma kapalı, süregelen.
    if not guard then
      local vel = GetEntityVelocity(ped)
      local dropping = (vel.z or 0.0) < -3.0        -- yerçekimi düşüşü
      local falling = IsPedFalling(ped) or dropping
      local collisionOff = GetEntityCollisionDisabled(ped)
      local moving = GetEntitySpeed(ped) > 1.5
      if collisionOff and moving and not inVeh and not falling
        and not IsPedRagdoll(ped) and not IsPedInParachuteFreeFall(ped)
        and GetPedParachuteState(ped) <= 0 then
        noclipTicks = noclipTicks + 1
      else
        noclipTicks = 0
      end
      -- ~2 sn (4 tick) kesintisiz kontrollü çarpışmasız hareket = noclip (kesin)
      if noclipTicks >= 4 then
        noclipTicks = 0
        report('NOCLIP', 'CRITICAL', { source = 'client' })
      end
    else
      noclipTicks = 0
    end

    -- ---- SUPER JUMP (yüksek eşik + doğrulama) ----
    if not guard and cRule('anti_superjump', true) and not inVeh
      and IsPedJumping(ped) and not IsPedRagdoll(ped) then
      local vz = GetEntityVelocity(ped)
      -- normal zıplama zVel ~4.5; hile 15+. 12 tavanı rampa/patlamayı dışlar.
      if (vz.z or 0.0) > 12.0 then
        jumpConfirm = jumpConfirm + 1
        if jumpConfirm >= 2 then jumpConfirm = 0; report('SUPER_JUMP', 'CRITICAL', { zVelocity = math.floor(vz.z) }) end
      end
    end

    -- ---- GODMODE / INVINCIBILITY — RAPOR (otomatik ban YOK: false riski) ----
    if not guard and cRule('anti_invincibility', false) and not IsPedDeadOrDying(ped, true)
      and GetPlayerInvincible(PlayerId()) then
      report('INVINCIBILITY', 'HIGH', { source = 'client' })
    end

    -- ---- INVISIBLE — RAPOR (otomatik ban YOK) ----
    if not guard and cRule('anti_invisibility', false)
      and not IsEntityVisible(ped) and not IsPedDeadOrDying(ped, true) and not inVeh then
      report('INVISIBLE', 'HIGH', { source = 'client' })
    end
  end
end)

-- ---------------------------------------------------------------------------
-- Kara listedeki SİLAH — envanterde belirir belirmez (ateş etmeden) yakalanır
-- ---------------------------------------------------------------------------
RegisterNetEvent('aeigs:weaponBlacklist', function(list)
  local map = {}
  for _, w in ipairs(list or {}) do map[w.hash] = w.action end
  WeaponBlacklist = map
end)

CreateThread(function()
  Wait(2000)
  TriggerServerEvent('aeigs:requestWeaponBlacklist')
  while true do
    Wait(1000)
    local ped = PlayerPedId()
    for hash, action in pairs(WeaponBlacklist) do
      if HasPedGotWeapon(ped, hash, false) then
        if action == 'REMOVE' then
          RemoveWeaponFromPed(ped, hash)
          report('BLACKLIST_WEAPON', 'MEDIUM', { hash = hash, action = 'REMOVE' })
        else
          -- KICK / BAN: sunucu doğrular ve uygular (silah kullanılmadan)
          TriggerServerEvent('aeigs:weaponHit', hash)
        end
      end
    end
  end
end)

-- ---------------------------------------------------------------------------
-- Yetkili ışınlama alıcısı (teleport tespitini muaf tutar)
-- ---------------------------------------------------------------------------
RegisterNetEvent('aeigs:teleport', function(x, y, z)
  AeigsTpGrace = GetGameTimer() + 6000
  local ped = PlayerPedId()
  SetEntityCoords(ped, x + 0.0, y + 0.0, z + 1.0, false, false, false, false)
end)

-- ---------------------------------------------------------------------------
-- İzleme / Ekran görüntüsü (screenshot-basic gerekir)
-- ---------------------------------------------------------------------------
RegisterNetEvent('aeigs:screenshot', function(uploadUrl, reqId, adminId)
  if GetResourceState('screenshot-basic') ~= 'started' then
    TriggerServerEvent('aeigs:screenshotResult', reqId, nil, adminId)
    return
  end
  exports['screenshot-basic']:requestScreenshotUpload(uploadUrl, Config.ScreenshotField or 'files[]', function(data)
    local url = nil
    local okDec, parsed = pcall(json.decode, data)
    if okDec and parsed then
      url = parsed.url or (parsed.files and parsed.files[1]) or (parsed.data and parsed.data.url)
    end
    TriggerServerEvent('aeigs:screenshotResult', reqId, url or data, adminId)
  end)
end)
