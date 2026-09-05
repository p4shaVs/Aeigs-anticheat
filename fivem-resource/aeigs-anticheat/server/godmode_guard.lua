-- godmode_guard.lua — Godmode/health-hack SUNUCU YEDEK katmanı (3. katman)
--
-- client/detections/godmode.lua'daki native bayrak katmanına ek olarak, bu
-- SUNUCU TARAFLI katman client'tan tamamen bağımsız çalışır:
-- PvP sırasında biri gerçekten vurulduğu halde canı hiç düşmüyorsa (hangi
-- teknikle yapılırsa yapılsın) yakalar. Oyuncunun canını DOĞRUDAN sunucu okur
-- (GetEntityHealth) — client burada yalan söyleyemez.

local function ruleOn(key)
  local r = Aeigs.getRules()
  return r[key] == true
end

local function playerFromPed(ped)
  local owner = NetworkGetEntityOwner(ped)
  if owner and owner > 0 and GetPlayerName(owner) then return owner end
  for _, pid in ipairs(GetPlayers()) do
    pid = tonumber(pid)
    if pid and GetPlayerPed(pid) == ped then return pid end
  end
  return nil
end

local win = {}       -- [vid] = { accum, hits, first, hpStart, hpMin }
local strikes = {}   -- [vid] = strike sayısı

local function reset(vid) win[vid] = nil end

AddEventHandler('weaponDamageEvent', function(sender, data)
  if not ruleOn('anti_invincibility') then return end
  if not data then return end
  local dmg = data.weaponDamage
  if not dmg or dmg <= 0 or dmg > 2000 then return end

  local ids = data.hitGlobalIds or (data.hitGlobalId and { data.hitGlobalId }) or nil
  if not ids then return end

  local now = GetGameTimer()
  for _, nid in ipairs(ids) do
    local ent = NetworkGetEntityFromNetworkId(nid)
    if ent and ent ~= 0 and DoesEntityExist(ent) and GetEntityType(ent) == 1 and IsPedAPlayer(ent) then
      local vid = playerFromPed(ent)
      if vid and not (Aeigs.isWhitelisted and Aeigs.isWhitelisted(vid)) then
        local ped = GetPlayerPed(vid)
        if ped and ped ~= 0 then
          if GetVehiclePedIsIn(ped, false) ~= 0 then goto next end  -- hasar araca gidebilir
          local armor = GetPedArmour(ped)
          if armor and armor > 0 then reset(vid); goto next end     -- kalkan = meşru soğurma
          local hp = GetEntityHealth(ped)
          if hp and hp > 0 then
            local w = win[vid]
            if not w or (now - w.first) > (Config.GodmodeWindowMs or 7000) then
              w = { accum = 0, hits = 0, first = now, hpStart = hp, hpMin = hp }
              win[vid] = w
            end
            w.accum = w.accum + dmg
            w.hits = w.hits + 1
            if hp < w.hpMin then w.hpMin = hp end

            local tol = Config.GodmodeHpTolerance or 8
            if w.hits >= (Config.GodmodeMinHits or 5)
              and w.accum >= (Config.GodmodeMinDamage or 150)
              and w.hpMin >= (w.hpStart - tol) then
              reset(vid)
              strikes[vid] = (strikes[vid] or 0) + 1
              if strikes[vid] >= (Config.GodmodeStrikes or 2) then
                strikes[vid] = 0
                TriggerEvent('aeigs:serverReport', vid, 'GODMODE', 'CRITICAL', {
                  reason = 'server_damage_absorbed', hits = w.hits, dmg = math.floor(w.accum), hp = hp,
                })
              end
            end
          end
        end
      end
      ::next::
    end
  end
end)

AddEventHandler('playerDropped', function()
  local s = source
  win[s] = nil; strikes[s] = nil
end)

CreateThread(function()
  while true do
    Wait(3000)
    for _, pid in ipairs(GetPlayers()) do
      pid = tonumber(pid)
      local ped = pid and GetPlayerPed(pid)
      if ped and ped ~= 0 and GetEntityHealth(ped) <= 0 then
        win[pid] = nil; strikes[pid] = nil
      end
    end
  end
end)
