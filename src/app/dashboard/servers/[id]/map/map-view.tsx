"use client";

import { useEffect, useMemo, useState } from "react";
import { useRouter } from "next/navigation";
import { Icons } from "@/components/icons";
import { cn } from "@/lib/utils";

export interface MapPlayer {
  id: string;
  name: string;
  trustScore: number;
  license: string | null;
  playtimeSec: number;
  posX: number | null;
  posY: number | null;
  heading: number | null;
  health: number | null;
  armor: number | null;
  activity: string | null;
  ping: number | null;
}

// GTA V dünya koordinatlarını (yaklaşık) harita yüzdesine çevirir.
const WORLD = { minX: -4000, maxX: 4500, topY: 8000, botY: -4000 };
function worldToPct(x: number, y: number) {
  const px = ((x - WORLD.minX) / (WORLD.maxX - WORLD.minX)) * 100;
  const py = ((WORLD.topY - y) / (WORLD.topY - WORLD.botY)) * 100;
  return { x: Math.max(2, Math.min(98, px)), y: Math.max(2, Math.min(98, py)) };
}

// Canlı koordinatı olmayan oyuncu için deterministik yedek konum.
function fallbackPos(id: string) {
  let h1 = 0, h2 = 0;
  for (let i = 0; i < id.length; i++) {
    h1 = (h1 * 31 + id.charCodeAt(i)) % 100000;
    h2 = (h2 * 17 + id.charCodeAt(i) * 7) % 100000;
  }
  return { x: 20 + (h1 % 60), y: 20 + (h2 % 60) };
}

function threatColor(score: number) {
  if (score >= 70) return "#10b981";
  if (score >= 40) return "#f59e0b";
  return "#f43f5e";
}

const ACTIVITY_LABEL: Record<string, string> = {
  driving: "Araçta", walking: "Yürüyor", shooting: "Ateş ediyor",
  swimming: "Yüzüyor", parachuting: "Paraşütte", idle: "Bekliyor",
  falling: "Düşüyor", ragdoll: "Yerde",
};

