"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { Icons, type IconName } from "@/components/icons";
import { cn } from "@/lib/utils";

const tabs: { seg: string; label: string; icon: IconName }[] = [
  { seg: "", label: "Genel Bakış", icon: "dashboard" },
  { seg: "players", label: "Oyuncular", icon: "users" },
  { seg: "map", label: "İnteraktif Harita", icon: "map" },
  { seg: "bans", label: "Yasaklar", icon: "ban" },
  { seg: "lookup", label: "Sorgulama", icon: "search" },
  { seg: "rules", label: "Güvenlik Kuralları", icon: "shield" },
  { seg: "admins", label: "Yöneticiler", icon: "user" },
  { seg: "logs", label: "Günlükler", icon: "logs" },
  { seg: "console", label: "Konsol", icon: "terminal" },
  { seg: "settings", label: "Ayarlar", icon: "config" },
];

export function ServerTabs({ serverId }: { serverId: string }) {
  const pathname = usePathname();
  const base = `/dashboard/servers/${serverId}`;

  return (
    <div className="mb-6 flex gap-1 overflow-x-auto border-b border-white/5 pb-px">
      {tabs.map((t) => {
        const href = t.seg ? `${base}/${t.seg}` : base;
        const active =
          t.seg === ""
            ? pathname === base
            : pathname === href || pathname.startsWith(href + "/");
        const Icon = Icons[t.icon];
        return (
          <Link
            key={t.seg}
            href={href}
            className={cn(
              "flex shrink-0 items-center gap-2 border-b-2 px-4 py-2.5 text-sm font-medium transition",
              active
                ? "border-brand-500 text-white"
                : "border-transparent text-slate-400 hover:text-slate-200"
            )}
          >
            <Icon size={16} />
            {t.label}
          </Link>
        );
      })}
    </div>
  );
}
