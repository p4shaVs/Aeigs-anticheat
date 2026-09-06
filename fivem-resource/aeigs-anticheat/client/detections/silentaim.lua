-- silentaim.lua — Silent Aim / Magic Bullet (client kamerayı bildirir, SUNUCU karar verir)
-- Gerçek silent aim, görünen mermiyi baktığın yere gönderir ama sunucuya
-- "düşmanı vurdum" diye event yollar. Bu yüzden client kamerandaki GERÇEK nişan
-- yönünü sunucuya sürekli bildirir; sunucu weaponDamageEvent'te vurulan oyuncuyla
-- nişan yönü arasındaki açıya bakar. Yere bakıp kafadan vuruyorsan açı ~90°+ → BAN.
local function camForward()
  local r = GetGameplayCamRot(2)
  local zr, xr = math.rad(r.z), math.rad(r.x)
  local num = math.abs(math.cos(xr))
  return vector3(-math.sin(zr) * num, math.cos(zr) * num, math.sin(xr))
end

CreateThread(function()
  while true do
    local S = Aeigs.S
    if S.ped and Aeigs.rule('anti_silent_aim', true) and S.weapon ~= GetHashKey("weapon_unarmed") and not S.dead then
      local cp = GetGameplayCamCoord()
      local fw = camForward()
      TriggerServerEvent('aeigs:aim', cp.x, cp.y, cp.z, fw.x, fw.y, fw.z)
      Wait(150)
    else
      Wait(700)
    end
  end
end)
