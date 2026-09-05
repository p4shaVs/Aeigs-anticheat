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
Config.HeartbeatInterval   = 20   -- sunucuyu çevrimiçi tutar
Config.PlayerSyncInterval  = 10   -- oyuncu listesini gönderir (bağlanınca da anında)
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

-- ---------------------------------------------------------------------------
-- Silah tespiti eşikleri (TİTİZ — yanlış pozitifi önlemek için yüksek tutuldu)
-- ---------------------------------------------------------------------------
-- Damage Multiplier: tek atışta bu değerin üstü hasar = hile (çoğu silah <150,
-- keskin nişancı ~ yüksek olabilir; 400 güvenli tavan).
Config.MaxWeaponDamage      = 400
Config.DamageConfirmHits    = 2     -- kaç kez üst üste aşarsa raporla
-- Explosive Bullets: 8 sn içinde bu kadar "mermi patlaması" = patlayıcı mermi
Config.ExplosiveBulletMax   = 4
-- Infinite Ammo / No Reload: kaç ardışık örnekte (0.5 sn) ateş edip mermi/şarjör
-- hiç azalmazsa hile say (5 ~ 2.5 sn kesintisiz ateş).
Config.AmmoConfirmSamples   = 6

-- ---------------------------------------------------------------------------
-- GODMODE — ANA YÖNTEM: server/godmode_guard.lua (hasar-emilimi, flag'e
-- bakmadan). Mantık: oyuncu GERÇEKTEN vuruluyor (weaponDamageEvent, sunucu
-- kendi doğrudan GetEntityHealth okur) ama canı hiç düşmüyorsa = godmode —
-- hangi teknikle yapılırsa yapılsın, client script'ler bu kararı etkileyemez.
-- Client'taki native bayrak taraması (client/detections/godmode.lua) ikinci,
-- destekleyici bir yöntemdir.
-- ---------------------------------------------------------------------------
Config.GodmodeWindowMs      = 6000   -- değerlendirme penceresi
Config.GodmodeMinHits       = 3      -- pencerede en az bu kadar GERÇEK isabet
Config.GodmodeMinDamage     = 80     -- pencerede toplam en az bu kadar amaçlanan hasar
Config.GodmodeHpTolerance   = 5      -- can bu kadar bile düşmediyse "hiç düşmedi" say
Config.GodmodeStrikes       = 1      -- tek pencere yeterli (server-authoritative, hızlı ban)

-- İzinli kaynaklar dışından spawn olan entity'leri işaretle (protection.lua)
Config.Debug = false
