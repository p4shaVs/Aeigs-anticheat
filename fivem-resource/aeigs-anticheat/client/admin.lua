-- Aeigs Anti-Cheat — oyun içi yönetici menüsü (komut tabanlı) + aksiyon alıcıları
-- İzinler webden verilir; sunucu her aksiyonda izni doğrular (client sadece arayüz).

local myPerms = {}
AeigsGranted = AeigsGranted or { noclip = false, god = false }

local PERM_HELP = {
  kick = '/ac kick [id] [sebep]',
  ban = '/ac ban [id] [sebep]',
  warn = '/ac warn [id] [sebep]',
  spectate = '/ac spectate [id]',
  noclip = '/ac noclip',
  revive = '/ac revive [id]',
  tp = '/ac tp [id]',
  bring = '/ac bring [id]',
  freeze = '/ac freeze [id] on|off',
  godmode = '/ac god',
  announce = '/ac announce [mesaj]',
  screenshot = '/ac ss [id]',
}

local function notify(msg)
  SetNotificationTextEntry('STRING')
  AddTextComponentSubstringPlayerName(msg)
  DrawNotification(false, true)
end

local function has(perm) return myPerms[perm] == true end

-- Sunucudan izinler geldi
RegisterNetEvent('aeigs:perms', function(list)
  myPerms = {}
  for _, p in ipairs(list or {}) do myPerms[p] = true end
end)

RegisterNetEvent('aeigs:notify', function(msg) notify(msg) end)

