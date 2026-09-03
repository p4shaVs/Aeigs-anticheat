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
