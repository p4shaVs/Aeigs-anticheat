-- Aeigs Anti-Cheat — sunucu taraflı korumalar
-- Panelden açılan "Güvenlik Kuralları" (heartbeat config.rules) burada okunur.
-- Başlangıç için çoğu kural RAPOR eder (report-only). Engellemeyi (CancelEvent)
-- açmak isterseniz ilgili yerdeki yorumu aktifleştirin — önce test edin.

local function ruleOn(key)
  local r = Aeigs.getRules()
  return r[key] == true
end

-- Basit oran sınırlayıcı (spam tespiti)
local hits = {}
local function tooFast(key, limit, windowMs)
  local now = GetGameTimer()
  local b = hits[key]
  if not b or now > b.reset then
    hits[key] = { count = 1, reset = now + windowMs }
    return false
  end
  b.count = b.count + 1
  return b.count > limit
end

local function name(src) return GetPlayerName(src) or ('Player#' .. src) end

-- ---------------------------------------------------------------------------
-- Patlama koruması
-- ---------------------------------------------------------------------------
AddEventHandler('explosionEvent', function(sender, ev)
  -- sender: patlamayı tetikleyen oyuncu (net id string olabilir)
  local src = tonumber(sender)
  if not src or src <= 0 then return end
  if ruleOn('anti_explosion_spam') then
    if tooFast('expl:' .. src, 8, 10000) then
      TriggerEvent('aeigs:serverReport', src, 'EXPLOSION', 'HIGH', { type = ev and ev.explosionType })
      -- Engellemek için: CancelEvent()
    end
  end
end)

-- ---------------------------------------------------------------------------
-- İzinsiz entity (araç/ped/obje) spam koruması
-- ---------------------------------------------------------------------------
AddEventHandler('entityCreating', function(handle)
  local owner = NetworkGetEntityOwner(handle)
  if not owner or owner <= 0 then return end
  local etype = GetEntityType(handle) -- 1=ped, 2=vehicle, 3=object
  local key
  if etype == 2 and ruleOn('anti_vehicle_spawn') then key = 'veh'
  elseif etype == 1 and ruleOn('anti_ped_spawn') then key = 'ped'
  elseif etype == 3 and ruleOn('anti_object_spawn') then key = 'obj' end
  if key and ruleOn('anti_entity_spam') then
    if tooFast(('ent:%s:%s'):format(key, owner), 30, 10000) then
      local tmap = { veh = 'ILLEGAL_VEHICLE', ped = 'ILLEGAL_PED', obj = 'ILLEGAL_OBJECT' }
      TriggerEvent('aeigs:serverReport', owner, tmap[key], 'MEDIUM', { entityType = etype })
      -- Engellemek için: CancelEvent()
    end
  end
end)

-- ---------------------------------------------------------------------------
-- Silah hasarı — imkânsız hasar (temel örnek)
-- ---------------------------------------------------------------------------
AddEventHandler('weaponDamageEvent', function(sender, data)
  local src = tonumber(sender)
  if not src then return end
  if ruleOn('anti_illegal_weapon') and data and data.weaponDamage and data.weaponDamage > 2000 then
    TriggerEvent('aeigs:serverReport', src, 'ILLEGAL_WEAPON', 'HIGH', { dmg = data.weaponDamage })
    -- Engellemek için: CancelEvent()
  end
end)

-- ---------------------------------------------------------------------------
-- Ortak rapor köprüsü (sunucu tespiti → API)
-- ---------------------------------------------------------------------------
AddEventHandler('aeigs:serverReport', function(src, dtype, severity, details)
  local ids = {}
  for _, id in ipairs(GetPlayerIdentifiers(src)) do
    if id:sub(1, 8) == 'license:' then ids.license = id break end
  end
  Aeigs.request('/detections', 'POST', {
    type = dtype,
    severity = severity or 'MEDIUM',
    playerName = name(src),
    license = ids.license,
    details = details or {},
  }, nil)
  Aeigs.log('DETECTION', 'anticheat', ('%s → %s'):format(dtype, name(src)))
end)
