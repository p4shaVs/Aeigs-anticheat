import { redirect } from "next/navigation";
import { getCurrentUser } from "@/lib/session";
import { PanelShell, type NavSection } from "@/components/panel-shell";

const nav: NavSection[] = [
  {
    title: "Genel",
    items: [
      { href: "/dashboard", label: "Gösterge Paneli", icon: "dashboard", exact: true },
      { href: "/dashboard/servers", label: "Sunucularım", icon: "server" },
      { href: "/dashboard/licenses", label: "Lisanslarım", icon: "key" },
    ],
  },
  {
    title: "Araçlar",
    items: [
      { href: "/dashboard/redeem", label: "Kod Kullan", icon: "gift" },
      { href: "/dashboard/download", label: "İndir", icon: "download" },
      { href: "/docs", label: "Dokümantasyon", icon: "book" },
    ],
  },
  {
    title: "Hesap",
    items: [
      { href: "/dashboard/settings", label: "Ayarlar", icon: "config" },
      { href: "/pricing", label: "Paket Yükselt", icon: "cart" },
    ],
  },
];

export default async function DashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const user = await getCurrentUser();
  if (!user) redirect("/login?next=/dashboard");

  return (
    <PanelShell nav={nav} user={user} variant="customer">
      {children}
    </PanelShell>
  );
}
