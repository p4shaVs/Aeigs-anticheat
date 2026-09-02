"use client";

import { useMemo, useState } from "react";
import { Icons } from "@/components/icons";
import { cn } from "@/lib/utils";

export interface MapPlayer {
  id: string;
  name: string;
  trustScore: number;
  license: string | null;
  playtimeSec: number;
}

// id'den deterministik konum üretir (gerçek koordinatlar oyun içi entegrasyonla gelecek).
function pos(id: string) {
  let h1 = 0, h2 = 0;
  for (let i = 0; i < id.length; i++) {
    h1 = (h1 * 31 + id.charCodeAt(i)) % 100000;
    h2 = (h2 * 17 + id.charCodeAt(i) * 7) % 100000;
  }
  return { x: 6 + (h1 % 88), y: 6 + (h2 % 88) };
}

function threatColor(score: number) {
  if (score >= 70) return "#10b981";
  if (score >= 40) return "#f59e0b";
  return "#f43f5e";
}

export function MapView({ players, maxSlots }: { players: MapPlayer[]; maxSlots: number }) {
  const [selected, setSelected] = useState<string | null>(null);
  const [query, setQuery] = useState("");
  const [onlyThreats, setOnlyThreats] = useState(false);

  const filtered = useMemo(() => {
    const q = query.toLowerCase();
    return players.filter((p) => {
      if (onlyThreats && p.trustScore >= 40) return false;
      if (!q) return true;
      return p.name.toLowerCase().includes(q) || (p.license ?? "").toLowerCase().includes(q);
    });
  }, [players, query, onlyThreats]);

  const shownIds = new Set(filtered.map((p) => p.id));

  return (
    <div className="grid gap-4 lg:grid-cols-[1fr_320px]">
      {/* Harita */}
      <div className="relative aspect-[16/11] overflow-hidden rounded-2xl border border-white/10 bg-base-900">
        {/* Zemin: ızgara + su/kara hissi */}
        <div className="absolute inset-0 bg-grid-faint [background-size:32px_32px] opacity-60" />
        <div className="pointer-events-none absolute inset-0 bg-gradient-to-br from-brand-500/5 via-transparent to-emerald-500/5" />
        <div className="pointer-events-none absolute -left-10 top-10 h-48 w-48 rounded-full bg-brand-500/10 blur-3xl" />
        <div className="pointer-events-none absolute bottom-6 right-10 h-56 w-56 rounded-full bg-emerald-500/10 blur-3xl" />

        {/* Marker'lar */}
        {players.map((p) => {
          const { x, y } = pos(p.id);
          const active = shownIds.has(p.id);
          const isSel = selected === p.id;
          return (
            <button
              key={p.id}
              onClick={() => setSelected(isSel ? null : p.id)}
              className={cn(
                "group absolute -translate-x-1/2 -translate-y-1/2 transition",
                active ? "opacity-100" : "pointer-events-none opacity-15"
              )}
              style={{ left: `${x}%`, top: `${y}%` }}
              title={p.name}
            >
              <span
                className={cn(
                  "block rounded-full ring-2 ring-black/40 transition-transform group-hover:scale-150",
                  isSel && "scale-150 animate-pulse-ring"
                )}
                style={{
                  width: isSel ? 14 : 10,
                  height: isSel ? 14 : 10,
                  background: threatColor(p.trustScore),
                }}
              />
              {isSel && (
                <span className="absolute left-1/2 top-full mt-1 -translate-x-1/2 whitespace-nowrap rounded-lg border border-white/10 bg-base-850 px-2 py-1 text-[11px] text-white shadow-card">
                  {p.name} · tehdit {100 - p.trustScore}
                </span>
              )}
            </button>
          );
        })}

        {/* Üst bilgi */}
        <div className="absolute left-3 top-3 flex items-center gap-2 rounded-xl border border-white/10 bg-base-950/70 px-3 py-1.5 text-xs text-slate-300 backdrop-blur">
          <Icons.map size={14} className="text-brand-300" />
          {players.length}/{maxSlots} çevrimiçi
        </div>
        <div className="absolute bottom-3 left-3 rounded-lg border border-amber-500/20 bg-amber-500/10 px-2.5 py-1 text-[11px] text-amber-200">
          Konumlar temsilidir — canlı koordinatlar oyun içi entegrasyonla gelecek
        </div>
      </div>

      {/* Oyuncu paneli */}
      <div className="flex flex-col rounded-2xl border border-white/5 bg-base-850/60">
        <div className="border-b border-white/5 p-3">
          <div className="mb-2 flex items-center justify-between">
            <span className="flex items-center gap-2 text-sm font-semibold text-white">
              <Icons.users size={16} /> Oyuncular
              <span className="rounded-md bg-white/10 px-1.5 py-0.5 text-[10px]">{filtered.length}</span>
            </span>
          </div>
          <div className="relative">
            <Icons.search size={14} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-500" />
            <input
              className="input h-9 pl-9 text-sm"
              placeholder="Ad veya lisans…"
              value={query}
              onChange={(e) => setQuery(e.target.value)}
            />
          </div>
          <label className="mt-2 flex cursor-pointer items-center gap-2 text-xs text-slate-400">
            <input
              type="checkbox"
              checked={onlyThreats}
              onChange={(e) => setOnlyThreats(e.target.checked)}
              className="h-3.5 w-3.5 rounded border-white/20 bg-base-900"
            />
            Sadece potansiyel tehditler
          </label>
        </div>
        <div className="max-h-[480px] flex-1 overflow-y-auto p-2">
          {filtered.length === 0 ? (
            <p className="py-8 text-center text-sm text-slate-500">Eşleşen oyuncu yok</p>
          ) : (
            filtered.map((p) => (
              <button
                key={p.id}
                onClick={() => setSelected(p.id)}
                className={cn(
                  "flex w-full items-center gap-3 rounded-xl px-2.5 py-2 text-left transition hover:bg-white/5",
                  selected === p.id && "bg-brand-500/10 ring-1 ring-inset ring-brand-500/30"
                )}
              >
                <span className="h-2.5 w-2.5 shrink-0 rounded-full" style={{ background: threatColor(p.trustScore) }} />
                <span className="min-w-0 flex-1">
                  <span className="block truncate text-sm text-slate-200">{p.name}</span>
                  <span className="block text-[11px] text-slate-500">
                    {Math.round(p.playtimeSec / 3600)}s oynama
                  </span>
                </span>
                <span className="shrink-0 text-xs font-semibold text-slate-400">
                  {100 - p.trustScore}
                </span>
              </button>
            ))
          )}
        </div>
      </div>
    </div>
  );
}
