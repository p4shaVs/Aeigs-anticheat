"use client";

import { useState } from "react";
import { Icons } from "./icons";
import { cn } from "@/lib/utils";

const ITEMS = [
  {
    q: "Aeigs Anti-Cheat nasıl çalışır?",
    a: "Sunucu taraflı bir kaynak (resource) olarak çalışır; client'a güvenmez. Aimbot, silent aim, injection, godmode gibi hileleri gerçek zamanlı tespit eder ve web panelinden yönetmeni sağlar.",
  },
  {
    q: "Kurulum ne kadar sürer?",
    a: "Ortalama 5 dakika. Lisansını etkinleştirip kaynağı sunucuna ekliyorsun, config'e API adresi ve token'ını giriyorsun, sunucuyu başlatınca panelde çevrimiçi görünüyor.",
  },
  {
    q: "Performansı etkiler mi?",
    a: "Hayır. Optimize edilmiş yapı ile 5ms altı işlem süresi hedeflenir; sunucuna minimum yük bindirir.",
  },
  {
    q: "Web panelinden oyuncu banlayabilir miyim?",
    a: "Evet. Oyuncuları web panelinden banlayabilir, kickleyebilir, uyarabilir; ban geçmişini ve alt hesapları sorgulayabilirsin. Komutlar sunucuya anında iletilir.",
  },
  {
    q: "Lisansımı başka sunucuda kullanabilir miyim?",
    a: "Lisansın izin verdiği sunucu limiti kadar kullanabilirsin. Panelden istediğin zaman sunucu ekleyip yönetebilirsin.",
  },
  {
    q: "Demo deneyebilir miyim?",
    a: "Evet, aşağıdaki Canlı Demo bölümünden demo hesabıyla tüm paneli inceleyebilirsin.",
  },
];

export function Faq() {
  const [open, setOpen] = useState<number | null>(0);
  return (
    <div className="mx-auto max-w-3xl space-y-3">
      {ITEMS.map((it, i) => {
        const isOpen = open === i;
        return (
          <div
            key={i}
            className={cn(
              "overflow-hidden rounded-2xl border transition",
              isOpen ? "border-brand-500/30 bg-base-850/70" : "border-white/5 bg-base-850/40"
            )}
          >
            <button
              onClick={() => setOpen(isOpen ? null : i)}
              className="flex w-full items-center justify-between gap-4 px-5 py-4 text-left"
            >
              <span className="text-sm font-semibold text-white">{it.q}</span>
              <Icons.chevronDown
                size={18}
                className={cn("shrink-0 text-slate-400 transition-transform", isOpen && "rotate-180")}
              />
            </button>
            <div
              className={cn(
                "grid transition-all duration-300 ease-out",
                isOpen ? "grid-rows-[1fr] opacity-100" : "grid-rows-[0fr] opacity-0"
              )}
            >
              <div className="overflow-hidden">
                <p className="px-5 pb-5 text-sm leading-relaxed text-slate-400">{it.a}</p>
              </div>
            </div>
          </div>
        );
      })}
    </div>
  );
}
