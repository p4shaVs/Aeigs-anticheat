import { z } from "zod";

// Ortam değişkenlerini uygulama açılırken doğrula. Eksik/zayıf sırlar
// prod'da erken hata versin diye burada topluca kontrol ediyoruz.
const schema = z.object({
  DATABASE_URL: z.string().min(1),
  AUTH_SECRET: z.string().min(32, "AUTH_SECRET en az 32 karakter olmalı"),
  LICENSE_HMAC_SECRET: z.string().min(16),
  APP_URL: z.string().url().default("http://localhost:3000"),
  NODE_ENV: z
    .enum(["development", "production", "test"])
    .default("development"),
});

const parsed = schema.safeParse(process.env);

if (!parsed.success) {
  // Konsola okunabilir hata bas, uygulamayı durdur.
  console.error(
    "❌ Geçersiz ortam değişkenleri:",
    parsed.error.flatten().fieldErrors
  );
  throw new Error("Ortam değişkenleri doğrulanamadı (.env dosyanızı kontrol edin)");
}

export const env = parsed.data;
