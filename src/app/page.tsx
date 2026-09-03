import Link from "next/link";
import { SiteHeader, SiteFooter } from "@/components/site-header";
import { LinkButton, Badge } from "@/components/ui";
import { Icons } from "@/components/icons";
import { Reveal } from "@/components/reveal";
import { HeroParallax } from "@/components/hero-parallax";
import { Faq } from "@/components/faq";

export default function HomePage() {
  return (
    <div className="min-h-screen overflow-x-hidden">
      <SiteHeader />
      <main>
        <Hero />
        <LogoStrip />
        <FeatureRows />
        <StatsBand />
        <Detection />
        <DemoSection />
        <PricingTeaser />
        <FaqSection />
        <CtaBand />
      </main>
      <SiteFooter />
    </div>
  );
}

/* ------------------------------- HERO ---------------------------------- */

function Hero() {
  return (
    <section className="relative">
      <div className="pointer-events-none absolute inset-0 -z-10 bg-grid-faint [background-size:44px_44px] [mask-image:radial-gradient(ellipse_at_top,black,transparent_75%)]" />
      <div className="mx-auto grid max-w-6xl items-center gap-12 px-4 pb-20 pt-16 sm:px-6 lg:grid-cols-2 lg:pt-24">
        <div>
          <div className="mb-5 inline-flex animate-fade-in items-center gap-2 rounded-full border border-white/10 bg-white/5 px-4 py-1.5 text-xs font-medium text-slate-300">
            <span className="flex h-1.5 w-1.5 rounded-full bg-emerald-400 shadow-[0_0_8px] shadow-emerald-400" />
            v4.7 — Yeni tespit motoru yayında
          </div>
          <h1 className="animate-slide-up text-4xl font-extrabold leading-[1.08] tracking-tight text-white sm:text-6xl">
            FiveM için{" "}
            <span className="bg-gradient-to-r from-brand-400 via-brand-300 to-accent-violet bg-clip-text text-transparent">
              en gelişmiş
            </span>{" "}
            anti-cheat
          </h1>
          <p className="mt-6 max-w-xl animate-slide-up text-lg text-slate-400 [animation-delay:80ms]">
            Aimbot, silent aim, injection ve exploit&apos;leri gerçek zamanlı
            yakala. Oyuncuları web panelinden yönet, banla ve tüm sunucunu tek
            yerden kontrol et.
          </p>
          <div className="mt-8 flex animate-slide-up flex-col gap-3 [animation-delay:160ms] sm:flex-row">
            <LinkButton href="/pricing" icon="cart" className="px-6 py-3 text-base">
              Hemen Satın Al
            </LinkButton>
            <LinkButton href="/api/demo" variant="secondary" icon="bolt" className="px-6 py-3 text-base">
              Canlı Demo
            </LinkButton>
          </div>
          <div className="mt-8 flex animate-fade-in flex-wrap items-center gap-x-6 gap-y-2 text-sm text-slate-500 [animation-delay:240ms]">
            <span className="flex items-center gap-1.5">
              <Icons.check size={15} className="text-emerald-400" /> 5 dakikada kurulum
            </span>
            <span className="flex items-center gap-1.5">
              <Icons.check size={15} className="text-emerald-400" /> 7/24 destek
            </span>
            <span className="flex items-center gap-1.5">
              <Icons.check size={15} className="text-emerald-400" /> Lifetime seçeneği
            </span>
          </div>
        </div>

        {/* Mouse ile hareket eden 3B görsel */}
        <div className="animate-scale-in [animation-delay:120ms]">
          <HeroParallax />
        </div>
      </div>
    </section>
  );
}

function LogoStrip() {
  return (
    <section className="border-y border-white/5 bg-base-950/50 py-6">
      <div className="mx-auto flex max-w-6xl flex-wrap items-center justify-center gap-x-10 gap-y-3 px-4 text-slate-600 sm:px-6">
        <span className="text-xs uppercase tracking-widest">Güvenenler</span>
        {["RolePlay TR", "LosSantos", "Vespucci", "Paleto", "Sandy RP", "Mirror Park"].map((n) => (
          <span key={n} className="text-sm font-semibold text-slate-500">{n}</span>
        ))}
      </div>
    </section>
  );
}

/* --------------------------- FEATURE ROWS ------------------------------ */