-- Menü: /ac (izinli komutları listeler) veya /ac <komut> ...
RegisterCommand(Config.AdminCommand or 'ac', function(_, args)
  TriggerServerEvent('aeigs:requestPerms')
  Wait(150)
  local cmd = args[1]
  if not cmd then
    local lines = { '~b~— Aeigs Yönetici Menüsü —' }
    local any = false
    for perm, help in pairs(PERM_HELP) do
      if has(perm) then lines[#lines + 1] = '~w~' .. help; any = true end
    end
    if not any then lines[#lines + 1] = '~r~Yetkiniz yok.' end
    notify(table.concat(lines, '\n'))
    return
  end

  local id = tonumber(args[2])
  if cmd == 'kick' and has('kick') then
    TriggerServerEvent('aeigs:adminAction', 'kick', id, table.concat(args, ' ', 3))
  elseif cmd == 'ban' and has('ban') then
    TriggerServerEvent('aeigs:adminAction', 'ban', id, table.concat(args, ' ', 3))
  elseif cmd == 'warn' and has('warn') then
    TriggerServerEvent('aeigs:adminAction', 'warn', id, table.concat(args, ' ', 3))
  elseif cmd == 'revive' and has('revive') then
    TriggerServerEvent('aeigs:adminAction', 'revive', id)
  elseif cmd == 'tp' and has('tp') then
    TriggerServerEvent('aeigs:adminAction', 'tp', id)
  elseif cmd == 'bring' and has('bring') then
    TriggerServerEvent('aeigs:adminAction', 'bring', id)
  elseif cmd == 'spectate' and has('spectate') then
    TriggerServerEvent('aeigs:adminAction', 'spectate', id)
  elseif cmd == 'freeze' and has('freeze') then
    TriggerServerEvent('aeigs:adminAction', 'freeze', id, args[3] or 'on')
  elseif cmd == 'noclip' and has('noclip') then
    TriggerServerEvent('aeigs:adminAction', 'noclip')
  elseif cmd == 'god' and has('godmode') then
    TriggerServerEvent('aeigs:adminAction', 'godmode')
  elseif cmd == 'announce' and has('announce') then
    TriggerServerEvent('aeigs:adminAction', 'announce', nil, table.concat(args, ' ', 2))
  elseif cmd == 'ss' and has('screenshot') then
    TriggerServerEvent('aeigs:adminAction', 'screenshot', id)
  else
    notify('~r~Geçersiz komut veya yetki yok.')
  end
end, false)

-- İzinler değişince menüyü baştan iste
CreateThread(function()
  Wait(3000)
  TriggerServerEvent('aeigs:requestPerms')
end)

-- ---------------------------------------------------------------------------
-- Aksiyon alıcıları
-- ---------------------------------------------------------------------------
RegisterNetEvent('aeigs:revive', function()
  local ped = PlayerPedId()
  local c = GetEntityCoords(ped)
  NetworkResurrectLocalPlayer(c.x, c.y, c.z, GetEntityHeading(ped), true, false)
  SetEntityHealth(ped, 200)
  ClearPedBloodDamage(ped)
  notify('~g~Canlandırıldınız.')
end)

RegisterNetEvent('aeigs:freeze', function(state)
  local ped = PlayerPedId()
  FreezeEntityPosition(ped, state == true)
  notify(state and '~b~Donduruldunuz.' or '~b~Çözüldünüz.')
end)

RegisterNetEvent('aeigs:teleport', function(x, y, z)
  local ped = PlayerPedId()
  SetEntityCoords(ped, x + 0.0, y + 0.0, z + 1.0, false, false, false, false)
  notify('~b~Işınlandınız.')
end)

RegisterNetEvent('aeigs:spectate', function(targetId, x, y, z)
  local ped = PlayerPedId()
  SetEntityCoords(ped, x + 0.0, y + 0.0, z + 30.0, false, false, false, false)
  NetworkSetInSpectatorMode(true, GetPlayerPed(GetPlayerFromServerId(tonumber(targetId))))
  notify('~b~İzleme modu açık — kapatmak için: /ac spectate 0')
  if tonumber(targetId) == 0 then NetworkSetInSpectatorMode(false, ped) end
end)

RegisterNetEvent('aeigs:toggleGod', function()
  AeigsGranted.god = not AeigsGranted.god
  SetPlayerInvincible(PlayerId(), AeigsGranted.god)
  notify(AeigsGranted.god and '~g~Godmode açık' or '~y~Godmode kapalı')
end)

-- NoClip (yönetici) — tespit bastırılır
RegisterNetEvent('aeigs:toggleNoclip', function()
  AeigsGranted.noclip = not AeigsGranted.noclip
  notify(AeigsGranted.noclip and '~g~NoClip açık (WASD + Shift/Ctrl)' or '~y~NoClip kapalı')
end)

CreateThread(function()
  local speed = 1.0
  while true do
    Wait(0)
    if AeigsGranted.noclip then
      local ped = PlayerPedId()
      SetEntityInvincible(ped, true)
      SetEntityCollision(ped, false, false)
      FreezeEntityPosition(ped, true)
      local c = GetEntityCoords(ped)
      local dx, dy, dz = 0.0, 0.0, 0.0
      local head = GetGameplayCamRelativeHeading() + GetEntityHeading(ped)
      local pitch = GetGameplayCamRelativePitch()
      if IsControlPressed(0, 21) then speed = 3.0 else speed = 1.0 end
      if IsControlPressed(0, 32) then -- W
        dx = -math.sin(math.rad(head)) * speed
        dy = math.cos(math.rad(head)) * speed
        dz = math.sin(math.rad(pitch)) * speed
      elseif IsControlPressed(0, 33) then -- S
        dx = math.sin(math.rad(head)) * speed
        dy = -math.cos(math.rad(head)) * speed
        dz = -math.sin(math.rad(pitch)) * speed
      end
      if IsControlPressed(0, 34) then dx = dx + math.cos(math.rad(head)) * speed end -- A
      if IsControlPressed(0, 35) then dx = dx - math.cos(math.rad(head)) * speed end -- D
      if IsControlPressed(0, 44) then dz = dz + speed end -- Q up
      if IsControlPressed(0, 46) then dz = dz - speed end -- E down
      SetEntityCoordsNoOffset(ped, c.x + dx, c.y + dy, c.z + dz, true, true, true)
    else
      local ped = PlayerPedId()
      if not AeigsGranted.god then SetEntityInvincible(ped, false) end
      SetEntityCollision(ped, true, true)
      FreezeEntityPosition(ped, false)
      Wait(500)
    end
  end
end)
