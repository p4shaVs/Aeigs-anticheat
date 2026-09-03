-- Aeigs Anti-Cheat — client tespit modülü (başlangıç)
-- NOT: Client tespiti spoofable'dır; asıl koruma sunucu tarafındadır.
-- Buradaki kontroller bariyeri yükseltir ve panele rapor eder.

local lastReport = {}

local function report(dtype, severity, details)
  -- aynı tespiti sık göndermemek için throttle (30 sn)
  local now = GetGameTimer()
  if lastReport[dtype] and now - lastReport[dtype] < 30000 then return end
  lastReport[dtype] = now
  TriggerServerEvent('aeigs:report', dtype, severity, details or {})
end

CreateThread(function()
  while true do
    Wait(4000)
    local ped = PlayerPedId()
    local pid = PlayerId()

    -- Godmode / invincibility
    if GetPlayerInvincible(pid) then
      report('INVINCIBILITY', 'CRITICAL', { source = 'client' })
    end

    -- Anormal can (max üstü)
    local health = GetEntityHealth(ped)
    if health > 200 then
      report('INVINCIBILITY', 'HIGH', { health = health })
    end

    -- Süper zıplama işareti (bilinen global/exploit örneği — genişletilebilir)
    -- if <özel kontrol> then report('SUPER_JUMP', 'MEDIUM') end
  end
end)

-- ---------------------------------------------------------------------------
-- İzleme / Ekran görüntüsü (opsiyonel)
-- Panelden bir oyuncunun ekranı istendiğinde sunucu bu event'i tetikler.
-- Çalışması için 'screenshot-basic' resource'unun kurulu olması gerekir.
-- ---------------------------------------------------------------------------
RegisterNetEvent('aeigs:screenshot', function(uploadUrl)
  if GetResourceState('screenshot-basic') ~= 'started' then return end
  exports['screenshot-basic']:requestScreenshotUpload(uploadUrl, 'files[]', function(data)
    -- data: yükleme sonucundan dönen JSON (görsel URL'i)
    TriggerServerEvent('aeigs:screenshotResult', data)
  end)
end)
