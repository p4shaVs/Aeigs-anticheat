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
}

-- Client tarafı: temel tespitler + canlı veri + yönetici menüsü + izleme kancaları
client_scripts {
  'config.lua',
  'client/main.lua',
  'client/admin.lua',
}
