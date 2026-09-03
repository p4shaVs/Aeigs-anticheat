# Aeigs Anti-Cheat — FiveM Kurulum & Kullanım (Yerel)

Bu rehber, web panelini FiveM sunucuna **yerelde** bağlamayı anlatır. Sonunda:
oyuncular (license + discord) panelde görünür, web'den ban/kick/uyarı oyunda
uygulanır, banlanan oyuncuya **ban kodu** gösterilir, konsolu ve kaynakları
(resource) web'den yönetirsin, loglar panele akar.

---

## 1) Web panelini çalıştır
Proje kökünde:
```bash
npm install
cp .env.example .env
npm run db:push
npm run db:seed
npm run dev            # http://localhost:3000
```
Giriş: `admin@aeigs.gg / Admin1234` (admin) veya `demo@aeigs.gg / Demo1234`.

## 2) Panelde sunucu oluştur ve token al
1. Panelde **Sunucularım → (lisans etkinleştir) → Sunucu Oluştur**.
2. Sunucuya gir → **Ayarlar** sekmesi → **Token Yenile** ile bir token oluştur.
   (Token yalnızca bir kez gösterilir, kopyala.)
3. **API Adresi**'ni de not al: `http://localhost:3000/api/v1`

> FiveM sunucun **aynı makinede** ise `localhost` çalışır. Başka makinede ise
> `localhost` yerine web'in çalıştığı makinenin LAN IP'sini yaz
> (örn. `http://192.168.1.50:3000/api/v1`).

## 3) Resource'u sunucuna ekle
`fivem-resource/aeigs-anticheat` klasörünü FiveM sunucunun `resources/`
klasörüne kopyala. Sonra `server.cfg` dosyasına ekle:
```cfg
set aeigs_api   "http://localhost:3000/api/v1"
set aeigs_token "aeigs_srv_BURAYA_TOKEN"
# İzleme (canlı ekran) için opsiyonel — screenshot-basic + bir yükleme hedefi:
set aeigs_ss_upload ""     # örn. "https://your-uploader/upload"
ensure aeigs-anticheat
```
Sunucuyu başlat. Konsolda `[aeigs] Anti-Cheat başlatıldı` görürsün. Panelde
sunucu **Çevrimiçi** olur.

---

## Ne çalışır?
| Panel | Ne yapar |
|---|---|
| **Genel Bakış** | Sunucu online/offline, oyuncu/ban sayıları, canlı grafik (gerçek veri) |
| **Oyuncular** | Oyuncular **license + discord** ile listelenir; web'den **Ban/Kick/Uyarı** |
| **Yasaklar** | Banlar + kaldır; her banın bir **ban kodu** olur |
| **Güvenlik Kuralları** | Toggle'lar heartbeat ile sunucuya iner; korumalar ona göre çalışır |
| **Konsol** | Yazdığın komut sunucuda `ExecuteCommand` ile çalışır |
| **Kaynaklar** | Sunucudaki resource'lar; **Başlat/Durdur/Yeniden Başlat** |
| **Günlük** | Sunucu olayları (giriş/çıkış/tespit/konsol) panele akar |
| **İnteraktif Harita** | Oyuncular **gerçek GTA5 konumlarında**; can/kalkan/aktivite/yön anlık; 5 sn'de bir canlı yenileme |
| **İzleme** | Oyuncunun **canlı ekran görüntüsü** (screenshot-basic gerekir) |
| **Bypass** | Discord ID / license ile muafiyet — bu kişiler banlanmaz/işaretlenmez |
| **Kara Liste** | Yasaklı araç/silah/ped/nesne — oyunda otomatik engellenir (REMOVE/KICK/BAN) |
| **Yöneticiler** | Oyun içi menü izinleri (kick/ban/tp/noclip/spectate…) webden verilir |

## Yeni özellikler — nasıl çalışır?

### 🗺️ İnteraktif Harita (canlı konum + can + kalkan)
Resource her **3 saniyede** çevrimiçi oyuncuların konum/can/kalkan/aktivite/yön
verisini gönderir. Harita bunları gerçek GTA5 koordinatlarına yerleştirir; sağ
panelden bir oyuncu seçince can/kalkan barları, aktivite, ping ve konumu görünür.