export function MapView({ serverId, players, maxSlots }: { serverId: string; players: MapPlayer[]; maxSlots: number }) {
  const router = useRouter();
  const [selected, setSelected] = useState<string | null>(null);
  const [query, setQuery] = useState("");
  const [onlyThreats, setOnlyThreats] = useState(false);
  const [live, setLive] = useState(true);

  // Canlı mod: her 5 sn'de sunucu bileşenini yeniden çeker (yeni konumlar gelir).
  useEffect(() => {
    if (!live) return;
    const t = setInterval(() => router.refresh(), 5000);
    return () => clearInterval(t);
  }, [live, router]);

  const filtered = useMemo(() => {
    const q = query.toLowerCase();
    return players.filter((p) => {
      if (onlyThreats && p.trustScore >= 40) return false;
      if (!q) return true;
      return p.name.toLowerCase().includes(q) || (p.license ?? "").toLowerCase().includes(q);
    });
  }, [players, query, onlyThreats]);

  const shownIds = new Set(filtered.map((p) => p.id));
  const sel = players.find((p) => p.id === selected) ?? null;
  const withCoords = players.filter((p) => p.posX != null && p.posY != null).length;

  function coordOf(p: MapPlayer) {
    if (p.posX != null && p.posY != null) return worldToPct(p.posX, p.posY);
    return fallbackPos(p.id);
  }

  return (
    <div className="grid gap-4 lg:grid-cols-[1fr_340px]">
      {/* Harita */}
      <div className="relative aspect-[10/11] overflow-hidden rounded-2xl border border-white/10 bg-[#0b1220]">
        <LosSantos />

        {/* Marker'lar */}
        {players.map((p) => {
          const { x, y } = coordOf(p);
          const active = shownIds.has(p.id);
          const isSel = selected === p.id;
          return (
            <button
              key={p.id}
              onClick={() => setSelected(isSel ? null : p.id)}
              className={cn(
                "group absolute -translate-x-1/2 -translate-y-1/2 transition-all duration-700 ease-out",
                active ? "opacity-100" : "pointer-events-none opacity-10"
              )}
              style={{ left: `${x}%`, top: `${y}%` }}
              title={p.name}
            >
              {/* yön oku */}
              {p.heading != null && (
                <span
                  className="absolute left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2"
                  style={{ transform: `translate(-50%,-50%) rotate(${p.heading}deg)` }}
                >
                  <span
                    className="block h-0 w-0 border-x-[4px] border-b-[7px] border-x-transparent"
                    style={{ borderBottomColor: threatColor(p.trustScore), marginTop: -12 }}
                  />
                </span>
              )}
              <span
                className={cn(
                  "block rounded-full ring-2 ring-black/50 transition-transform group-hover:scale-150",
                  isSel && "scale-150 animate-pulse-ring"
                )}
                style={{ width: isSel ? 14 : 10, height: isSel ? 14 : 10, background: threatColor(p.trustScore) }}
              />
              {isSel && (
                <span className="absolute left-1/2 top-full mt-1 -translate-x-1/2 whitespace-nowrap rounded-lg border border-white/10 bg-base-850 px-2 py-1 text-[11px] text-white shadow-card">
                  {p.name}
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
        <button
          onClick={() => setLive((l) => !l)}
          className={cn(
            "absolute right-3 top-3 flex items-center gap-1.5 rounded-xl border px-3 py-1.5 text-xs backdrop-blur transition",
            live ? "border-emerald-500/30 bg-emerald-500/10 text-emerald-300" : "border-white/10 bg-base-950/70 text-slate-400"
          )}
        >
          <span className={cn("h-1.5 w-1.5 rounded-full", live && "animate-pulse bg-emerald-400")} />
          {live ? "CANLI" : "Duraklatıldı"}
        </button>
        {withCoords === 0 && (
          <div className="absolute bottom-3 left-3 rounded-lg border border-amber-500/20 bg-amber-500/10 px-2.5 py-1 text-[11px] text-amber-200">
            Canlı koordinat bekleniyor — resource bağlandığında oyuncular gerçek konumlarına yerleşir
          </div>
        )}
      </div>

      {/* Sağ panel: seçili oyuncu detayı + liste */}
      <div className="flex flex-col gap-4">
        {sel && <PlayerDetail serverId={serverId} p={sel} />}

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
              <input className="input h-9 pl-9 text-sm" placeholder="Ad veya lisans…" value={query} onChange={(e) => setQuery(e.target.value)} />
            </div>
            <label className="mt-2 flex cursor-pointer items-center gap-2 text-xs text-slate-400">
              <input type="checkbox" checked={onlyThreats} onChange={(e) => setOnlyThreats(e.target.checked)} className="h-3.5 w-3.5 rounded border-white/20 bg-base-900" />
              Sadece potansiyel tehditler
            </label>
          </div>
          <div className="max-h-[360px] flex-1 overflow-y-auto p-2">
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
                      {p.activity ? ACTIVITY_LABEL[p.activity] ?? p.activity : `${Math.round(p.playtimeSec / 3600)}s oynama`}
                    </span>
                  </span>
                  {p.health != null && <HealthPip health={p.health} armor={p.armor} />}
                </button>
              ))
            )}
          </div>
        </div>
      </div>
    </div>
  );
}

function HealthPip({ health, armor }: { health: number; armor: number | null }) {
  return (
    <span className="flex shrink-0 flex-col items-end gap-0.5">
      <span className="flex items-center gap-1 text-[10px] text-rose-300">
        <Icons.activity size={10} /> {Math.max(0, health - 100)}
      </span>
      {armor != null && armor > 0 && (
        <span className="flex items-center gap-1 text-[10px] text-brand-300">
          <Icons.shield size={10} /> {armor}
        </span>
      )}
    </span>
  );
}

function PlayerDetail({ serverId, p }: { serverId: string; p: MapPlayer }) {
  const [ssStatus, setSsStatus] = useState<string>("");
  const [ssUrl, setSsUrl] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);
  const hp = p.health != null ? Math.max(0, Math.min(100, p.health - 100)) : null;

  async function requestScreenshot() {
    setBusy(true);
    setSsStatus("İstek gönderildi, bekleniyor…");
    setSsUrl(null);
    try {
      await fetch(`/api/servers/${serverId}/screenshot`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ playerId: p.id }),
      });
      // Sonucu 20 sn boyunca sorgula
      for (let i = 0; i < 20; i++) {
        await new Promise((r) => setTimeout(r, 1500));
        const res = await fetch(`/api/servers/${serverId}/screenshot?playerId=${p.id}`);
        const json = await res.json();
        if (json.ok && json.data.status === "DONE" && json.data.url) {
          setSsUrl(json.data.url);
          setSsStatus("");
          break;
        }
        if (json.ok && json.data.status === "FAILED") {
          setSsStatus("Alınamadı — screenshot-basic kurulu mu?");
          break;
        }
      }
      if (!ssUrl) setSsStatus((s) => s || "Yanıt yok (zaman aşımı)");
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="rounded-2xl border border-white/10 bg-base-850/80 p-4">
      <div className="mb-3 flex items-center justify-between">
        <span className="flex items-center gap-2 font-semibold text-white">
          <span className="h-2.5 w-2.5 rounded-full" style={{ background: threatColor(p.trustScore) }} />
          {p.name}
        </span>
        <span className="text-xs text-slate-500">tehdit {100 - p.trustScore}</span>
      </div>

      {/* Can / Kalkan barları */}
      <div className="mb-3 space-y-2">
        <Bar label="Can" value={hp} color="#f43f5e" icon="activity" />
        <Bar label="Kalkan" value={p.armor} color="#3b82f6" icon="shield" />
      </div>

      <div className="mb-3 grid grid-cols-2 gap-2 text-xs">
        <Info label="Aktivite" value={p.activity ? ACTIVITY_LABEL[p.activity] ?? p.activity : "—"} />
        <Info label="Ping" value={p.ping != null ? `${p.ping} ms` : "—"} />
        <Info label="Konum" value={p.posX != null ? `${Math.round(p.posX)}, ${Math.round(p.posY!)}` : "—"} />
        <Info label="Oynama" value={`${Math.round(p.playtimeSec / 3600)} saat`} />
      </div>

      {/* Canlı ekran */}
      <div className="overflow-hidden rounded-xl border border-white/10 bg-base-950">
        {ssUrl ? (
          // eslint-disable-next-line @next/next/no-img-element
          <img src={ssUrl} alt="ekran" className="aspect-video w-full object-cover" />
        ) : (
          <div className="grid aspect-video place-items-center text-center text-xs text-slate-500">
            {ssStatus || "Ekran görüntüsü için iste"}
          </div>
        )}
      </div>
      <button className="btn-secondary mt-2 w-full" onClick={requestScreenshot} disabled={busy}>
        <Icons.eye size={15} /> {busy ? "Alınıyor…" : "Canlı Ekranı İste"}
      </button>
    </div>
  );
}

