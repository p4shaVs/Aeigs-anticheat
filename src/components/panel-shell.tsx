"use client";

import { useState } from "react";
import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { Logo } from "./ui";
import { Icons, type IconName } from "./icons";
import { cn } from "@/lib/utils";

export interface NavItem {
  href: string;
  label: string;
  icon: IconName;
  badge?: string;
  exact?: boolean;
}
export interface NavSection {
  title?: string;
  items: NavItem[];
}

export interface ShellUser {
  username: string;
  email: string;
  role: "USER" | "ADMIN";
  avatarUrl: string | null;
}

export function PanelShell({
  nav,
  user,
  children,
  variant = "customer",
}: {
  nav: NavSection[];
  user: ShellUser;
  children: React.ReactNode;
  variant?: "customer" | "admin";
}) {
  const pathname = usePathname();
  const router = useRouter();
  const [mobileOpen, setMobileOpen] = useState(false);

  function isActive(item: NavItem) {
    if (item.exact) return pathname === item.href;
    return pathname === item.href || pathname.startsWith(item.href + "/");
  }

  async function logout() {
    await fetch("/api/auth/logout", { method: "POST" });
    router.push("/login");
    router.refresh();
  }

  const sidebar = (
    <div className="flex h-full flex-col">
      <div className="flex h-16 shrink-0 items-center justify-between px-5">
        <Link href="/" onClick={() => setMobileOpen(false)}>
          <Logo />
        </Link>
        {variant === "admin" && (
          <span className="badge bg-purple-500/10 text-purple-300 ring-1 ring-inset ring-purple-500/20">
            Admin
          </span>
        )}
      </div>

      <nav className="flex-1 space-y-6 overflow-y-auto px-3 py-4">
        {nav.map((section, i) => (
          <div key={i}>
            {section.title && (
              <p className="mb-2 px-3 text-[10px] font-semibold uppercase tracking-[0.14em] text-slate-600">
                {section.title}
              </p>
            )}
            <div className="space-y-1">
              {section.items.map((item) => {
                const Icon = Icons[item.icon];
                const active = isActive(item);
                return (
                  <Link
                    key={item.href}
                    href={item.href}
                    onClick={() => setMobileOpen(false)}
                    className={cn("nav-link", active && "nav-link-active")}
                  >
                    <Icon size={18} className="shrink-0" />
                    <span className="flex-1 truncate">{item.label}</span>
                    {item.badge && (
                      <span className="rounded-md bg-white/5 px-1.5 py-0.5 text-[10px] font-medium text-slate-400">
                        {item.badge}
                      </span>
                    )}
                  </Link>
                );
              })}
            </div>
          </div>
        ))}
      </nav>

      <div className="shrink-0 border-t border-white/5 p-3">
        <div className="flex items-center gap-3 rounded-xl px-2 py-2">
          <span className="grid h-9 w-9 shrink-0 place-items-center rounded-full bg-brand-gradient text-sm font-bold text-white">
            {user.username.charAt(0).toUpperCase()}
          </span>
          <div className="min-w-0 flex-1">
            <p className="truncate text-sm font-medium text-slate-200">
              {user.username}
            </p>
            <p className="truncate text-xs text-slate-500">{user.email}</p>
          </div>
          <button
            onClick={logout}
            title="Çıkış yap"
            className="grid h-8 w-8 place-items-center rounded-lg text-slate-400 transition hover:bg-white/5 hover:text-rose-300"
          >
            <Icons.logout size={17} />
          </button>
        </div>
      </div>
    </div>
  );

  return (
    <div className="min-h-screen lg:grid lg:grid-cols-[264px_1fr]">
      {/* Masaüstü sidebar */}
      <aside className="sticky top-0 hidden h-screen border-r border-white/5 bg-base-900/60 backdrop-blur-xl lg:block">
        {sidebar}
      </aside>

      {/* Mobil sidebar */}
      {mobileOpen && (
        <div className="fixed inset-0 z-50 lg:hidden">
          <div
            className="absolute inset-0 bg-black/60 backdrop-blur-sm"
            onClick={() => setMobileOpen(false)}
          />
          <aside className="absolute left-0 top-0 h-full w-72 border-r border-white/5 bg-base-900">
            {sidebar}
          </aside>
        </div>
      )}

      <div className="flex min-h-screen flex-col">
        {/* Üst bar */}
        <header className="sticky top-0 z-30 flex h-16 items-center gap-3 border-b border-white/5 bg-base-950/70 px-4 backdrop-blur-xl sm:px-6">
          <button
            onClick={() => setMobileOpen(true)}
            className="grid h-9 w-9 place-items-center rounded-lg text-slate-400 hover:bg-white/5 lg:hidden"
          >
            <Icons.menu size={20} />
          </button>
          <div className="flex flex-1 items-center gap-2">
            <div className="hidden items-center gap-2 rounded-xl border border-white/10 bg-base-900/60 px-3 py-2 text-sm text-slate-500 sm:flex sm:w-64">
              <Icons.search size={16} />
              <span>Hızlı arama…</span>
            </div>
          </div>
          <div className="flex items-center gap-2">
            <Link
              href="/dashboard/settings"
              className="grid h-9 w-9 place-items-center rounded-lg text-slate-400 hover:bg-white/5"
              title="Bildirimler"
            >
              <Icons.bell size={18} />
            </Link>
            {variant === "admin" ? (
              <Link href="/dashboard" className="btn-secondary hidden sm:inline-flex">
                Müşteri Paneli
              </Link>
            ) : (
              user.role === "ADMIN" && (
                <Link href="/admin" className="btn-secondary hidden sm:inline-flex">
                  <Icons.crown size={15} /> Admin
                </Link>
              )
            )}
          </div>
        </header>

        <main className="flex-1 px-4 py-6 sm:px-6 lg:px-8">
          <div className="mx-auto max-w-7xl">{children}</div>
        </main>
      </div>
    </div>
  );
}
