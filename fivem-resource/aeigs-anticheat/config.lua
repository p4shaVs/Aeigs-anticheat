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
Config.PositionInterval    = 3    -- canlı konum/can/kalkan gönderimi (harita/izleme)
Config.WhitelistInterval   = 60   -- bypass listesini tazeler
Config.BlacklistInterval   = 60   -- kara listeyi tazeler
Config.AdminInterval       = 60   -- yönetici listesi + izinleri tazeler
Config.ScreenshotInterval  = 5    -- bekleyen ekran görüntüsü isteklerini çeker

Config.AcVersion = '0.1.0'

-- ---------------------------------------------------------------------------
-- Ekran görüntüsü (izleme) — screenshot-basic kaynağı gerekir.
-- Görüntüler bir yükleme hedefine POST edilir ve dönen URL panele iletilir.
-- Basit test için imgur/imgbb yerine kendi yükleyicinizi kullanın.
-- Boş bırakılırsa ekran görüntüsü özelliği devre dışı kalır.
-- ---------------------------------------------------------------------------
Config.ScreenshotUploadUrl = GetConvar('aeigs_ss_upload', '')  -- örn. 'https://your-uploader/upload'
Config.ScreenshotField     = 'files[]'

-- Oyun içi yönetici menüsü komutu (chat): /ac
Config.AdminCommand = 'ac'

-- İzinli kaynaklar dışından spawn olan entity'leri işaretle (protection.lua)
Config.Debug = false
