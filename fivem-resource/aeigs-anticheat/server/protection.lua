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
-- Patlayıcı mermi sayaçları (oyuncu bazlı, kayan pencere)
local expBullet = {}

AddEventHandler('explosionEvent', function(sender, ev)
  -- sender: patlamayı tetikleyen oyuncu (net id string olabilir)
  local src = tonumber(sender)
  if not src or src <= 0 then return end
  local etype = ev and ev.explosionType

  -- Patlayıcı mermi (explosionType 18 = BULLET). TİTİZ: tek patlama değil,
  -- kısa sürede birden fazla mermi-patlaması = patlayıcı mermi hilesi.
  if ruleOn('anti_explosive_bullets') and etype == 18 then
    local now = GetGameTimer()
    local b = expBullet[src]
    if not b or now > b.reset then b = { n = 0, reset = now + 8000 }; expBullet[src] = b end
    b.n = b.n + 1
    if b.n > (Config.ExplosiveBulletMax or 4) then
      expBullet[src] = nil
      CancelEvent()
      TriggerEvent('aeigs:serverReport', src, 'EXPLOSIVE_BULLETS', 'CRITICAL', { count = b.n })
      return
    end
  end

  if ruleOn('anti_explosion_spam') then
    if tooFast('expl:' .. src, 8, 10000) then
      TriggerEvent('aeigs:serverReport', src, 'EXPLOSION', 'HIGH', { type = etype })
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

  -- Kara liste kontrolü: yasaklı model ise oluşturmayı iptal et + uygula.
  local model = GetEntityModel(handle)
  local entry = Aeigs.blacklistLookup and Aeigs.blacklistLookup(model)
  if entry then
    local kindMap = { vehicle = 2, ped = 1, object = 3 }
    if kindMap[entry.kind] == etype then
      CancelEvent() -- yasaklı entity oluşmasın
      Aeigs.enforceBlacklist(owner, entry, model)
      return
    end
  end

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
-- SILENT AIM / MAGIC BULLET — client gerçek nişan yönünü bildirir; burada
-- vurulan oyuncu ile nişan yönü arasındaki açı ölçülür. Yere bakıp kafadan
-- vuruyorsa açı ~90°+ → kesin silent aim. (2 doğrulama.)
-- ---------------------------------------------------------------------------
local aimData = {}
RegisterNetEvent('aeigs:aim', function(px, py, pz, fx, fy, fz)
  aimData[source] = {
    pos = vector3(px + 0.0, py + 0.0, pz + 0.0),
    fwd = vector3(fx + 0.0, fy + 0.0, fz + 0.0),
    t = GetGameTimer(),
  }
end)
AddEventHandler('playerDropped', function() aimData[source] = nil end)

local silentStrike = {}

-- ---------------------------------------------------------------------------
-- Silah hasarı — imkânsız hasar (temel örnek)
-- ---------------------------------------------------------------------------
AddEventHandler('weaponDamageEvent', function(sender, data)
  local src = tonumber(sender)
  if not src then return end

  -- Silent aim: vurulan oyuncu(lar) ile nişan yönü arasındaki açı
  if ruleOn('anti_silent_aim') and data and (data.hitGlobalIds or data.hitGlobalId)
      and not (Aeigs.isWhitelisted and Aeigs.isWhitelisted(src)) then
    local aim = aimData[src]
    if aim and (GetGameTimer() - aim.t) < 800 then
      local ids = data.hitGlobalIds or { data.hitGlobalId }
      for _, nid in ipairs(ids) do
        local ent = NetworkGetEntityFromNetworkId(nid)
        if ent and ent ~= 0 and GetEntityType(ent) == 1 and IsPedAPlayer(ent) then
          local dir = GetEntityCoords(ent) - aim.pos
          local dist = #dir
          if dist > 5.0 then
            dir = dir / dist
            local dot = aim.fwd.x * dir.x + aim.fwd.y * dir.y + aim.fwd.z * dir.z
            if dot < 0.5 then  -- >60° sapma: nişan almadığın oyuncuyu vurdun
              silentStrike[src] = (silentStrike[src] or 0) + 1
              if silentStrike[src] >= 2 then
                silentStrike[src] = 0
                TriggerEvent('aeigs:serverReport', src, 'SILENT_AIM', 'CRITICAL', { angleCos = math.floor(dot * 100) / 100 })
              end
            end
          end
        end
      end
    end
  end

  -- Kara listedeki silah kullanımı
  if data and data.weaponType then
    local entry = Aeigs.blacklistLookup and Aeigs.blacklistLookup(data.weaponType)
    if entry and entry.kind == 'weapon' then
      CancelEvent()
      Aeigs.enforceBlacklist(src, entry, data.weaponType)
      return
    end
  end

  if ruleOn('anti_illegal_weapon') and data and data.weaponDamage and data.weaponDamage > 2000 then
    TriggerEvent('aeigs:serverReport', src, 'ILLEGAL_WEAPON', 'HIGH', { dmg = data.weaponDamage })
    -- Engellemek için: CancelEvent()
  end

  -- Damage Multiplier limiti — tek atışta anormal hasar. TİTİZ: birkaç kez
  -- üst üste tavanı aşınca raporla (tek fluke ban atmasın).
  if ruleOn('anti_damage_multiplier') and data and data.weaponDamage
      and data.weaponDamage > (Config.MaxWeaponDamage or 400)
      and data.weaponDamage <= 2000 then
    if tooFast('dmgmul:' .. src, (Config.DamageConfirmHits or 2) - 1, 6000) then
      TriggerEvent('aeigs:serverReport', src, 'DAMAGE_MULTIPLIER', 'CRITICAL', { dmg = math.floor(data.weaponDamage) })
    end
  end
end)

-- ---------------------------------------------------------------------------
-- giveWeaponEvent — kara listedeki silah bu event'le verilmeye çalışılırsa engelle
-- ---------------------------------------------------------------------------
AddEventHandler('giveWeaponEvent', function(sender, data)
  local src = tonumber(sender)
  if not src then return end
  local hash = data and (data.weaponType or data.weaponHash)
  if hash and Aeigs.blacklistLookup then
    local entry = Aeigs.blacklistLookup(hash)
    if entry and entry.kind == 'weapon' then
      CancelEvent()
      Aeigs.enforceBlacklist(src, entry, hash)
    end
  end
end)

-- ---------------------------------------------------------------------------
-- Ortak rapor köprüsü (sunucu tespiti → API)
-- ---------------------------------------------------------------------------
AddEventHandler('aeigs:serverReport', function(src, dtype, severity, details)
  -- Bypass'lı oyuncular (yöneticiler/içerik üreticiler) raporlanmaz.
  if Aeigs.isWhitelisted and Aeigs.isWhitelisted(src) then return end
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
  }, function(ok, data)
    if ok and data and data.banned and GetPlayerName(src) then
      DropPlayer(src, ('[Aeigs] Yasaklandınız | Sebep: %s | Ban Kodu: %s')
        :format(tostring(dtype or ''), data.banCode or '—'))
      if Aeigs.refreshBans then Aeigs.refreshBans() end
    end
  end)
  Aeigs.log('DETECTION', 'anticheat', ('%s → %s'):format(dtype, name(src)))
end)
