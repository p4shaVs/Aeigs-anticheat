-- Aeigs Anti-Cheat — silah/ammo tespitleri (client)
-- TİTİZ: her tespit çok sayıda ardışık örnekle DOĞRULANDIKTAN sonra raporlanır;
-- tek bir fluke asla ban attırmaz. Kurallar sunucudan gelir (aeigs:rules).

AeigsRules = AeigsRules or {}
RegisterNetEvent('aeigs:rules', function(r)
  if type(r) == 'table' then AeigsRules = r end
end)
CreateThread(function()
  Wait(2500)
  TriggerServerEvent('aeigs:requestRules')
end)

-- defaultOn: kural henüz gelmediyse varsayılan durum
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

local UNARMED = GetHashKey('weapon_unarmed')

CreateThread(function()
  local lastWeapon, lastTotal, lastClip = nil, -1, -1
  local sameAmmo, sameClip = 0, 0

  while true do
    Wait(500)
    local ped = PlayerPedId()
    local wep = GetSelectedPedWeapon(ped)

    -- Silah değişti → sayaçları sıfırla
    if wep ~= lastWeapon then
      lastWeapon = wep
      lastTotal = GetAmmoInPedWeapon(ped, wep)
      lastClip = GetAmmoInClip(ped, wep)
      sameAmmo, sameClip = 0, 0
    end

    local clipSize = GetMaxAmmoInClip(ped, wep, false)
    local isFirearm = wep ~= UNARMED and clipSize and clipSize > 1
    local shooting = IsPedShooting(ped)
    local total = GetAmmoInPedWeapon(ped, wep)
    local clip = GetAmmoInClip(ped, wep)

    if isFirearm and shooting and total > 0 then
      -- Sonsuz mermi: ateş ederken toplam mermi HİÇ azalmıyor (tam eşit)
      if cRule('anti_infinite_ammo', true) and total == lastTotal then
        sameAmmo = sameAmmo + 1
        if sameAmmo >= (Config.AmmoConfirmSamples or 6) then
          sameAmmo = 0
          report('INFINITE_AMMO', 'CRITICAL', { source = 'client' })
        end
      else
        sameAmmo = 0
      end

      -- No reload: ateş ederken şarjör HİÇ azalmıyor (bitmiyor/kendiliğinden dolu)
      if cRule('anti_no_reload', true) and clip == lastClip and clip > 0 then
        sameClip = sameClip + 1
        if sameClip >= (Config.AmmoConfirmSamples or 6) then
          sameClip = 0
          report('NO_RELOAD', 'CRITICAL', { source = 'client' })
        end
      else
        sameClip = 0
      end
    else
      sameAmmo, sameClip = 0, 0
    end

    lastTotal = total
    lastClip = clip
  end
end)

-- NOT: Anti No Recoil güvenilir biçimde (yanlış pozitifsiz) client'ta tespit
-- edilemez; bu yüzden otomatik ban YAPILMAZ. Kural açıkken ileride sunucu
-- taraflı istatistiksel bir kontrol eklenebilir.

-- ---------------------------------------------------------------------------
-- SILENT AIM / MAGIC BULLET (client, güvenilir)
-- Mermin nereye çarptı (impact) ile nereye nişan aldığın (kamera yönü) arasındaki
-- açı ölçülür. Normal atışta mermi HER ZAMAN nişan çizgisine yakındır; silent aim /
-- magic bullet mermiyi nişan almadığın hedefe gönderir → açı çok büyük olur.
-- TİTİZ: yalnızca ~53°'den fazla sapan atışlar + 3 kez doğrulama → oto-ban.
-- ---------------------------------------------------------------------------
local function camForward()
  local r = GetGameplayCamRot(2)
  local zr, xr = math.rad(r.z), math.rad(r.x)
  local num = math.abs(math.cos(xr))
  return vector3(-math.sin(zr) * num, math.cos(zr) * num, math.sin(xr))
end

CreateThread(function()
  local lastImpact = nil
  local offHits = 0
  while true do
    Wait(30)
    local ped = PlayerPedId()
    if cRule('anti_silent_aim', true) and IsPedShooting(ped) and not IsPedInAnyVehicle(ped, false) then
      local ok, impact = GetPedLastWeaponImpactCoord(ped)
      if ok and (not lastImpact or #(impact - lastImpact) > 0.05) then
        lastImpact = impact
        local camPos = GetGameplayCamCoord()
        local toImpact = impact - camPos
        local dist = #toImpact
        if dist > 3.0 then
          local dir = toImpact / dist
          local fwd = camForward()
          local dot = fwd.x * dir.x + fwd.y * dir.y + fwd.z * dir.z  -- cos(açı)
          -- dot < 0.6  → ~53°'den fazla sapma = nişan almadığın yere isabet
          if dot < 0.6 then
            offHits = offHits + 1
            if offHits >= 3 then
              offHits = 0
              report('SILENT_AIM', 'CRITICAL', { angleCos = math.floor(dot * 100) / 100 })
            end
          else
            if offHits > 0 then offHits = offHits - 1 end
          end
        end
      end
    else
      offHits = 0
    end
  end
end)