### 👁️ Canlı Ekran (İzleme)
1. Sunucuya [`screenshot-basic`](https://github.com/citizenfx/screenshot-basic) ekle.
2. `set aeigs_ss_upload "<yükleme adresin>"` ayarla (görseli barındıran endpoint).
3. Panelde **İzleme** veya haritada oyuncu → **Canlı Ekranı İste**. Görüntü
   yükleme hedefine gönderilir, dönen URL panelde gösterilir.

### 🛡️ Bypass (muafiyet)
**Moderasyon → Bypass**'tan Discord ID veya license ekle. Bu kimlikler otomatik
ban, hile tespiti raporu ve kara listeden **muaf** tutulur. (NoClip açan yönetici
banlanmaz.)

### 🚫 Kara Liste (araç/silah/ped/nesne)
**Yönetim → Kara Liste**'den model adı ekle (örn. `rhino`, `weapon_rpg`). Oyuncu
spawn etmeye çalışınca **oluşturma iptal edilir** ve seçtiğin işlem uygulanır:
Kaldır / Kick / Ban.

### 🎮 Oyun içi yönetici menüsü (webden izin)
**Yönetim → Yöneticiler**'den kişiyi identifier (`discord:...`) ile ekle ve
izinleri seç. Oyunda `/ac` yazınca izinli komutlar listelenir:
```
/ac kick [id] [sebep]     /ac ban [id] [sebep]      /ac warn [id] [sebep]
/ac tp [id]   /ac bring [id]   /ac spectate [id]     /ac revive [id]
/ac freeze [id] on|off    /ac noclip   /ac god   /ac announce [mesaj]   /ac ss [id]
```
İzin **her aksiyonda sunucuda** doğrulanır (client sadece arayüz). Oyun içi
ban/kick/uyarı panele ve Discord'a da işlenir.

### 🔔 Discord webhook logları
**Ayarlar**'da webhook URL'ini gir ve hangi olayların gönderileceğini seç
(Ban, Kick, Uyarı, Tespit, Otomatik Ban, Kara Liste İhlali, Bağlanma). Her olay
zengin **embed** olarak Discord'a düşer.

### 🚁 NoClip tespiti + otomatik ban
Client, çarpışmasız/havada anormal hareketi tespit eder → `NOCLIP (CRITICAL)`
raporlar. Lisansta **auto_ban** açıksa ve oyuncu **bypass'lı değilse** otomatik
banlanır. (Menüyle açılan yönetici noclip'i tespiti tetiklemez.)

## Ban kodu nasıl çalışır?
- Web'den birini banlayınca oyuncu oyundan atılırken **Ban Kodu: AC-XXXXXX**
  görür.
- Oyuncu `http://localhost:3000/ban` sayfasına kodu girip **ban sebebini**
  görebilir.

## Akış (özet)
```
FiveM resource  ──heartbeat / players / detections / logs / resources──▶  Web API
FiveM resource  ◀──actions (ban/kick/warn) / commands (konsol, resource)──  Web API
```
Resource her birkaç saniyede kuyruğu çeker; panelden bir şey yapınca birkaç
saniye içinde oyunda uygulanır.

## Opsiyonel: Ekran izleme (Monitoring)
Canlı ekran görüntüsü için sunucuya [`screenshot-basic`](https://github.com/citizenfx/screenshot-basic)
kaynağını ekle. Client tarafı `aeigs:screenshot` event'i ile görüntü alır.
(Yükleme hedefi ayarı ilerleyen adımda panele bağlanacak.)

## Güvenlik notları
- `aeigs_token`'ı gizli tut; sızarsa panelden **Token Yenile** ile iptal et.
- Sunucu taraflı korumalar (protection.lua) başlangıçta **rapor eder**;
  engellemeyi (CancelEvent) açmadan önce kendi sunucunda test et.

## Sık sorunlar
- **Panel offline / oyuncu gelmiyor:** `aeigs_api` ve `aeigs_token` doğru mu?
  FiveM host'tan web adresine erişilebiliyor mu? (`localhost` vs LAN IP)
- **401 hata (konsolda):** token yanlış/iptal — panelden yenile.
- **Kaynaklar boş:** resource yeni başladıysa ~45 sn içinde senkronize olur.