function FeatureRows() {
  const rows = [
    {
      eyebrow: "Tespit Motoru",
      title: "Bilinen ve bilinmeyen tüm hileler",
      text: "Davranış analizi ve imza tabanlı tespitin birleşimi ile aimbot, silent aim, ESP, godmode ve daha fazlasını sunucu tarafında yakalar.",
      points: ["Client'a güvenmez", "Otomatik ban & kanıt", "Akıllı eşiklerle düşük yanlış pozitif"],
      icon: "shieldCheck" as const,
      mock: <DetectionMock />,
    },
    {
      eyebrow: "Web Panel",
      title: "Sunucunu tarayıcıdan yönet",
      text: "Oyuncular, banlar, canlı harita, analitik ve konsol — hepsi tek modern panelde. Web'den banla, kickle, sorgula.",
      points: ["Canlı oyuncu haritası", "Web'den ban / kick / uyarı", "Oyuncu sorgulama & alt hesap"],
      icon: "globe" as const,
      mock: <PanelMock />,
      reverse: true,
    },
    {
      eyebrow: "Güvenlik Kuralları",
      title: "40+ koruma, tek tıkla aç/kapat",
      text: "Executor, client, health, weapon, entity ve event korumalarını sunucuna göre özelleştir. Değişiklikler anında uygulanır.",
      points: ["Kategorili toggle'lar", "Discord webhook logları", "Lisans bazlı özellikler"],
      icon: "config" as const,
      mock: <RulesMock />,
    },
  ];

  return (
    <section id="features" className="mx-auto max-w-6xl scroll-mt-20 px-4 py-24 sm:px-6">
      <div className="space-y-24">
        {rows.map((r, i) => (
          <div key={i} className="grid items-center gap-10 lg:grid-cols-2">
            <Reveal className={r.reverse ? "lg:order-2" : ""}>
              <span className="section-title text-brand-400">{r.eyebrow}</span>
              <h2 className="mt-3 text-3xl font-bold tracking-tight text-white sm:text-4xl">
                {r.title}
              </h2>
              <p className="mt-4 text-slate-400">{r.text}</p>
              <ul className="mt-6 space-y-3">
                {r.points.map((p) => (
                  <li key={p} className="flex items-center gap-3 text-sm text-slate-300">
                    <span className="grid h-5 w-5 shrink-0 place-items-center rounded-full bg-emerald-500/15 text-emerald-400">
                      <Icons.check size={13} />
                    </span>
                    {p}
                  </li>
                ))}
              </ul>
            </Reveal>
            <Reveal delay={120} className={r.reverse ? "lg:order-1" : ""}>
              {r.mock}
            </Reveal>
          </div>
        ))}
      </div>
    </section>
  );
}

function DetectionMock() {
  const items = [
    { n: "AimBot", t: "blue" as const },
    { n: "Silent Aim", t: "violet" as const },
    { n: "Overlay / ESP", t: "amber" as const },
    { n: "Godmode", t: "green" as const },
    { n: "Spoofer", t: "blue" as const },
    { n: "Injection", t: "red" as const },
  ];
  return (
    <div className="card p-6">
      <div className="mb-4 flex items-center justify-between">
        <span className="text-sm font-semibold text-white">Aktif Tespit Modülleri</span>
        <Badge tone="green" dot>Canlı</Badge>
      </div>
      <div className="grid grid-cols-2 gap-3">
        {items.map((d) => (
          <div key={d.n} className="flex items-center justify-between rounded-xl border border-white/5 bg-base-900/60 px-3 py-2.5">
            <span className="text-sm text-slate-300">{d.n}</span>
            <Badge tone={d.t}>Aktif</Badge>
          </div>
        ))}
      </div>
    </div>
  );
}

function PanelMock() {
  return (
    <div className="card overflow-hidden p-0">
      <div className="flex items-center gap-2 border-b border-white/5 px-4 py-3">
        <span className="h-2.5 w-2.5 rounded-full bg-rose-500/70" />
        <span className="h-2.5 w-2.5 rounded-full bg-amber-500/70" />
        <span className="h-2.5 w-2.5 rounded-full bg-emerald-500/70" />
      </div>
      <div className="grid grid-cols-3 gap-2 p-4">
        {[["ONLINE", "256"], ["BANS", "89"], ["PLAYERS", "15.8K"]].map(([l, v]) => (
          <div key={l} className="rounded-xl border border-white/5 bg-base-900/60 p-3">
            <div className="text-[9px] font-semibold tracking-wider text-slate-500">{l}</div>
            <div className="mt-1 text-lg font-bold text-white">{v}</div>
          </div>
        ))}
      </div>
      <div className="px-4 pb-4">
        <div className="flex h-24 items-end gap-1 rounded-xl border border-white/5 bg-base-900/60 p-3">
          {[40, 60, 50, 72, 64, 84, 76, 96, 88, 74, 92, 100].map((h, i) => (
            <div key={i} className="flex-1 rounded-t bg-gradient-to-t from-brand-500/30 to-brand-400" style={{ height: `${h}%` }} />
          ))}
        </div>
      </div>
    </div>
  );
}

