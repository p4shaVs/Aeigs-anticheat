import Link from "next/link";
import { SiteHeader, SiteFooter } from "@/components/site-header";
import { LinkButton, Badge } from "@/components/ui";
import { Icons } from "@/components/icons";

export default function HomePage() {
  return (
    <div className="min-h-screen">
      <SiteHeader />
      <main>
        <Hero />
        <LogoStrip />
        <Features />
        <Detection />
        <PanelPreview />
        <CtaBand />
      </main>
      <SiteFooter />
    </div>
  );
}

/* -------------------------------------------------------------------------- */

function Hero() {
  return (
    <section className="relative overflow-hidden">
      <div className="pointer-events-none absolute inset-0 -z-10 bg-grid-faint [background-size:44px_44px] [mask-image:radial-gradient(ellipse_at_center,black,transparent_70%)]" />
      <div className="mx-auto max-w-6xl px-4 pb-20 pt-20 text-center sm:px-6 sm:pt-28">
        <div className="mx-auto mb-6 inline-flex animate-fade-in items-center gap-2 rounded-full border border-white/10 bg-white/5 px-4 py-1.5 text-xs font-medium text-slate-300">
          <span className="flex h-1.5 w-1.5 rounded-full bg-emerald-400 shadow-[0_0_8px] shadow-emerald-400" />
          v4.7 — Yeni tespit motoru yayında
        </div>
        <h1 className="mx-auto max-w-3xl animate-fade-in text-4xl font-extrabold leading-[1.1] tracking-tight text-white sm:text-6xl">
          FiveM sunucunuz için{" "}
          <span className="bg-gradient-to-r from-brand-400 via-brand-300 to-accent-violet bg-clip-text text-transparent">
            yenilmez koruma
          </span>
        </h1>
        <p className="mx-auto mt-6 max-w-2xl animate-fade-in text-lg text-slate-400">
          Aeigs Anti-Cheat; aimbot, silent aim, injection ve exploit'leri
          gerçek zamanlı yakalar. Web panelinden oyuncuları yönetin, banlayın ve
          tüm sunucunuzu tek yerden kontrol edin.
        </p>
        <div className="mt-9 flex animate-fade-in flex-col items-center justify-center gap-3 sm:flex-row">
          <LinkButton href="/register" icon="shieldCheck" className="px-6 py-3 text-base">
            Hemen Koruma Al
          </LinkButton>
          <LinkButton
            href="/pricing"
            variant="secondary"
            className="px-6 py-3 text-base"
          >
            Fiyatları Gör
          </LinkButton>
        </div>
        <p className="mt-4 text-xs text-slate-500">
          Kredi kartı gerekmez • 5 dakikada kurulum • 7/24 destek
        </p>

        <HeroStats />
      </div>
    </section>
  );
}

function HeroStats() {
  const stats = [
    { value: "99.9%", label: "Tespit oranı" },
    { value: "<5ms", label: "Sunucu gecikmesi" },
    { value: "24/7", label: "Canlı izleme" },
    { value: "15K+", label: "Korunan oyuncu" },
  ];
  return (
    <div className="mx-auto mt-16 grid max-w-3xl grid-cols-2 gap-4 sm:grid-cols-4">
      {stats.map((s) => (
        <div key={s.label} className="card animate-fade-in p-5">
          <div className="text-2xl font-bold text-white sm:text-3xl">{s.value}</div>
          <div className="mt-1 text-xs text-slate-500">{s.label}</div>
        </div>
      ))}
    </div>
  );
}

function LogoStrip() {
  return (
    <section className="border-y border-white/5 bg-base-950/50 py-6">
      <div className="mx-auto flex max-w-6xl flex-wrap items-center justify-center gap-x-10 gap-y-3 px-4 text-slate-600 sm:px-6">
        <span className="text-xs uppercase tracking-widest">Güvendikleri</span>
        {["RolePlay TR", "LosSantos", "Vespucci", "Paleto", "Sandy RP", "Mirror Park"].map(
          (n) => (
            <span key={n} className="text-sm font-semibold text-slate-500">
              {n}
            </span>
          )
        )}
      </div>
    </section>
  );
}

/* -------------------------------------------------------------------------- */

