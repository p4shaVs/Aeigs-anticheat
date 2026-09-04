# Aeigs Anti-Cheat — Netlify Yayınlama Kılavuzu (Key sistemi dahil)

> **Neden SQLite değil?** Netlify serverless çalışır; dosya sistemi geçici ve
> salt-okunurdur. `dev.db` orada kaybolur → key/lisans sistemi çalışmaz.
> Bu yüzden bulut **PostgreSQL** (ücretsiz **Neon**) kullanıyoruz.

## 1) Bulut veritabanı (Neon) — 3 dakika
1. https://neon.tech → ücretsiz hesap → **New Project** (bölge: Europe).
2. Oluşunca **Connection string**'i kopyala. **Pooled** olanı seç
   (`...-pooler...` içeren). Şuna benzer:
   ```
   postgresql://user:pass@ep-xxx-pooler.eu-central-1.aws.neon.tech/aeigs?sslmode=require
   ```

## 2) Şemayı ve ilk veriyi buluta yükle (kendi bilgisayarından, 1 kez)
Proje klasöründe:
```bash
# 1. Neon string'ini geçici olarak ver
export DATABASE_URL="postgresql://...-pooler...neon.tech/aeigs?sslmode=require"   # Windows PowerShell: $env:DATABASE_URL="..."

# 2. Tabloları oluştur
npx prisma db push

# 3. (opsiyonel) admin + örnek veriyi ekle
npm run db:seed
```
> Bu adım tabloları buluta kurar. Netlify her build'de bunu YAPMAZ (sadece kod derler).

## 3) GitHub → Netlify
1. Repoyu GitHub'a gönder (zaten `p4shaVs/Aeigs-anticheat`).
2. https://app.netlify.com → **Add new site → Import from GitHub** → repoyu seç.
3. Netlify ayarları `netlify.toml`'dan otomatik gelir:
   - Build command: `npm run build`
   - Publish: `.next`
   - Plugin: `@netlify/plugin-nextjs` (Next.js runtime — API route'lar çalışır)

## 4) Ortam değişkenleri (Netlify → Site settings → Environment variables)
Şunları ekle (Production + Preview):

| Anahtar | Değer |
|--------|-------|
| `DATABASE_URL` | Neon pooled connection string |
| `AUTH_SECRET` | `openssl rand -base64 48` çıktısı (≥32 karakter) |
| `LICENSE_HMAC_SECRET` | `openssl rand -base64 48` çıktısı (uzun, rastgele) |
| `APP_URL` | Netlify site URL'in, örn. `https://aeigs.netlify.app` |

> **ÖNEMLİ:** `LICENSE_HMAC_SECRET` = key/lisans imzalama tuzu. Kurduktan sonra
> DEĞİŞTİRME — değişirse mevcut sunucu API token'ları geçersiz olur.
> `AUTH_SECRET` de değişirse tüm kullanıcı oturumları düşer.

## 5) Deploy
**Deploys → Trigger deploy → Deploy site.** Bitince site URL'in hazır.

## 6) Key sistemi nasıl çalışıyor (deploy sonrası)
Key/lisans akışı tamamen DB + `LICENSE_HMAC_SECRET`'e bağlı; ekstra ayar yok:
1. **Admin panelde** key üretilir → `AEIGS-XXXX-XXXX-XXXX-XXXX` (kriptografik rastgele).
2. Müşteri panelde **"Kod Kullan"** ile key'i hesabına tanımlar → sunucu oluşur.
3. Sunucu için **API token** üretilir. Ham token **bir kez** gösterilir; DB'de
   sadece HMAC hash saklanır (sızarsa token kullanılamaz).
4. FiveM `config.lua`'da:
   ```
   set aeigs_api   "https://aeigs.netlify.app/api/v1"
   set aeigs_token "aeigs_srv_xxxxxxxxxxxx"
   ```
5. Resource her heartbeat'te bu token'la `/api/v1`'e bağlanır; tespitler
   `/api/v1/detections`'a düşer, CRITICAL olanlar otomatik ban olur.

## Sık sorunlar
- **Build'de "Environment variables doğrulanamadı"** → env değişkenlerinden biri
  eksik/kısa. `AUTH_SECRET` ≥32, `LICENSE_HMAC_SECRET` ≥16 karakter olmalı.
- **"Can't reach database"** → `DATABASE_URL` yanlış ya da `?sslmode=require` yok,
  veya pooled string kullanılmamış.
- **FiveM sunucusu bağlanamıyor** → `aeigs_api` sonunda `/api/v1` olmalı; token
  doğru mu; site canlı mı kontrol et.
