import type { Metadata, Viewport } from "next";
import { Plus_Jakarta_Sans } from "next/font/google";
import "./globals.css";

// Modern, hafif kalın, geometrik gövdeli font. Başlıklarda 700-800 kullanılır.
const jakarta = Plus_Jakarta_Sans({
  subsets: ["latin"],
  weight: ["400", "500", "600", "700", "800"],
  variable: "--font-sans",
  display: "swap",
});

export const metadata: Metadata = {
  title: {
    default: "Aeigs Anti-Cheat — FiveM için Yeni Nesil Koruma",
    template: "%s · Aeigs Anti-Cheat",
  },
  description:
    "FiveM sunucunuz için gelişmiş anti-cheat, web paneli ve lisans yönetimi. Aimbot, silent aim ve exploit koruması; canlı harita, ban/kick yönetimi ve daha fazlası.",
  applicationName: "Aeigs Anti-Cheat",
  keywords: ["fivem", "anticheat", "anti-cheat", "aeigs", "fivem panel"],
  robots: { index: true, follow: true },
};

export const viewport: Viewport = {
  themeColor: "#05060a",
  width: "device-width",
  initialScale: 1,
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="tr" className={`dark ${jakarta.variable}`}>
      <body className="font-sans">{children}</body>
    </html>
  );
}