function Features() {
  const items = [
    {
      icon: "shieldCheck" as const,
      title: "Gerçek Zamanlı Tespit",
      text: "Aimbot, silent aim, godmode ve overlay'leri milisaniyeler içinde yakalayan sunucu taraflı motor.",
    },
    {
      icon: "globe" as const,
      title: "Web Yönetim Paneli",
      text: "Tarayıcıdan oyuncu yönetimi, ban/kick, canlı harita ve detaylı analitik.",
    },
    {
      icon: "bolt" as const,
      title: "Yüksek Performans",
      text: "Optimize edilmiş yapı ile sunucunuza minimum yük. 5ms altı işlem süresi.",
    },
    {
      icon: "lock" as const,
      title: "Lisans Güvenliği",
      text: "Şifrelenmiş lisans anahtarları, HWID kontrolü ve anlık iptal desteği.",
    },
    {
      icon: "discord" as const,
      title: "Discord Entegrasyonu",
      text: "Tüm tespitler ve cezalar anında Discord kanalınıza webhook ile iletilir.",
    },
    {
      icon: "terminal" as const,
      title: "Uzaktan Konsol",
      text: "Web panelinden sunucu komutları çalıştırın, kaynakları yönetin.",
    },
  ];
  return (
    <section id="features" className="mx-auto max-w-6xl scroll-mt-20 px-4 py-24 sm:px-6">
      <SectionHead
        eyebrow="Özellikler"
        title="Bir sunucunun ihtiyacı olan her şey"
        desc="Tespitten yönetime, lisanstan raporlamaya kadar eksiksiz bir anti-cheat ekosistemi."
      />
      <div className="mt-14 grid gap-5 sm:grid-cols-2 lg:grid-cols-3">
        {items.map((it) => {
          const Icon = Icons[it.icon];
          return (
            <div
              key={it.title}
              className="card group p-6 transition hover:border-brand-500/30 hover:shadow-glow"
            >
              <span className="grid h-11 w-11 place-items-center rounded-xl bg-brand-gradient text-white shadow-glow">
                <Icon size={22} />
              </span>
              <h3 className="mt-4 text-base font-semibold text-white">{it.title}</h3>
              <p className="mt-2 text-sm leading-relaxed text-slate-400">{it.text}</p>
            </div>
          );
        })}
      </div>
    </section>
  );
}

/* -------------------------------------------------------------------------- */

function Detection() {
  const detections = [
    { name: "AimBot", tone: "blue" as const },
    { name: "Silent Aim", tone: "violet" as const },
    { name: "Overlay / ESP", tone: "amber" as const },
    { name: "Illegal Weapon", tone: "red" as const },
    { name: "Godmode", tone: "green" as const },
    { name: "Spoofer", tone: "blue" as const },
    { name: "Resource Inject", tone: "violet" as const },
    { name: "Event Exploit", tone: "amber" as const },
  ];
  return (
    <section
      id="detection"
      className="relative scroll-mt-20 border-y border-white/5 bg-base-900/40 py-24"
    >
      <div className="mx-auto grid max-w-6xl items-center gap-14 px-4 sm:px-6 lg:grid-cols-2">
        <div>
          <SectionHead
            align="left"
            eyebrow="Koruma Motoru"
            title="Bilinen ve bilinmeyen tüm tehditler"
            desc="Davranış analizi ve imza tabanlı tespitin birleşimi ile hem yaygın hilelere hem de yeni exploit'lere karşı koruma."
          />
          <ul className="mt-8 space-y-3">
            {[
              "Sunucu taraflı doğrulama — client'a güvenmez",
              "Otomatik ban ve kanıt (screenshot) toplama",
              "Trust-score ile şüpheli oyuncu takibi",
              "Yanlış pozitifleri en aza indiren akıllı eşikler",
            ].map((t) => (
              <li key={t} className="flex items-start gap-3 text-sm text-slate-300">
                <span className="mt-0.5 grid h-5 w-5 shrink-0 place-items-center rounded-full bg-emerald-500/15 text-emerald-400">
                  <Icons.check size={13} />
                </span>
                {t}
              </li>
            ))}
          </ul>
        </div>
        <div className="card p-6">
          <div className="mb-4 flex items-center justify-between">
            <span className="text-sm font-semibold text-white">Aktif Tespit Modülleri</span>
            <Badge tone="green" dot>
              Canlı
            </Badge>
          </div>
          <div className="grid grid-cols-2 gap-3">
            {detections.map((d) => (
              <div
                key={d.name}
                className="flex items-center justify-between rounded-xl border border-white/5 bg-base-900/60 px-3 py-2.5"
              >
                <span className="text-sm text-slate-300">{d.name}</span>
                <Badge tone={d.tone}>Aktif</Badge>
              </div>
            ))}
          </div>
        </div>
      </div>
    </section>
  );
}

