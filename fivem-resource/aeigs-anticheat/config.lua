Config = {}

-- ---------------------------------------------------------------------------
-- Bağlantı ayarları
-- server.cfg içine şunları ekleyin (panelden Ayarlar sekmesinden alın):
--   set aeigs_api   "http://localhost:3000/api/v1"
--   set aeigs_token "aeigs_srv_xxxxxxxxxxxx"
-- ---------------------------------------------------------------------------
Config.ApiBase = GetConvar('aeigs_api', 'http://localhost:3000/api/v1')
Config.Token   = GetConvar('aeigs_token', '')

-- Zamanlayıcılar (saniye)
Config.HeartbeatInterval   = 30   -- sunucuyu çevrimiçi tutar
Config.PlayerSyncInterval  = 20   -- oyuncu listesini gönderir
Config.ActionPollInterval  = 5    -- panelden gelen ceza/komutları çeker
Config.BanRefreshInterval  = 60   -- ban listesini tazeler
Config.ResourceSyncInterval= 45   -- kaynak listesini gönderir
Config.LogFlushInterval    = 10   -- birikmiş logları gönderir

Config.AcVersion = '0.1.0'

-- İzinli kaynaklar dışından spawn olan entity'leri işaretle (protection.lua)
Config.Debug = false