function RulesMock() {
  const rules = [
    ["Anti Aimbot", true], ["Anti NoClip", true], ["Anti Godmode", true],
    ["Anti Spawn", true], ["Anti Speed Hack", true], ["Anti Overlay", false],
  ] as const;
  return (
    <div className="card p-6">
      <div className="mb-4 flex items-center justify-between">
        <span className="text-sm font-semibold text-white">Güvenlik Kuralları</span>
        <span className="text-xs text-slate-500">38 aktif</span>
      </div>
      <div className="space-y-2">
        {rules.map(([n, on]) => (
          <div key={n} className="flex items-center justify-between rounded-xl border border-white/5 bg-base-900/60 px-3 py-2.5">
            <span className="text-sm text-slate-300">{n}</span>
            <span className={"relative inline-flex h-5 w-9 items-center rounded-full " + (on ? "bg-brand-500" : "bg-white/10")}>
              <span className={"inline-block h-3.5 w-3.5 transform rounded-full bg-white transition " + (on ? "translate-x-5" : "translate-x-1")} />
            </span>
          </div>
        ))}
      </div>
    </div>
  );
}

/* ----------------------------- STATS ----------------------------------- */

function StatsBand() {
  const stats = [
    { v: "99.9%", l: "Tespit oranı" },
    { v: "<5ms", l: "Sunucu gecikmesi" },
    { v: "15K+", l: "Korunan oyuncu" },
    { v: "24/7", l: "Canlı izleme" },
  ];
  return (
    <section className="border-y border-white/5 bg-base-900/40 py-16">
      <div className="mx-auto grid max-w-5xl grid-cols-2 gap-6 px-4 sm:px-6 md:grid-cols-4">
        {stats.map((s, i) => (
          <Reveal key={s.l} delay={i * 80} className="text-center">
            <div className="bg-gradient-to-b from-white to-slate-400 bg-clip-text text-4xl font-extrabold text-transparent sm:text-5xl">
              {s.v}
            </div>
            <div className="mt-2 text-sm text-slate-500">{s.l}</div>
          </Reveal>
        ))}
      </div>
    </section>
  );
}

/* --------------------------- DETECTION --------------------------------- */

function Detection() {
  const detections = [
    "AimBot", "Silent Aim", "Overlay / ESP", "Illegal Weapon", "Godmode",
    "Spoofer", "Resource Inject", "Event Exploit", "Illegal Vehicle", "Explosion Spam",
  ];
  return (
    <section id="detection" className="mx-auto max-w-6xl scroll-mt-20 px-4 py-24 sm:px-6">
      <Reveal className="mx-auto max-w-2xl text-center">
        <span className="section-title text-brand-400">Koruma Kapsamı</span>
        <h2 className="mt-3 text-3xl font-bold tracking-tight text-white sm:text-4xl">
          Her tehdide karşı tek kalkan
        </h2>
        <p className="mt-4 text-slate-400">
          Yaygın hilelerden yeni exploit&apos;lere kadar geniş kapsamlı koruma.
        </p>
      </Reveal>
      <div className="mt-12 flex flex-wrap justify-center gap-3">
        {detections.map((d, i) => (
          <Reveal
            key={d}
            delay={i * 40}
            className="flex items-center gap-2 rounded-full border border-white/10 bg-base-850/60 px-4 py-2 text-sm text-slate-300"
          >
            <Icons.shieldCheck size={15} className="text-emerald-400" />
            {d}
          </Reveal>
        ))}
      </div>
    </section>
  );
}

/* ----------------------------- DEMO ------------------------------------ */

function DemoSection() {
  return (
    <section id="demo" className="mx-auto max-w-6xl scroll-mt-20 px-4 py-24 sm:px-6">
      <div className="relative overflow-hidden rounded-3xl border border-white/10 bg-base-900/50 p-8 sm:p-12">
        <div className="pointer-events-none absolute -right-16 -top-16 h-64 w-64 rounded-full bg-brand-500/15 blur-3xl" />
        <div className="grid items-center gap-10 lg:grid-cols-2">
          <Reveal>
            <Badge tone="blue">Canlı Demo</Badge>
            <h2 className="mt-4 text-3xl font-bold tracking-tight text-white sm:text-4xl">
              Paneli kaydolmadan dene
            </h2>
            <p className="mt-4 text-slate-400">
              Demo hesabıyla gerçek verilerle dolu bir sunucuyu incele: dashboard,
              oyuncular, banlar, canlı harita, güvenlik kuralları ve konsol.
            </p>
            <div className="mt-6 flex flex-col gap-3 sm:flex-row">
              <LinkButton href="/api/demo" icon="bolt" className="px-6 py-3">
                Demoyu Aç
              </LinkButton>
              <LinkButton href="/login" variant="secondary" className="px-6 py-3">
                Giriş Yap
              </LinkButton>
            </div>
            <div className="mt-5 rounded-xl border border-white/5 bg-base-950/50 px-4 py-3 text-xs text-slate-500">
              Demo hesabı: <span className="font-mono text-slate-300">demo@aeigs.gg</span> ·{" "}
              <span className="font-mono text-slate-300">Demo1234</span>
            </div>
          </Reveal>
          <Reveal delay={120}>
            <PanelMock />
          </Reveal>
        </div>
      </div>
    </section>
  );
}