/* -------------------------------------------------------------------------- */

function PanelPreview() {
  return (
    <section className="mx-auto max-w-6xl px-4 py-24 sm:px-6">
      <SectionHead
        eyebrow="Yönetim Paneli"
        title="Sunucunuzu tarayıcıdan yönetin"
        desc="Oyuncular, banlar, canlı harita, analitik ve daha fazlası — hepsi tek modern panelde."
      />
      <div className="mt-12 overflow-hidden rounded-2xl border border-white/10 bg-base-850 shadow-card">
        <div className="flex items-center gap-2 border-b border-white/5 px-4 py-3">
          <span className="h-3 w-3 rounded-full bg-rose-500/70" />
          <span className="h-3 w-3 rounded-full bg-amber-500/70" />
          <span className="h-3 w-3 rounded-full bg-emerald-500/70" />
          <span className="ml-3 text-xs text-slate-500">panel.aeigs.gg/dashboard</span>
        </div>
        <div className="grid gap-4 p-4 sm:grid-cols-4">
          {[
            { l: "CONNECTIONS", v: "1 247", c: "text-brand-300" },
            { l: "TOTAL PLAYERS", v: "15 823", c: "text-accent-violet" },
            { l: "TOTAL BANS", v: "89", c: "text-accent-rose" },
            { l: "ONLINE NOW", v: "256", c: "text-accent-emerald" },
          ].map((s) => (
            <div key={s.l} className="rounded-xl border border-white/5 bg-base-900/60 p-4">
              <div className="text-[10px] font-semibold uppercase tracking-wider text-slate-500">
                {s.l}
              </div>
              <div className={`mt-2 text-2xl font-bold ${s.c}`}>{s.v}</div>
            </div>
          ))}
          <div className="sm:col-span-4">
            <div className="flex h-40 items-end gap-1.5 rounded-xl border border-white/5 bg-base-900/60 p-4">
              {[40, 55, 48, 70, 62, 85, 78, 96, 88, 72, 90, 100, 84, 66, 92].map((h, i) => (
                <div
                  key={i}
                  className="flex-1 rounded-t bg-gradient-to-t from-brand-500/30 to-brand-400"
                  style={{ height: `${h}%` }}
                />
              ))}
            </div>
          </div>
        </div>
      </div>
      <div className="mt-8 text-center">
        <LinkButton href="/register" icon="arrowRight">
          Paneli Ücretsiz Dene
        </LinkButton>
      </div>
    </section>
  );
}

/* -------------------------------------------------------------------------- */

function CtaBand() {
  return (
    <section className="mx-auto max-w-6xl px-4 pb-24 sm:px-6">
      <div className="relative overflow-hidden rounded-3xl border border-brand-500/20 bg-gradient-to-br from-brand-600/20 via-base-850 to-accent-violet/10 p-10 text-center sm:p-16">
        <div className="pointer-events-none absolute -right-20 -top-20 h-60 w-60 rounded-full bg-brand-500/20 blur-3xl" />
        <h2 className="text-3xl font-bold tracking-tight text-white sm:text-4xl">
          Sunucunuzu bugün koruma altına alın
        </h2>
        <p className="mx-auto mt-4 max-w-xl text-slate-300">
          Hesabınızı oluşturun, lisansınızı etkinleştirin ve dakikalar içinde
          korunmaya başlayın.
        </p>
        <div className="mt-8 flex flex-col items-center justify-center gap-3 sm:flex-row">
          <LinkButton href="/register" className="px-6 py-3 text-base">
            Ücretsiz Hesap Oluştur
          </LinkButton>
          <Link
            href="/pricing"
            className="text-sm font-medium text-slate-300 hover:text-white"
          >
            veya paketleri incele →
          </Link>
        </div>
      </div>
    </section>
  );
}

/* -------------------------------------------------------------------------- */

function SectionHead({
  eyebrow,
  title,
  desc,
  align = "center",
}: {
  eyebrow: string;
  title: string;
  desc?: string;
  align?: "center" | "left";
}) {
  return (
    <div className={align === "center" ? "mx-auto max-w-2xl text-center" : "max-w-xl"}>
      <span className="section-title text-brand-400">{eyebrow}</span>
      <h2 className="mt-3 text-3xl font-bold tracking-tight text-white sm:text-4xl">
        {title}
      </h2>
      {desc && <p className="mt-4 text-slate-400">{desc}</p>}
    </div>
  );
}
