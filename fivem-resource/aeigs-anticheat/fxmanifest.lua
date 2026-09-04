fx_version 'cerulean'
game 'gta5'

name 'aeigs-anticheat'
author 'Aeigs'
description 'Aeigs Anti-Cheat — web panel entegrasyonu (heartbeat, oyuncu senk., ban/kick, konsol, kaynaklar, loglar)'
version '0.1.0'

-- Sunucu tarafı: API entegrasyonu, kuyruk tüketimi, koruma kancaları
server_scripts {
  'config.lua',
  'server/http.lua',
  'server/main.lua',
  'server/live.lua',
  'server/protection.lua',
  'server/recorder.lua',
}

-- Client tarafı: çekirdek + her hile ayrı dosya (detections/) + canlı veri + menü
client_scripts {
  'config.lua',
  'client/core.lua',              -- paylaşılan durum + yardımcılar (İLK)
  'client/detections/noclip.lua',
  'client/detections/teleport.lua',
  'client/detections/godmode.lua',
  'client/detections/superjump.lua',
  'client/detections/speedhack.lua',
  'client/detections/aimbot.lua',
  'client/detections/silentaim.lua',
  'client/detections/weapons.lua',
  'client/detections/extras.lua',
  'client/detections/recorder.lua', -- hile test/debug kaydedici (yetkili)
  'client/main.lua',              -- konum/ekran görüntüsü (tespit değil)
  'client/admin.lua',             -- oyun içi yönetici menüsü
}