/* --------------------------- PRICING ----------------------------------- */

function PricingTeaser() {
  const tiers = [
    { name: "Starter", price: "€14.99", period: "/ay", featured: false, points: ["Temel tespit", "Web panel", "1 sunucu"] },
    { name: "Premium", price: "€29.99", period: "/ay", featured: true, points: ["Gelişmiş tespit", "Canlı harita + konsol", "Otomatik ban", "3 sunucu"] },
    { name: "Enterprise", price: "€99.99", period: "lifetime", featured: false, points: ["Tüm özellikler", "API erişimi", "Öncelikli destek"] },
  ];
  return (
    <section id="pricing" className="mx-auto max-w-6xl scroll-mt-20 px-4 py-24 sm:px-6">
      <Reveal className="mx-auto max-w-2xl text-center">
        <span className="section-title text-brand-400">Fiyatlandırma</span>
        <h2 className="mt-3 text-3xl font-bold tracking-tight text-white sm:text-4xl">
          Sunucuna uygun paketi seç
        </h2>
      </Reveal>
      <div className="mt-12 grid gap-6 lg:grid-cols-3">
        {tiers.map((t, i) => (
          <Reveal
            key={t.name}
            delay={i * 100}
            className={
              "card relative flex flex-col p-7 " +
              (t.featured ? "border-brand-500/40 shadow-glow ring-1 ring-brand-500/20" : "")
            }
          >
            {t.featured && (
              <span className="absolute -top-3 left-1/2 -translate-x-1/2">
                <Badge tone="blue"><Icons.crown size={12} /> En Popüler</Badge>
              </span>
            )}
            <h3 className="text-lg font-bold text-white">{t.name}</h3>
            <div className="mt-3 flex items-end gap-1">
              <span className="text-4xl font-extrabold text-white">{t.price}</span>
              <span className="pb-1 text-sm text-slate-500">{t.period}</span>
            </div>
            <ul className="my-6 flex-1 space-y-3">
              {t.points.map((p) => (
                <li key={p} className="flex items-center gap-2.5 text-sm text-slate-300">
                  <span className="grid h-5 w-5 place-items-center rounded-full bg-emerald-500/15 text-emerald-400">
                    <Icons.check size={13} />
                  </span>
                  {p}
                </li>
              ))}
            </ul>
            <LinkButton href="/pricing" variant={t.featured ? "primary" : "secondary"} className="w-full justify-center py-3">
              Paketi Seç
            </LinkButton>
          </Reveal>
        ))}
      </div>
    </section>
  );
}

/* ----------------------------- FAQ ------------------------------------- */

function FaqSection() {
  return (
    <section id="faq" className="mx-auto max-w-6xl scroll-mt-20 px-4 py-24 sm:px-6">
      <Reveal className="mx-auto mb-12 max-w-2xl text-center">
        <span className="section-title text-brand-400">SSS</span>
        <h2 className="mt-3 text-3xl font-bold tracking-tight text-white sm:text-4xl">
          Sık sorulan sorular
        </h2>
      </Reveal>
      <Faq />
    </section>
  );
}

/* ----------------------------- CTA ------------------------------------- */

function CtaBand() {
  return (
    <section className="mx-auto max-w-6xl px-4 pb-24 sm:px-6">
      <Reveal className="relative overflow-hidden rounded-3xl border border-brand-500/20 bg-gradient-to-br from-brand-600/20 via-base-850 to-accent-violet/10 p-10 text-center sm:p-16">
        <div className="pointer-events-none absolute -right-20 -top-20 h-60 w-60 rounded-full bg-brand-500/20 blur-3xl" />
        <h2 className="text-3xl font-bold tracking-tight text-white sm:text-4xl">
          Sunucunu bugün koruma altına al
        </h2>
        <p className="mx-auto mt-4 max-w-xl text-slate-300">
          Hesabını oluştur, lisansını etkinleştir ve dakikalar içinde korunmaya başla.
        </p>
        <div className="mt-8 flex flex-col items-center justify-center gap-3 sm:flex-row">
          <LinkButton href="/register" className="px-6 py-3 text-base">Ücretsiz Hesap Oluştur</LinkButton>
          <Link href="/api/demo" className="text-sm font-medium text-slate-300 hover:text-white">
            veya canlı demoyu aç →
          </Link>
        </div>
      </Reveal>
    </section>
  );
}
