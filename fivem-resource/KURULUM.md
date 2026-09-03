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
| **Analitik / Olaylar / İzleme** | Gerçek verilerle dolar (İzleme ekran görüntüsü opsiyoneldir) |

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
