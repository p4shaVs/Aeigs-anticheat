"use client";

import { useEffect, useMemo, useRef, useState } from "react";
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

const WORLD = { minX: -4000, maxX: 4500, topY: 8000, botY: -4000 };
function worldToPct(x: number, y: number) {
  const px = ((x - WORLD.minX) / (WORLD.maxX - WORLD.minX)) * 100;
  const py = ((WORLD.topY - y) / (WORLD.topY - WORLD.botY)) * 100;
  return { x: Math.max(1, Math.min(99, px)), y: Math.max(1, Math.min(99, py)) };
}
function fallbackPos(id: string) {
  let h1 = 0, h2 = 0;
  for (let i = 0; i < id.length; i++) {
    h1 = (h1 * 31 + id.charCodeAt(i)) % 100000;
    h2 = (h2 * 17 + id.charCodeAt(i) * 7) % 100000;
  }
  return { x: 25 + (h1 % 55), y: 25 + (h2 % 55) };
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

type ViewMode = "iso" | "top" | "city";
type FilterMode = "heat" | "risky" | "cluster";

const VIEW_TRANSFORM: Record<ViewMode, string> = {
  iso: "rotateX(52deg) rotateZ(0deg) scale(0.92)",
  top: "rotateX(0deg) scale(1)",
  city: "rotateX(54deg) rotateZ(0deg) scale(1.7) translate(6%, -14%)",
};

export function MapView({ serverId, players, maxSlots }: { serverId: string; players: MapPlayer[]; maxSlots: number }) {
  const router = useRouter();
  const [view, setView] = useState<ViewMode>("iso");
  const [mode, setMode] = useState<FilterMode>("cluster");
  const [selected, setSelected] = useState<string | null>(null);
  const [query, setQuery] = useState("");
  const [live, setLive] = useState(true);
  const [minTrust, setMinTrust] = useState(0);
  const [maxTrust, setMaxTrust] = useState(100);
  const [maxPlaytimeH, setMaxPlaytimeH] = useState(24);
  const [recentOnly, setRecentOnly] = useState(false);
  const [newOnly, setNewOnly] = useState(false);
  const [region, setRegion] = useState<null | { x1: number; y1: number; x2: number; y2: number }>(null);
  const [drawing, setDrawing] = useState(false);
  const planeRef = useRef<HTMLDivElement>(null);
  const mapTile = process.env.NEXT_PUBLIC_MAP_TILE ?? "";

  useEffect(() => {
    if (!live) return;
    const t = setInterval(() => router.refresh(), 5000);
    return () => clearInterval(t);
  }, [live, router]);

  const filtered = useMemo(() => {
    const q = query.toLowerCase();
    return players.filter((p) => {
      if (p.trustScore < minTrust || p.trustScore > maxTrust) return false;
      const ph = p.playtimeSec / 3600;
      if (maxPlaytimeH < 24 && ph > maxPlaytimeH) return false;
      if (newOnly && ph > 5) return false;
      if (mode === "risky" && p.trustScore >= 40) return false;
      if (q && !(p.name.toLowerCase().includes(q) || (p.license ?? "").toLowerCase().includes(q))) return false;
      return true;
    });
  }, [players, query, minTrust, maxTrust, maxPlaytimeH, newOnly, mode]);

  function coordOf(p: MapPlayer) {
    if (p.posX != null && p.posY != null) return worldToPct(p.posX, p.posY);
    return fallbackPos(p.id);
  }
  function inRegion(x: number, y: number) {
    if (!region) return true;
    return x >= Math.min(region.x1, region.x2) && x <= Math.max(region.x1, region.x2) &&
      y >= Math.min(region.y1, region.y2) && y <= Math.max(region.y1, region.y2);
  }

  const shown = filtered.filter((p) => { const c = coordOf(p); return inRegion(c.x, c.y); });
  const shownIds = new Set(shown.map((p) => p.id));
  const sel = players.find((p) => p.id === selected) ?? null;

  // Bölge çizimi (drag)
  function planePoint(e: React.MouseEvent) {
    const el = planeRef.current;
    if (!el) return { x: 50, y: 50 };
    const r = el.getBoundingClientRect();
    return { x: ((e.clientX - r.left) / r.width) * 100, y: ((e.clientY - r.top) / r.height) * 100 };
  }

  return (
    <div className="grid gap-4 lg:grid-cols-[1fr_340px]">
      {/* 3D Harita */}
      <div className="relative overflow-hidden rounded-2xl border border-white/10 bg-gradient-to-b from-[#1b3a5c] via-[#12233a] to-[#0a1119]"
        style={{ aspectRatio: "10 / 9", perspective: "1400px" }}>
        {/* Görünüm anahtarları */}
        <div className="absolute right-3 top-3 z-30 flex items-center gap-0.5 rounded-xl border border-white/10 bg-base-950/70 p-1 backdrop-blur">
          {([["iso", "İzometrik"], ["top", "Yukarıdan aşağıya"], ["city", "Şehir"]] as [ViewMode, string][]).map(([k, label]) => (
            <button key={k} onClick={() => setView(k)}
              className={cn("rounded-lg px-3 py-1.5 text-xs font-medium transition", view === k ? "bg-white/10 text-white" : "text-slate-400 hover:text-slate-200")}>
              {label}
            </button>
          ))}
        </div>
        <div className="absolute left-3 top-3 z-30 flex items-center gap-2 rounded-xl border border-white/10 bg-base-950/70 px-3 py-1.5 text-xs text-slate-300 backdrop-blur">
          <Icons.map size={14} className="text-brand-300" /> {shown.length}/{maxSlots} çevrimiçi
        </div>
        <button onClick={() => setLive((l) => !l)}
          className={cn("absolute bottom-3 left-3 z-30 flex items-center gap-1.5 rounded-xl border px-3 py-1.5 text-xs backdrop-blur transition",
            live ? "border-emerald-500/30 bg-emerald-500/10 text-emerald-300" : "border-white/10 bg-base-950/70 text-slate-400")}>
          <span className={cn("h-1.5 w-1.5 rounded-full", live && "animate-pulse bg-emerald-400")} /> {live ? "CANLI" : "Duraklatıldı"}
        </button>

        {/* 3D düzlem */}
        <div className="absolute inset-0 grid place-items-center" style={{ transformStyle: "preserve-3d" }}>
          <div
            ref={planeRef}
            className="relative h-[80%] w-[80%] rounded-xl transition-transform duration-700 ease-out"
            style={{ transform: VIEW_TRANSFORM[view], transformStyle: "preserve-3d", boxShadow: "0 60px 80px -20px rgba(0,0,0,0.7)" }}
            onMouseDown={(e) => { if (drawing) { const p = planePoint(e); setRegion({ x1: p.x, y1: p.y, x2: p.x, y2: p.y }); } }}
            onMouseMove={(e) => { if (drawing && region) { const p = planePoint(e); setRegion((r) => r && ({ ...r, x2: p.x, y2: p.y })); } }}
            onMouseUp={() => { if (drawing) setDrawing(false); }}
          >
            {/* Zemin: gerçek harita dokusu (varsa) veya stilize Los Santos */}
            {mapTile ? (
              // eslint-disable-next-line @next/next/no-img-element
              <img src={mapTile} alt="harita" className="absolute inset-0 h-full w-full rounded-xl object-cover" />
            ) : (
              <LosSantos />
            )}
            {/* Yükseklik hissi: dağ gölgesi */}
            <div className="pointer-events-none absolute left-[46%] top-[6%] h-[34%] w-[40%] rounded-[50%] bg-gradient-to-b from-white/10 to-transparent blur-2xl" />

            {/* Bölge dikdörtgeni */}
            {region && (
              <div className="pointer-events-none absolute border-2 border-brand-400/70 bg-brand-400/10"
                style={{ left: `${Math.min(region.x1, region.x2)}%`, top: `${Math.min(region.y1, region.y2)}%`,
                  width: `${Math.abs(region.x2 - region.x1)}%`, height: `${Math.abs(region.y2 - region.y1)}%` }} />
            )}

            {/* Isı haritası blobları */}
            {mode === "heat" && shown.map((p) => {
              const { x, y } = coordOf(p);
              return <span key={"h" + p.id} className="pointer-events-none absolute -translate-x-1/2 -translate-y-1/2 rounded-full blur-md"
                style={{ left: `${x}%`, top: `${y}%`, width: 42, height: 42, background: threatColor(p.trustScore), opacity: 0.5 }} />;
            })}

            {/* Marker pinleri (kameraya dik dururlar) */}
            {players.map((p) => {
              const { x, y } = coordOf(p);
              const active = shownIds.has(p.id);
              const isSel = selected === p.id;
              return (
                <button key={p.id} onClick={() => setSelected(isSel ? null : p.id)}
                  className={cn("group absolute -translate-x-1/2 -translate-y-1/2 transition-all duration-700",
                    active ? "opacity-100" : "pointer-events-none opacity-0")}
                  style={{ left: `${x}%`, top: `${y}%`, transformStyle: "preserve-3d" }} title={p.name}>
                  <span className="block origin-bottom" style={{ transform: view === "top" ? "none" : "rotateX(-52deg)" }}>
                    {mode !== "heat" && (
                      <span className={cn("block rounded-full ring-2 ring-black/50 transition-transform group-hover:scale-150", isSel && "scale-[1.6] animate-pulse-ring")}
                        style={{ width: isSel ? 13 : 9, height: isSel ? 13 : 9, background: threatColor(p.trustScore),
                          boxShadow: `0 0 10px ${threatColor(p.trustScore)}` }} />
                    )}
                    {isSel && (
                      <span className="absolute left-1/2 top-full mt-1 -translate-x-1/2 whitespace-nowrap rounded-lg border border-white/10 bg-base-850 px-2 py-1 text-[11px] text-white shadow-card">
                        {p.name}
                      </span>
                    )}
                  </span>
                </button>
              );
            })}
          </div>
        </div>
      </div>

      {/* Sağ panel: filtreler + oyuncu listesi */}
      <div className="flex flex-col gap-3">
        <div className="rounded-2xl border border-white/5 bg-base-850/60 p-3">
          <div className="mb-2 flex items-center justify-between">
            <span className="text-sm font-semibold text-white">Oyuncular</span>
            <span className="text-xs text-slate-500">{shown.length} gösterildi</span>
          </div>
          <p className="mb-3 text-xs text-slate-500">Profili incelemek için oyuncuya tıklayın.</p>

          {/* Mod radyoları */}
          <div className="mb-3 flex gap-1.5">
            {([["heat", "Isı haritası"], ["risky", "Sadece riskli"], ["cluster", "Tıkanma"]] as [FilterMode, string][]).map(([k, label]) => (
              <button key={k} onClick={() => setMode(k)}
                className={cn("flex-1 rounded-lg border px-2 py-1.5 text-[11px] font-medium transition",
                  mode === k ? "border-emerald-500/40 bg-emerald-500/10 text-emerald-300" : "border-white/10 text-slate-400 hover:bg-white/5")}>
                {label}
              </button>
            ))}
          </div>

          <div className="relative mb-3">
            <Icons.search size={14} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-500" />
            <input className="input h-9 pl-9 text-sm" placeholder="Oyuncu veya Discord'da arama yapın…" value={query} onChange={(e) => setQuery(e.target.value)} />
          </div>

          <div className="mb-3 flex gap-1.5">
            <button onClick={() => { setDrawing(true); setRegion(null); }}
              className={cn("flex flex-1 items-center justify-center gap-1.5 rounded-lg border px-3 py-2 text-xs font-medium transition",
                drawing ? "border-brand-500/50 bg-brand-500/10 text-white" : "border-white/10 text-slate-300 hover:bg-white/5")}>
              <Icons.map size={14} /> Bölge seçin
            </button>
            <button onClick={() => { setRegion(null); setDrawing(false); }} title="Bölgeyi temizle"
              className="grid h-auto w-10 place-items-center rounded-lg border border-white/10 text-slate-400 hover:bg-white/5">
              <Icons.x size={14} />
            </button>
          </div>

          {/* İtibar puanı aralığı */}
          <RangeRow label="İtibar puanı" min={0} max={100} lo={minTrust} hi={maxTrust}
            onLo={setMinTrust} onHi={setMaxTrust} />
          {/* Oyun zamanı */}
          <div className="mt-3">
            <div className="mb-1 flex items-center justify-between text-[11px]">
              <span className="text-slate-400">Oyun zamanı</span>
              <span className="font-mono text-slate-500">0s – {maxPlaytimeH >= 24 ? "24s+" : `${maxPlaytimeH}s`}</span>
            </div>
            <input type="range" min={1} max={24} value={maxPlaytimeH} onChange={(e) => setMaxPlaytimeH(Number(e.target.value))} className="ac-range w-full" />
          </div>

          <div className="mt-3 flex gap-1.5">
            <button onClick={() => setRecentOnly((v) => !v)}
              className={cn("flex-1 rounded-lg border px-2 py-1.5 text-[11px] transition",
                recentOnly ? "border-brand-500/40 bg-brand-500/10 text-white" : "border-white/10 text-slate-400 hover:bg-white/5")}>
              Yakın zamanda katıldı
            </button>
            <button onClick={() => setNewOnly((v) => !v)}
              className={cn("flex-1 rounded-lg border px-2 py-1.5 text-[11px] transition",
                newOnly ? "border-brand-500/40 bg-brand-500/10 text-white" : "border-white/10 text-slate-400 hover:bg-white/5")}>
              Yeni oyuncular
            </button>
          </div>
        </div>

        {sel && <PlayerDetail serverId={serverId} p={sel} />}

        <div className="max-h-[300px] overflow-y-auto rounded-2xl border border-white/5 bg-base-850/60 p-2">
          {shown.length === 0 ? (
            <p className="py-8 text-center text-sm text-slate-500">Eşleşen oyuncu yok</p>
          ) : (
            shown.map((p) => (
              <button key={p.id} onClick={() => setSelected(p.id)}
                className={cn("flex w-full items-center gap-3 rounded-xl px-2.5 py-2 text-left transition hover:bg-white/5",
                  selected === p.id && "bg-brand-500/10 ring-1 ring-inset ring-brand-500/30")}>
                <span className="h-2.5 w-2.5 shrink-0 rounded-full" style={{ background: threatColor(p.trustScore) }} />
                <span className="min-w-0 flex-1">
                  <span className="block truncate text-sm text-slate-200">{p.name}</span>
                  <span className="block text-[11px] text-slate-500">
                    {p.activity ? ACTIVITY_LABEL[p.activity] ?? p.activity : `${Math.round(p.playtimeSec / 3600)}s oynama`}
                  </span>
                </span>
                {p.health != null && <span className="shrink-0 text-[11px] text-rose-300">{Math.max(0, p.health - 100)}hp</span>}
              </button>
            ))
          )}
        </div>
      </div>
    </div>
  );
}

function RangeRow({ label, min, max, lo, hi, onLo, onHi }: {
  label: string; min: number; max: number; lo: number; hi: number; onLo: (n: number) => void; onHi: (n: number) => void;
}) {
  return (
    <div>
      <div className="mb-1 flex items-center justify-between text-[11px]">
        <span className="text-slate-400">{label}</span>
        <span className="font-mono text-slate-500">{lo} – {hi}</span>
      </div>
      <div className="flex items-center gap-2">
        <input type="range" min={min} max={max} value={lo} onChange={(e) => onLo(Math.min(Number(e.target.value), hi))} className="ac-range w-full" />
        <input type="range" min={min} max={max} value={hi} onChange={(e) => onHi(Math.max(Number(e.target.value), lo))} className="ac-range w-full" />
      </div>
    </div>
  );
}

function PlayerDetail({ serverId, p }: { serverId: string; p: MapPlayer }) {
  const [ssUrl, setSsUrl] = useState<string | null>(null);
  const [ssStatus, setSsStatus] = useState("");
  const [busy, setBusy] = useState(false);
  const hp = p.health != null ? Math.max(0, Math.min(100, p.health - 100)) : null;

  async function requestScreenshot() {
    setBusy(true); setSsStatus("İstek gönderildi…"); setSsUrl(null);
    try {
      await fetch(`/api/servers/${serverId}/screenshot`, {
        method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ playerId: p.id }),
      });
      for (let i = 0; i < 18; i++) {
        await new Promise((r) => setTimeout(r, 1500));
        const res = await fetch(`/api/servers/${serverId}/screenshot?playerId=${p.id}`);
        const json = await res.json();
        if (json.ok && json.data.status === "DONE" && json.data.url) { setSsUrl(json.data.url); setSsStatus(""); return; }
        if (json.ok && json.data.status === "FAILED") { setSsStatus("Alınamadı — screenshot-basic kurulu mu?"); return; }
      }
      setSsStatus("Zaman aşımı");
    } finally { setBusy(false); }
  }

  return (
    <div className="rounded-2xl border border-white/10 bg-base-850/80 p-4">
      <div className="mb-3 flex items-center justify-between">
        <span className="flex items-center gap-2 font-semibold text-white">
          <span className="h-2.5 w-2.5 rounded-full" style={{ background: threatColor(p.trustScore) }} /> {p.name}
        </span>
        <span className="text-xs text-slate-500">tehdit {100 - p.trustScore}</span>
      </div>
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
      <div className="overflow-hidden rounded-xl border border-white/10 bg-base-950">
        {ssUrl ? (
          // eslint-disable-next-line @next/next/no-img-element
          <img src={ssUrl} alt="ekran" className="aspect-video w-full object-cover" />
        ) : (
          <div className="grid aspect-video place-items-center text-center text-xs text-slate-500">{ssStatus || "Ekran görüntüsü için iste"}</div>
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

function LosSantos() {
  return (
    <svg viewBox="0 0 100 100" className="absolute inset-0 h-full w-full rounded-xl" preserveAspectRatio="none">
      <defs>
        <linearGradient id="land3d" x1="0" y1="0" x2="1" y2="1">
          <stop offset="0%" stopColor="#3a4a34" />
          <stop offset="55%" stopColor="#2b3a28" />
          <stop offset="100%" stopColor="#20301f" />
        </linearGradient>
        <radialGradient id="mtn" cx="55%" cy="26%" r="30%">
          <stop offset="0%" stopColor="#6b7d5c" />
          <stop offset="100%" stopColor="#33422c" />
        </radialGradient>
      </defs>
      <rect width="100" height="100" fill="#12283f" />
      <path d="M28 8 L58 5 L76 14 L84 30 L88 48 L82 64 L88 78 L80 94 L58 99 L42 96 L38 84 L28 80 L22 66 L28 52 L20 42 L26 24 Z"
        fill="url(#land3d)" stroke="#485a3c" strokeWidth="0.5" />
      <ellipse cx="58" cy="26" rx="20" ry="14" fill="url(#mtn)" opacity="0.9" />
      <path d="M46 90 L58 88 L62 97 L50 98 Z" fill="#16241c" />
      <g stroke="#556644" strokeWidth="0.6" fill="none" opacity="0.7">
        <path d="M34 16 L70 22 L80 46 L72 72 L64 96" />
        <path d="M28 42 L52 48 L80 54" />
      </g>
      <g stroke="#3f5238" strokeWidth="0.22" opacity="0.7">
        {Array.from({ length: 8 }).map((_, i) => <line key={"h" + i} x1={48} y1={66 + i * 4} x2={74} y2={62 + i * 4} />)}
        {Array.from({ length: 7 }).map((_, i) => <line key={"v" + i} x1={50 + i * 3.4} y1={66} x2={52 + i * 3.4} y2={96} />)}
      </g>
    </svg>
  );
}
