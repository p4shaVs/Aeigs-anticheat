-- Aeigs Anti-Cheat — client çekirdeği (paylaşılan durum + yardımcılar)
-- Tüm tespit modülleri (client/detections/*.lua) bunu kullanır.
-- Amaç: tek yerde durum önbelleği + rapor + kural + strike + legit-muafiyet.

Aeigs = Aeigs or {}
Aeigs.Rules = Aeigs.Rules or {}

RegisterNetEvent('aeigs:rules', function(r)
  if type(r) == 'table' then Aeigs.Rules = r end
end)
CreateThread(function() Wait(2500); TriggerServerEvent('aeigs:requestRules') end)

--- Kural açık mı? (kural gelmediyse def)
function Aeigs.rule(key, def)
  local v = Aeigs.Rules[key]
  if v == nil then return def end
  return v == true
end

--- Tespiti sunucuya raporla (throttle ile). severity CRITICAL → oto-ban akışı.
local lastReport = {}
function Aeigs.report(dtype, severity, details, throttle)
  local now = GetGameTimer()
  throttle = throttle or 15000
  if lastReport[dtype] and now - lastReport[dtype] < throttle then return end
  lastReport[dtype] = now
  TriggerServerEvent('aeigs:report', dtype, severity or 'HIGH', details or {})
end

-- ---------------------------------------------------------------------------
-- Legit aksiyon muafiyeti (spawn / admin tp / revive) — yanlış-pozitif önler
-- Diğer resource'lar da exports ile işaretleyebilir (anti-false + kontrollü bypass)
-- ---------------------------------------------------------------------------
Aeigs.grace = { tp = 0, revive = 0, spectate = 0, spawn = GetGameTimer() + 30000 }
function Aeigs.markTp() Aeigs.grace.tp = GetGameTimer() + 10000 end
function Aeigs.markRevive() Aeigs.grace.revive = GetGameTimer() + 10000 end
function Aeigs.markSpectate(on) Aeigs.grace.spectate = on and (GetGameTimer() + 3600000) or 0 end
function Aeigs.spawnGuard() return GetGameTimer() < Aeigs.grace.spawn end
function Aeigs.tpGrace() return GetGameTimer() < Aeigs.grace.tp end
function Aeigs.reviveGrace() return GetGameTimer() < Aeigs.grace.revive end
function Aeigs.spectateGrace() return GetGameTimer() < Aeigs.grace.spectate end

exports('markTeleport', function() Aeigs.markTp() end)  -- legit tp yapan scriptler çağırır
exports('markRevive', function() Aeigs.markRevive() end)
AddEventHandler('playerSpawned', function() Aeigs.grace.spawn = GetGameTimer() + 12000; Aeigs.markTp() end)
RegisterNetEvent('aeigs:grantTp', function() Aeigs.markTp() end)  -- sunucu admin tp
RegisterNetEvent('aeigs:grantRevive', function() Aeigs.markRevive() end)

-- ---------------------------------------------------------------------------
-- Strike sistemi — tek fluke ban atmasın; N vuruş / pencere içinde tetikler
-- ---------------------------------------------------------------------------
function Aeigs.strike(needed, windowMs)
  return {
    n = 0, last = 0, needed = needed or 2, window = windowMs or 10000,
    hit = function(self)
      local t = GetGameTimer()
      if t - self.last > self.window then self.n = 0 end
      self.last = t
      self.n = self.n + 1
      if self.n >= self.needed then self.n = 0; return true end
      return false
    end,
  }
end

-- ---------------------------------------------------------------------------
-- Paylaşılan durum önbelleği (200 ms) — natives tek yerde okunur
-- ---------------------------------------------------------------------------
local S = {}
Aeigs.S = S

CreateThread(function()
  while true do
    local ped = PlayerPedId()
    S.ped = ped
    S.id = PlayerId()
    S.coords = GetEntityCoords(ped)
    S.height = GetEntityHeightAboveGround(ped)
    S.speed = GetEntitySpeed(ped)
    S.vel = GetEntityVelocity(ped)
    S.inVeh = IsPedInAnyVehicle(ped, false)
    S.veh = S.inVeh and GetVehiclePedIsIn(ped, false) or 0
    S.driver = S.veh ~= 0 and GetPedInVehicleSeat(S.veh, -1) == ped
    S.vehSpeed = S.veh ~= 0 and GetEntitySpeed(S.veh) or 0.0
    S.falling = IsPedFalling(ped)
    S.ragdoll = IsPedRagdoll(ped)
    S.swimming = IsPedSwimming(ped)
    S.climbing = IsPedClimbing(ped)
    S.jumping = IsPedJumping(ped)
    S.parachute = GetPedParachuteState(ped)
    S.dead = IsPedDeadOrDying(ped, true)
    S.cutscene = IsCutscenePlaying()
    S.invincible = GetPlayerInvincible(S.id)
    S.frozen = IsEntityPositionFrozen(ped)
    S.collisionOff = GetEntityCollisionDisabled(ped)
    S.attached = IsEntityAttached(ped)
    S.armor = GetPedArmour(ped)
    S.health = GetEntityHealth(ped)
    S.maxHealth = GetEntityMaxHealth(ped)
    S.weapon = GetSelectedPedWeapon(ped)
    Wait(200)
  end
end)

-- Weapon blacklist listesi (silahlar core'da tutulur; detections/weapons kullanır)
Aeigs.WeaponBlacklist = {}
RegisterNetEvent('aeigs:weaponBlacklist', function(list)
  local m = {}
  for _, w in ipairs(list or {}) do m[w.hash] = w.action end
  Aeigs.WeaponBlacklist = m
end)
CreateThread(function() Wait(2600); TriggerServerEvent('aeigs:requestWeaponBlacklist') end)

print('^2[aeigs] client çekirdeği yüklendi^7')
