-- Aeigs Anti-Cheat — davranış tespitleri (client)
-- Speed hack, freecam, yetkisiz spectate, infinite stamina, model değişimi,
-- araç hız hilesi. TİTİZ: durum kontrolleri + doğrulama; false riski düşük.
-- Kurallar sunucudan (aeigs:rules) gelir; yalnızca açık olanlar çalışır.

AeigsRules = AeigsRules or {}
AeigsGranted = AeigsGranted or {}

local function cRule(key, defaultOn)
  local v = AeigsRules[key]
  if v == nil then return defaultOn end
  return v == true
end

local lastReport = {}
local function report(dtype, severity, details)
  local now = GetGameTimer()
  if lastReport[dtype] and now - lastReport[dtype] < 20000 then return end
  lastReport[dtype] = now
  TriggerServerEvent('aeigs:report', dtype, severity, details or {})
end

local startGuard = GetGameTimer() + 30000
AddEventHandler('playerSpawned', function() startGuard = GetGameTimer() + 12000 end)

-- ---------------------------------------------------------------------------
-- SPEED HACK (yaya) — durum-duyarlı tavan, 5x doğrulama → oto-ban
-- Yaya koşusu ~7 m/s. 18 m/s (65 km/h) yaya için imkânsız. Düşme/araç/ragdoll/
-- yüzme/paraşüt/tırmanma/havada hariç → patlama savrulması vb. false vermez.
-- ---------------------------------------------------------------------------
CreateThread(function()
  local spd = 0
  while true do
    Wait(400)
    local ped = PlayerPedId()
    if GetGameTimer() > startGuard and cRule('anti_speedhack', true) then
      local inVeh = IsPedInAnyVehicle(ped, false)
      if not inVeh and not IsPedFalling(ped) and not IsPedRagdoll(ped)
        and GetPedParachuteState(ped) <= 0 and not IsPedSwimming(ped)
        and not IsPedClimbing(ped) and not IsPedJumping(ped) and not IsEntityInAir(ped) then
        if GetEntitySpeed(ped) > 18.0 then
          spd = spd + 1
          if spd >= 5 then spd = 0; report('SPEED_HACK', 'CRITICAL', { speed = math.floor(GetEntitySpeed(ped)) }) end
        else spd = 0 end
      else spd = 0 end

      -- Araç hız hilesi (aşırı) — en hızlı araç ~60 m/s; 130 m/s = kesin hile
      if inVeh then
        local veh = GetVehiclePedIsIn(ped, false)
        if veh ~= 0 and GetEntitySpeed(veh) > 130.0 then
          report('VEHICLE_SPEED', 'CRITICAL', { speed = math.floor(GetEntitySpeed(veh)) })
        end
      end
    end
  end
end)

-- ---------------------------------------------------------------------------
-- Freecam / Spectate / Infinite Stamina / Model change — RAPOR (oto-ban yok)
-- ---------------------------------------------------------------------------
CreateThread(function()
  local sprintStart = 0
  local lastModel = nil
  local modelTimes = {}
  while true do
    Wait(1000)
    local ped = PlayerPedId()
    if GetGameTimer() <= startGuard then goto continue end

    -- Yetkisiz spectate (yöneticinin verdiği spectate muaf)
    if cRule('anti_spectate', true) and NetworkIsInSpectatorMode() and not AeigsGranted.spectate then
      report('SPECTATE', 'HIGH', { source = 'client' })
    end

    -- Freecam: kamera peddan anormal uzakta (3. şahıs ~5m; 25m+ = serbest kamera)
    if cRule('anti_freecam', true) and not IsPedInAnyVehicle(ped, false)
      and not IsCutscenePlaying() and not IsPedDeadOrDying(ped, true) then
      local d = #(GetGameplayCamCoord() - GetEntityCoords(ped))
      if d > 25.0 then report('FREECAM', 'HIGH', { dist = math.floor(d) }) end
    end

    -- Infinite stamina: kesintisiz 45 sn koşu (normal stamina çok önce biter)
    if cRule('anti_infinite_stamina', true) then
      if IsPedSprinting(ped) then
        if sprintStart == 0 then sprintStart = GetGameTimer() end
        if GetGameTimer() - sprintStart > 45000 then
          sprintStart = 0
          report('INFINITE_STAMINA', 'HIGH', { source = 'client' })
        end
      else
        sprintStart = 0
      end
    end

    -- Model değişimi: 30 sn içinde 3'ten fazla model değişimi = şüpheli
    if cRule('anti_model_change', false) then
      local m = GetEntityModel(ped)
      if lastModel and m ~= lastModel then
        modelTimes[#modelTimes + 1] = GetGameTimer()
        local cnt = 0
        for i = #modelTimes, 1, -1 do
          if GetGameTimer() - modelTimes[i] < 30000 then cnt = cnt + 1 else break end
        end
        if cnt > 3 then modelTimes = {}; report('MODEL_CHANGE', 'HIGH', { source = 'client' }) end
      end
      lastModel = m
    end

    ::continue::
  end
end)
