"use client";

import { useEffect, useRef } from "react";
import { Icons } from "./icons";

/**
 * Mouse hareketine tepki veren 3B hero görseli.
 * - İmleç konumuna göre panoyu eğer (rotateX/rotateY)
 * - Katmanlar farklı derinlikte (translateZ) → parallax
 * - Arkadaki ışık imleci takip eder
 * Not: Buradaki pano, Aeigs panelinin stilize bir önizlemesidir. Kendi PNG
 * görselini kullanmak istersen /public içine koyup <img> ile değiştirebilirsin.
 */
export function HeroParallax() {
  const wrapRef = useRef<HTMLDivElement>(null);
  const cardRef = useRef<HTMLDivElement>(null);
  const glowRef = useRef<HTMLDivElement>(null);
  const raf = useRef<number>();

  useEffect(() => {
    const wrapEl = wrapRef.current;
    const cardEl = cardRef.current;
    const glowEl = glowRef.current;
    if (!wrapEl || !cardEl) return;
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) return;

    let tx = 0, ty = 0, cx = 0, cy = 0;

    const schedule = () => {
      if (raf.current) return;
      raf.current = requestAnimationFrame(apply);
    };
    const apply = () => {
      raf.current = undefined;
      cx += (tx - cx) * 0.12;
      cy += (ty - cy) * 0.12;
      const ry = cx * 16;
      const rx = -cy * 14;
      cardEl.style.transform = `perspective(1100px) rotateX(${rx.toFixed(2)}deg) rotateY(${ry.toFixed(2)}deg)`;
      cardEl.style.setProperty("--px", `${(cx * 26).toFixed(1)}px`);
      cardEl.style.setProperty("--py", `${(cy * 26).toFixed(1)}px`);
      if (Math.abs(tx - cx) > 0.001 || Math.abs(ty - cy) > 0.001) schedule();
    };
    const onMove = (e: MouseEvent) => {
      const r = wrapEl.getBoundingClientRect();
      tx = (e.clientX - r.left) / r.width - 0.5;
      ty = (e.clientY - r.top) / r.height - 0.5;
      if (glowEl) {
        glowEl.style.setProperty("--gx", `${e.clientX - r.left}px`);
        glowEl.style.setProperty("--gy", `${e.clientY - r.top}px`);
      }
      schedule();
    };
    const onLeave = () => {
      tx = 0; ty = 0; schedule();
    };

    window.addEventListener("mousemove", onMove);
    wrapEl.addEventListener("mouseleave", onLeave);
    return () => {
      window.removeEventListener("mousemove", onMove);
      wrapEl.removeEventListener("mouseleave", onLeave);
      if (raf.current) cancelAnimationFrame(raf.current);
    };
  }, []);

  return (
    <div ref={wrapRef} className="relative [perspective:1100px]">
      {/* İmleci takip eden ışık */}
      <div
        ref={glowRef}
        className="pointer-events-none absolute inset-0 -z-10 rounded-[2rem] opacity-70"
        style={{
          background:
            "radial-gradient(28rem 28rem at var(--gx,50%) var(--gy,40%), rgba(99,102,241,0.28), transparent 60%)",
        }}
      />

      <div
        ref={cardRef}
        className="relative rounded-2xl border border-white/10 bg-base-850/80 p-3 shadow-card backdrop-blur-xl transition-transform duration-100 [transform-style:preserve-3d] will-change-transform"
      >
        {/* Tarayıcı çubuğu */}
        <div className="mb-3 flex items-center gap-2 px-2 pt-1">
          <span className="h-2.5 w-2.5 rounded-full bg-rose-500/70" />
          <span className="h-2.5 w-2.5 rounded-full bg-amber-500/70" />
          <span className="h-2.5 w-2.5 rounded-full bg-emerald-500/70" />
          <span className="ml-3 rounded-md bg-white/5 px-3 py-1 text-[11px] text-slate-500">
            panel.aeigs.gg/dashboard
          </span>
        </div>

        {/* Stat kartları — derinlikte yüzer */}
        <div
          className="grid grid-cols-3 gap-2"
          style={{ transform: "translateZ(40px) translate(var(--px), var(--py))" }}
        >
          {[
            { l: "ONLINE", v: "256", c: "text-emerald-300", i: "activity" as const },
            { l: "BANS", v: "89", c: "text-rose-300", i: "ban" as const },
            { l: "PLAYERS", v: "15.8K", c: "text-brand-300", i: "users" as const },
          ].map((s) => {
            const Icon = Icons[s.i];
            return (
              <div key={s.l} className="rounded-xl border border-white/5 bg-base-900/70 p-3">
                <div className="flex items-center justify-between">
                  <span className="text-[9px] font-semibold tracking-wider text-slate-500">{s.l}</span>
                  <Icon size={13} className={s.c} />
                </div>
                <div className={`mt-1 text-lg font-bold ${s.c}`}>{s.v}</div>
              </div>
            );
          })}
        </div>

        {/* Grafik */}
        <div
          className="mt-2 rounded-xl border border-white/5 bg-base-900/70 p-3"
          style={{ transform: "translateZ(24px) translate(calc(var(--px)*0.6), calc(var(--py)*0.6))" }}
        >
          <div className="mb-2 flex items-center justify-between">
            <span className="text-[10px] font-semibold text-slate-300">Sunucu Analitiği</span>
            <span className="rounded bg-emerald-500/10 px-1.5 py-0.5 text-[9px] text-emerald-300">CANLI</span>
          </div>
          <div className="flex h-24 items-end gap-1">
            {[40, 55, 48, 66, 60, 78, 70, 88, 82, 72, 90, 100, 86, 70, 92, 80].map((h, i) => (
              <div
                key={i}
                className="flex-1 rounded-t bg-gradient-to-t from-brand-500/25 to-brand-400"
                style={{ height: `${h}%` }}
              />
            ))}
          </div>
        </div>

        {/* Tespit satırı */}
        <div
          className="mt-2 flex items-center justify-between rounded-xl border border-white/5 bg-base-900/70 px-3 py-2"
          style={{ transform: "translateZ(56px) translate(calc(var(--px)*1.3), calc(var(--py)*1.3))" }}
        >
          <div className="flex items-center gap-2">
            <span className="grid h-6 w-6 place-items-center rounded-lg bg-rose-500/15 text-rose-300">
              <Icons.warn size={13} />
            </span>
            <div>
              <div className="text-[11px] font-medium text-slate-200">AimBot Tespit Edildi</div>
              <div className="text-[9px] text-slate-500">Player#2481 · az önce</div>
            </div>
          </div>
          <span className="rounded-md bg-rose-500/10 px-2 py-0.5 text-[9px] font-semibold text-rose-300">
            OTOMATİK BAN
          </span>
        </div>
      </div>

      {/* Yüzen küçük rozet */}
      <div
        className="absolute -left-5 top-1/3 animate-float rounded-2xl border border-white/10 bg-base-850/90 px-3 py-2 shadow-card backdrop-blur"
        style={{ transform: "translateZ(80px)" }}
      >
        <div className="flex items-center gap-2">
          <span className="grid h-8 w-8 place-items-center rounded-lg bg-brand-gradient text-white">
            <Icons.shieldCheck size={16} />
          </span>
          <div>
            <div className="text-[11px] font-bold text-white">99.9%</div>
            <div className="text-[9px] text-slate-500">Tespit oranı</div>
          </div>
        </div>
      </div>
    </div>
  );
}
