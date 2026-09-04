-- recorder.lua (sunucu) — hile test kayıtlarını dosyaya yazar
-- Client'tan gelen kayıt tamponunu resources/aeigs-anticheat/recordings/ altına
-- JSON olarak kaydeder. Yalnızca yetkili (admin) oyuncular kayıt başlatabilir.

local RES = GetCurrentResourceName()

-- Kayıt yetkisi: admin olan veya 'ban' iznine sahip oyuncular
local function canRecord(src)
  if Aeigs.adminOf and Aeigs.adminOf(src) then return true end
  if Aeigs.hasPerm and Aeigs.hasPerm(src, 'ban') then return true end
  return false
end

RegisterNetEvent('aeigs:rec:auth', function()
  local src = source
  if canRecord(src) then
    TriggerClientEvent('aeigs:rec:allow', src)
    Aeigs.log('INFO', 'recorder', ('%s hile kaydını başlattı'):format(GetPlayerName(src) or src))
  else
    TriggerClientEvent('aeigs:rec:deny', src)
  end
end)

local function sanitize(s)
  return (tostring(s):gsub('[^%w%-_]', '_'))
end

RegisterNetEvent('aeigs:rec:dump', function(frames)
  local src = source
  if not canRecord(src) then return end
  if type(frames) ~= 'table' then return end

  local pname = sanitize(GetPlayerName(src) or ('p' .. src))
  local ts = os.date('%Y%m%d_%H%M%S')
  local fname = ('recordings/rec_%s_%s.json'):format(pname, ts)

  local payload = {
    player = GetPlayerName(src),
    serverId = src,
    recordedAt = ts,
    frameCount = #frames,
    frames = frames,
  }

  local ok, encoded = pcall(json.encode, payload)
  if not ok then
    Aeigs.log('ERROR', 'recorder', 'JSON encode hatası')
    return
  end

  SaveResourceFile(RES, fname, encoded, -1)
  Aeigs.log('INFO', 'recorder', ('Kayıt yazıldı: %s (%d kare)'):format(fname, #frames))
  TriggerClientEvent('aeigs:notify', src, ('~g~Kayıt dosyaya yazıldı: %s'):format(fname))
end)
