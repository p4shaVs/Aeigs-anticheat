import Link from "next/link";
import { getOwnedServer } from "@/lib/guards";
import { StatusBadge } from "@/components/ui";
import { Icons } from "@/components/icons";
import { relativeDays } from "@/lib/utils";
import { ServerTabs } from "./server-tabs";

export default async function ServerLayout({
  children,
  params,
}: {
  children: React.ReactNode;
  params: { id: string };
}) {
  const { server } = await getOwnedServer(params.id);

  return (
    <div>
      <Link
        href="/dashboard/servers"
        className="mb-4 inline-flex items-center gap-1.5 text-sm text-slate-400 hover:text-slate-200"
      >
        <Icons.arrowRight size={15} className="rotate-180" />
        Sunucular
      </Link>

      <div className="mb-6 flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div className="flex items-center gap-3">
          <span className="grid h-12 w-12 place-items-center rounded-2xl bg-brand-gradient text-white shadow-glow">
            <Icons.server size={22} />
          </span>
          <div>
            <div className="flex items-center gap-2">
              <h1 className="text-xl font-bold text-white">{server.name}</h1>
              <StatusBadge status={server.status} />
            </div>
            <p className="text-sm text-slate-500">
              {server.ip ?? "IP ayarlanmadı"} · AC {server.acVersion ?? "—"}
            </p>
          </div>
        </div>
        <div className="flex items-center gap-4 text-sm">
          <div className="rounded-xl border border-white/5 bg-base-900/40 px-4 py-2">
            <p className="text-[10px] uppercase text-slate-500">Lisans</p>
            <p className="font-medium text-slate-200">
              {relativeDays(server.licenseKey?.expiresAt)}
            </p>
          </div>
        </div>
      </div>

      <ServerTabs serverId={server.id} />

      {children}
    </div>
  );
}
