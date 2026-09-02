# Aeigs Anti-Cheat

FiveM sunucuları için yeni nesil anti-cheat SaaS platformu. Bu depo **web tarafını**
içerir: pazarlama sitesi, kullanıcı hesapları, satın alım/lisans sistemi, müşteri ve
admin panelleri, key generator ve FiveM kaynağının çağıracağı REST API.

> FiveM Lua kaynağı (in-game) ayrı bir entegrasyon adımında eklenecektir. API tarafı
> (`/api/v1/*`) şimdiden hazırdır.

## Teknoloji

- **Next.js 14** (App Router) + **TypeScript**
- **TailwindCSS** — koyu, modern panel tasarımı
- **Prisma** + **SQLite** (prod'da `postgresql`'e geçilebilir)
- **JWT (httpOnly cookie)** + **bcrypt** — güvenli oturum, hash'li şifreler
- **Zod** doğrulama, in-memory **rate limiting**, RBAC (USER/ADMIN), denetim kaydı

## Kurulum

```bash
npm install
cp .env.example .env          # AUTH_SECRET ve LICENSE_HMAC_SECRET değerlerini değiştirin
npm run db:push               # şemayı veritabanına uygula
npm run db:seed               # demo veri + kullanıcılar (opsiyonel)
npm run dev                   # http://localhost:3000
```

### Demo hesaplar (seed sonrası)

| Rol     | E-posta          | Şifre      |
|---------|------------------|------------|
| Admin   | admin@aeigs.gg   | Admin1234  |
| Müşteri | demo@aeigs.gg    | Demo1234   |

> Not: İlk kaydolan kullanıcı otomatik olarak **ADMIN** olur (kurulum kolaylığı).

## Özellikler

### Public
- Modern landing (hero, özellikler, koruma vitrini, panel önizleme)
- Fiyatlandırma + tek tıkla lisans oluşturan satın alma akışı (manuel/demo ödeme)
- Dokümantasyon + API referansı

### Müşteri Paneli (`/dashboard`)
- Genel bakış (canlı grafik, tespit donut'u, son aktivite)
- Sunucular: oluşturma, oyuncular, **web'den ban/kick/uyarı**, ban yönetimi, günlükler, yapılandırma
- Lisanslarım, Kod Kullan (redeem), İndir, Hesap ayarları (şifre değiştir)

### Admin Paneli (`/admin`)
- Platform istatistikleri, kullanıcılar, sunucular, denetim kaydı
- **Key Generator**: özellik seçerek toplu lisans üretimi, ürüne/kullanıcıya atama, süre/limit
- Ürün yönetimi (paketler, fiyat, özellikler)

## FiveM API (`/api/v1`)

Tüm istekler `Authorization: Bearer <sunucu-token>` başlığı gerektirir. Token, sunucu
oluşturulurken üretilir; DB'de yalnızca HMAC hash'i saklanır.

| Method | Uç | Açıklama |
|--------|-----|----------|
| POST | `/api/v1/heartbeat` | Sunucuyu çevrimiçi tutar, config döner |
| POST | `/api/v1/players/sync` | Aktif oyuncu listesini senkronize eder |
| POST | `/api/v1/detections` | Tespit raporlar (kritik + auto_ban → otomatik ban) |
| GET  | `/api/v1/actions/pending` | Panelden verilen bekleyen cezaları çeker |
| POST | `/api/v1/actions/ack` | Uygulanan cezaları onaylar |
| GET  | `/api/v1/bans` | Aktif ban listesini çeker (giriş kontrolü) |

## Güvenlik notları

- Şifreler bcrypt (12 round) ile hash'lenir; hatalı girişte kademeli kilit.
- Oturumlar DB'de saklanır ve iptal edilebilir (jti); şifre değişince diğer cihazlar düşer.
- Sunucu API token'ları yalnızca bir kez gösterilir, DB'de HMAC-SHA256 hash'i tutulur.
- Tüm girişler Zod ile doğrulanır; hassas uçlarda rate limit ve denetim kaydı vardır.
- Güvenlik başlıkları (`next.config.mjs`) ve rol tabanlı middleware koruması.

## Prod'a geçiş

1. `prisma/schema.prisma` içinde `provider = "postgresql"` yapıp `DATABASE_URL` verin.
2. Güçlü `AUTH_SECRET` ve `LICENSE_HMAC_SECRET` üretin (`openssl rand -base64 48`).
3. Gerçek ödeme entegrasyonu (Stripe/PayPal) `/api/checkout` üzerine eklenebilir.

## Komutlar

```bash
npm run dev        # geliştirme
npm run build      # prod derleme (prisma generate + next build)
npm run start      # prod sunucu
npm run db:studio  # Prisma Studio
npm run db:seed    # demo veri
```
