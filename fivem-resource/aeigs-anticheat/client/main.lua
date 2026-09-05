-- Aeigs Anti-Cheat — client: canlı veri + ekran görüntüsü + yetkili ışınlama
-- (Tespitler client/detections/*.lua içindedir. Bu dosya tespit YAPMAZ.)

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

-- Canlı konum / can / kalkan (interaktif harita + izleme)
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

-- Hafif "olası NoClip" sinyali (~250ms) — sunucunun TELEPORT taraması büyük
-- bir sıçramayı NOCLIP'e mi yoksa gerçek ışınlanmaya mı bağlayacağını bilsin
-- diye. HIZLI olması şart: sunucu teleport taraması 1 sn'de bir çalışıyor,
-- bu sinyal ondan daha sık gelmezse teleport taraması önce davranıp yanlış
-- sebeple (TELEPORT) banlayabilir. Çarpışma bayrağını hiç set etmeyen
-- noclip'leri de yakalamak için "zemin altında" sinyali de eklendi.
CreateThread(function()
  while true do
    Wait(250)
    local ped = PlayerPedId()
    local height = GetEntityHeightAboveGround(ped)
    local underground = height and height < -0.6 and not IsPedFalling(ped) and not IsPedRagdoll(ped)
    TriggerServerEvent('aeigs:collState', GetEntityCollisionDisabled(ped) or underground)
  end
end)

-- (Yetkili ışınlama alıcısı client/admin.lua'da; teleport tespitini muaf tutar.)

-- İzleme / ekran görüntüsü (screenshot-basic)
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
