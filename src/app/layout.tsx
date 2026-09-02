import type { Metadata, Viewport } from "next";
import "./globals.css";

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
    <html lang="tr" className="dark">
      <body
        style={{
          // Font indirme bağımlılığı olmadan modern sistem yığını.
          ["--font-sans" as any]:
            "'Inter', ui-sans-serif, system-ui, -apple-system, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif",
        }}
      >
        {children}
      </body>
    </html>
  );
}