function Bar({ label, value, color, icon }: { label: string; value: number | null; color: string; icon: "activity" | "shield" }) {
  const Icon = Icons[icon];
  const v = value ?? 0;
  return (
    <div>
      <div className="mb-1 flex items-center justify-between text-[11px]">
        <span className="flex items-center gap-1 text-slate-400"><Icon size={11} /> {label}</span>
        <span className="text-slate-300">{value != null ? v : "—"}</span>
      </div>
      <div className="h-1.5 overflow-hidden rounded-full bg-white/5">
        <div className="h-full rounded-full transition-all" style={{ width: `${Math.min(100, v)}%`, background: color }} />
      </div>
    </div>
  );
}

function Info({ label, value }: { label: string; value: string }) {
  return (
    <div className="rounded-lg bg-white/5 px-2.5 py-1.5">
      <div className="text-[10px] uppercase tracking-wide text-slate-500">{label}</div>
      <div className="truncate font-mono text-slate-300">{value}</div>
    </div>
  );
}

// Stilize Los Santos haritası (temsili silüet + otoyollar + şehir ızgarası).
function LosSantos() {
  return (
    <svg viewBox="0 0 100 110" className="absolute inset-0 h-full w-full" preserveAspectRatio="none">
      <defs>
        <radialGradient id="sea" cx="50%" cy="45%" r="75%">
          <stop offset="0%" stopColor="#132033" />
          <stop offset="100%" stopColor="#0a111d" />
        </radialGradient>
        <linearGradient id="land" x1="0" y1="0" x2="1" y2="1">
          <stop offset="0%" stopColor="#1c2b1f" />
          <stop offset="100%" stopColor="#15241c" />
        </linearGradient>
      </defs>
      <rect width="100" height="110" fill="url(#sea)" />
      {/* Ana kara — kuzeyde dağlar, güneydoğuda şehir */}
      <path
        d="M30 6 L58 4 L74 12 L82 26 L86 44 L80 60 L86 74 L80 92 L60 104 L44 100 L40 86 L30 82 L24 68 L30 54 L22 44 L26 28 Z"
        fill="url(#land)" stroke="#2c3f31" strokeWidth="0.6"
      />
      {/* İç ada / liman */}
      <path d="M46 92 L58 90 L62 98 L50 100 Z" fill="#12201a" stroke="#25382b" strokeWidth="0.4" />
      {/* Otoyollar */}
      <g stroke="#3a4d3d" strokeWidth="0.7" fill="none" opacity="0.8">
        <path d="M34 14 L70 20 L80 44 L72 70 L66 96" />
        <path d="M28 40 L52 46 L78 52" />
        <path d="M52 46 L56 88" />
        <path d="M40 84 L64 78" />
      </g>
      {/* Şehir ızgarası (güneydoğu) */}
      <g stroke="#31463a" strokeWidth="0.28" opacity="0.7">
        {Array.from({ length: 7 }).map((_, i) => (
          <line key={"h" + i} x1={50} y1={70 + i * 4.5} x2={72} y2={66 + i * 4.5} />
        ))}
        {Array.from({ length: 6 }).map((_, i) => (
          <line key={"v" + i} x1={52 + i * 3.4} y1={70} x2={54 + i * 3.4} y2={98} />
        ))}
      </g>
    </svg>
  );
}
