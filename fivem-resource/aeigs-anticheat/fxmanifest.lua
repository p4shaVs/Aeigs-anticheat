fx_version 'cerulean'
game 'gta5'

name 'aeigs-anticheat'
author 'Aeigs'
description 'Aeigs Anti-Cheat — kapsamlı FiveM koruması + web panel entegrasyonu'
version '0.4.0'

-- Sunucu tarafı: API entegrasyonu, kuyruk tüketimi, koruma kancaları
server_scripts {
  'config.lua',
  'server/http.lua',
  'server/main.lua',
  'server/live.lua',
  'server/protection.lua',
  'server/godmode_guard.lua',   -- godmode ANA yöntem: hasar-emilimi (server-authoritative)
  'server/vehicle_guard.lua',   -- araç godmode + anlık onarım + kalkan yenilenmesi
  'server/session_guard.lua',   -- reconnect spam + sohbet flood + kaynak allowlist (opsiyonel)
  'server/recorder.lua',
}

-- Client tarafı: çekirdek + her hile ayrı dosya (detections/) + canlı veri + menü
client_scripts {
  'config.lua',
  'client/core.lua',              -- paylaşılan durum + yardımcılar (İLK)
  'client/detections/noclip.lua',         -- yaya + araç noclip (çift sinyal)
  'client/detections/flyhack.lua',        -- sürdürülebilir yerçekimsiz uçuş
  'client/detections/teleport.lua',
  'client/detections/godmode.lua',        -- native bayrak taraması (rapor-only, 2. katman)
  'client/detections/superjump.lua',
  'client/detections/speedhack.lua',
  'client/detections/aimbot.lua',         -- Katman 1 (snap) + Katman 2 (sürekli kilit)
  'client/detections/silentaim.lua',
  'client/detections/norecoil.lua',       -- rapor-only
  'client/detections/nofalldamage.lua',   -- rapor-only
  'client/detections/weapons.lua',        -- ammo/reload + give-all-weapons + kara liste
  'client/detections/extras.lua',         -- freecam/spectate/stamina/model/invisible/prop-disguise
  'client/detections/recorder.lua', -- hile test/debug kaydedici
  'client/main.lua',              -- konum/ekran görüntüsü (tespit değil)
  'client/admin.lua',             -- oyun içi yönetici menüsü
}
