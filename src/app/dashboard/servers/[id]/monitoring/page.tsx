import { getOwnedServer } from "@/lib/guards";
import { db } from "@/lib/db";
import { PageHeader, EmptyState, Badge } from "@/components/ui";
import { Icons } from "@/components/icons";

export const dynamic = "force-dynamic";

export default async function MonitoringPage({ params }: { params: { id: string } }) {
  const { server } = await getOwnedServer(params.id);
  const players = await db.player.findMany({
    where: { serverId: server.id, online: true },
    orderBy: { trustScore: "asc" },
    take: 24,
  });

  return (
    <>
      <PageHeader
        title="İzleme"
        description="Çevrimiçi oyuncuların ekranlarını aynı anda izleyin."
      />
      <div className="mb-4 flex items-center gap-2 rounded-xl border border-amber-500/20 bg-amber-500/5 px-4 py-2.5 text-sm text-amber-200/80">
        <Icons.bolt size={16} className="text-amber-300" />
        Canlı ekran görüntüleri oyun içi entegrasyonla aktifleşecek.
      </div>

      {players.length === 0 ? (
        <EmptyState icon="eye" title="Çevrimiçi oyuncu yok" description="Oyuncular bağlandığında ekranları burada görünecek." />
      ) : (
        <div className="grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-4">
          {players.map((p) => (
            <div key={p.id} className="overflow-hidden rounded-xl border border-white/5 bg-base-850/60">
              <div className="relative aspect-video bg-gradient-to-br from-slate-700/30 to-base-950">
                <div className="absolute inset-0 bg-grid-faint [background-size:14px_14px] opacity-30" />
                <div className="absolute inset-0 grid place-items-center text-slate-600">
                  <Icons.eye size={22} />
                </div>
                <span className="absolute left-2 top-2 flex items-center gap-1 rounded bg-black/50 px-1.5 py-0.5 text-[10px] text-emerald-300">
                  <span className="h-1.5 w-1.5 rounded-full bg-emerald-400" /> canlı
                </span>
              </div>
              <div className="flex items-center justify-between px-3 py-2">
                <span className="truncate text-xs text-slate-300">{p.name}</span>
                <Badge tone={p.trustScore >= 70 ? "green" : p.trustScore >= 40 ? "amber" : "red"}>{100 - p.trustScore}</Badge>
              </div>
            </div>
          ))}
        </div>
      )}
    </>
  );
}
