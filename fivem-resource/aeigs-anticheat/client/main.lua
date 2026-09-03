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
local noclipTicks = 0
local godTicks = 0
local lastPos = nil
local lastDist = 0

CreateThread(function()
  while true do
    Wait(500)
    local ped = PlayerPedId()
    local pid = PlayerId()
    local now = GetGameTimer()
    local guard = now < spawnGuardUntil
    local coords = GetEntityCoords(ped)
    local inVeh = IsPedInAnyVehicle(ped, false)

    -- ---- GODMODE / INVINCIBILITY (sürekli kontrol → yanlış pozitif yok) ----
    if not guard and not IsPedDeadOrDying(ped, true) then
      if GetPlayerInvincible(pid) then
        godTicks = godTicks + 1
      else
        godTicks = 0
      end
      -- ~4 sn (8 tick) kesintisiz invincible ise gerçek godmode kabul et
      if godTicks >= 8 then
        godTicks = 0
        report('INVINCIBILITY', 'CRITICAL', { source = 'client' })
      end
    else
      godTicks = 0
    end

    -- ---- NO-CLIP ----
    if not guard then
      local inValidAirState =
        inVeh or IsPedFalling(ped) or IsPedSwimming(ped)
        or GetPedParachuteState(ped) > 0 or IsPedRagdoll(ped)
        or IsPedJumping(ped) or IsPedClimbing(ped)
      local collisionOff = GetEntityCollisionDisabled(ped)
      local heightAbove = GetEntityHeightAboveGround(ped)
      local moving = GetEntitySpeed(ped) > 2.0
      if collisionOff and moving and not inVeh then
        noclipTicks = noclipTicks + 2
      elseif (not inValidAirState) and heightAbove > 3.0 and moving then
        noclipTicks = noclipTicks + 1
      else
        noclipTicks = 0
      end
      if noclipTicks >= 4 then
        noclipTicks = 0
        report('NOCLIP', 'CRITICAL', { source = 'client' })
      end
    end

    -- ---- SUPER JUMP ----
    if not guard and not inVeh and IsPedJumping(ped) then
      local vz = GetEntityVelocity(ped)
      -- normal zıplama ~4.5; hile ile 7.5+ dikey hız
      local zv = vz.z or 0.0
      if zv > 7.5 then
        report('SUPER_JUMP', 'CRITICAL', { zVelocity = zv })
      end
    end

    -- ---- TELEPORT ---- (tek tuşla başka konuma ışınlanma)
    -- Titiz: yalnızca YERDE, NORMAL durumdayken ANİ tek sıçrama teleporttur.
    -- NoClip sürekli hızlı hareket eder (önceki tick de büyük) → teleport SAYILMAZ.
    -- Araç, düşme, yüzme, paraşüt, noclip (çarpışmasız/havada) hariç tutulur.
    if lastPos and now > AeigsTpGrace and not guard then
      local dist = #(coords - lastPos)
      local collisionOff = GetEntityCollisionDisabled(ped)
      local heightAbove = GetEntityHeightAboveGround(ped)
      local normalState =
        not inVeh and not collisionOff and not IsPedFalling(ped)
        and not IsPedSwimming(ped) and GetPedParachuteState(ped) == 0
        and not IsPedRagdoll(ped) and not IsPedJumping(ped) and heightAbove < 6.0
      -- Ani sıçrama: bu tick > 140m ama önceki tick < 40m (yani yürürken birden atladı)
      if normalState and dist > 140.0 and lastDist < 40.0 then
        report('TELEPORT', 'CRITICAL', { distance = math.floor(dist) })
      end
      lastDist = dist
    end
    lastPos = coords
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
