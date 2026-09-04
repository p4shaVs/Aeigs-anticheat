-- weapons.lua — Infinite Ammo / No Reload + kara listedeki silah engelleme
local UNARMED = GetHashKey("weapon_unarmed")

-- Ammo tespitleri: ateş ederken mermi/şarjör HİÇ azalmıyorsa (6 örnek doğrulama)
CreateThread(function()
  local lastWeapon, lastTotal, lastClip = nil, -1, -1
  local sameAmmo, sameClip = 0, 0
  while true do
    Wait(500)
    local S = Aeigs.S
    local ped, wep = S.ped, S.weapon
    if not ped then goto cont end
    if wep ~= lastWeapon then
      lastWeapon = wep
      lastTotal = GetAmmoInPedWeapon(ped, wep)
      lastClip = GetAmmoInClip(ped, wep)
      sameAmmo, sameClip = 0, 0
    end
    do
      local clipSize = GetMaxAmmoInClip(ped, wep, false)
      local isFirearm = wep ~= UNARMED and clipSize and clipSize > 1
      local total = GetAmmoInPedWeapon(ped, wep)
      local clip = GetAmmoInClip(ped, wep)
      if isFirearm and IsPedShooting(ped) and total > 0 then
        if Aeigs.rule('anti_infinite_ammo', true) and total == lastTotal then
          sameAmmo = sameAmmo + 1
          if sameAmmo >= 6 then sameAmmo = 0; Aeigs.report('INFINITE_AMMO', 'CRITICAL', {}) end
        else sameAmmo = 0 end
        if Aeigs.rule('anti_no_reload', true) and clip == lastClip and clip > 0 then
          sameClip = sameClip + 1
          if sameClip >= 6 then sameClip = 0; Aeigs.report('NO_RELOAD', 'CRITICAL', {}) end
        else sameClip = 0 end
      else sameAmmo = 0; sameClip = 0 end
      lastTotal = total; lastClip = clip
    end
    ::cont::
  end
end)

-- Kara listedeki silah envanterde belirir belirmez (ateş etmeden)
CreateThread(function()
  while true do
    Wait(1000)
    local ped = Aeigs.S.ped
    if ped then
      for hash, action in pairs(Aeigs.WeaponBlacklist) do
        if HasPedGotWeapon(ped, hash, false) then
          if action == 'REMOVE' then
            RemoveWeaponFromPed(ped, hash)
            Aeigs.report('BLACKLIST_WEAPON', 'MEDIUM', { hash = hash })
          else
            TriggerServerEvent('aeigs:weaponHit', hash)
          end
        end
      end
    end
  end
end)
