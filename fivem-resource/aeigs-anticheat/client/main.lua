-- Aeigs Anti-Cheat — client tespit + canlı veri modülü
-- NOT: Client tespiti spoofable'dır; asıl koruma sunucu tarafındadır.
-- Buradaki kontroller bariyeri yükseltir, panele rapor eder ve canlı
-- konum/can/kalkan verisini gönderir (interaktif harita + izleme).

local lastReport = {}

-- Yönetici menüsü noclip/godmode verdiğinde tespit bastırılır (yanlış pozitif).
AeigsGranted = AeigsGranted or { noclip = false, god = false }

local function report(dtype, severity, details)
  local now = GetGameTimer()
  if lastReport[dtype] and now - lastReport[dtype] < 30000 then return end
  lastReport[dtype] = now
  TriggerServerEvent('aeigs:report', dtype, severity, details or {})
end

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
      health = GetEntityHealth(ped),   -- 100..200 (sunucu 100 çıkarır)
      armor = GetPedArmour(ped),
      activity = currentActivity(ped),
    })
  end
end)

-- ---------------------------------------------------------------------------
-- Temel tespitler: godmode / anormal can / no-clip
-- ---------------------------------------------------------------------------
local noclipTicks = 0

CreateThread(function()
  while true do
    Wait(1000)
    local ped = PlayerPedId()
    local pid = PlayerId()

    -- Godmode / invincibility (menüyle verilmediyse)
    if not AeigsGranted.god then
      if GetPlayerInvincible(pid) then
        report('INVINCIBILITY', 'CRITICAL', { source = 'client' })
      end
      local health = GetEntityHealth(ped)
      if health > 200 then
        report('INVINCIBILITY', 'HIGH', { health = health })
      end
    end

    -- No-clip tespiti: yetkiyle açılmadıysa; havada, çarpışmasız/çok yüksekte
    -- hareket ediyor ve düşme/paraşüt/araç/yüzme durumunda değilse.
    if not AeigsGranted.noclip then
      local inValidAirState =
        IsPedInAnyVehicle(ped, false) or IsPedFalling(ped) or IsPedSwimming(ped)
        or GetPedParachuteState(ped) > 0 or IsPedRagdoll(ped) or IsPedJumping(ped)
        or IsPedClimbing(ped)
      local collisionOff = GetEntityCollisionDisabled(ped)
      local heightAbove = GetEntityHeightAboveGround(ped)
      local moving = GetEntitySpeed(ped) > 2.0

      if collisionOff and moving and not IsPedInAnyVehicle(ped, false) then
        noclipTicks = noclipTicks + 2
      elseif (not inValidAirState) and heightAbove > 3.0 and moving then
        noclipTicks = noclipTicks + 1
      else
        noclipTicks = 0
      end

      if noclipTicks >= 3 then
        noclipTicks = 0
        report('NOCLIP', 'CRITICAL', { source = 'client' })
      end
    else
      noclipTicks = 0
    end
  end
end)

-- ---------------------------------------------------------------------------
-- İzleme / Ekran görüntüsü (screenshot-basic gerekir)
-- Sunucu: TriggerClientEvent('aeigs:screenshot', src, uploadUrl, reqId, adminId)
-- ---------------------------------------------------------------------------
RegisterNetEvent('aeigs:screenshot', function(uploadUrl, reqId, adminId)
  if GetResourceState('screenshot-basic') ~= 'started' then
    TriggerServerEvent('aeigs:screenshotResult', reqId, nil, adminId)
    return
  end
  exports['screenshot-basic']:requestScreenshotUpload(uploadUrl, Config.ScreenshotField or 'files[]', function(data)
    -- data: yükleyiciden dönen JSON; çoğu yükleyici { files = { url } } döndürür.
    local url = nil
    local okDec, parsed = pcall(json.decode, data)
    if okDec and parsed then
      url = parsed.url or (parsed.files and parsed.files[1]) or (parsed.data and parsed.data.url)
    end
    TriggerServerEvent('aeigs:screenshotResult', reqId, url or data, adminId)
  end)
end)
