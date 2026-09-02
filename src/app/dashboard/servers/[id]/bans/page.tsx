import { getOwnedServer } from "@/lib/guards";
import { db } from "@/lib/db";
import { EmptyState, Badge } from "@/components/ui";
import { formatDateTime, relativeDays } from "@/lib/utils";
import { UnbanButton } from "./unban-button";

export const dynamic = "force-dynamic";

export default async function BansPage({
  params,
}: {
  params: { id: string };
}) {
  const { server } = await getOwnedServer(params.id);
  const bans = await db.ban.findMany({
    where: { serverId: server.id },
    orderBy: [{ active: "desc" }, { createdAt: "desc" }],
    take: 200,
  });

  if (bans.length === 0) {
    return (
      <EmptyState
        icon="ban"
        title="Ban kaydı yok"
        description="Oyuncular sayfasından veya otomatik tespitlerle verilen banlar burada görünür."
      />
    );
  }

  return (
    <div className="overflow-x-auto rounded-2xl border border-white/5 bg-base-850/60">
      <table className="w-full min-w-[760px] text-sm">
        <thead>
          <tr className="border-b border-white/5 text-left text-xs uppercase tracking-wide text-slate-500">
            <th className="px-4 py-3 font-medium">Oyuncu</th>
            <th className="px-4 py-3 font-medium">Sebep</th>
            <th className="px-4 py-3 font-medium">Veren</th>
            <th className="px-4 py-3 font-medium">Tarih</th>
            <th className="px-4 py-3 font-medium">Durum</th>
            <th className="px-4 py-3 text-right font-medium">İşlem</th>
          </tr>
        </thead>
        <tbody>
          {bans.map((b) => (
            <tr key={b.id} className="border-b border-white/5 last:border-0 hover:bg-white/[0.02]">
              <td className="px-4 py-3">
                <div className="font-medium text-slate-200">{b.playerName}</div>
                <div className="font-mono text-[11px] text-slate-500">
                  {b.license ?? b.steam ?? b.discord ?? b.ip ?? "—"}
                </div>
              </td>
              <td className="max-w-xs px-4 py-3 text-slate-300">{b.reason}</td>
              <td className="px-4 py-3 text-slate-400">{b.bannedBy}</td>
              <td className="px-4 py-3 text-slate-500">{formatDateTime(b.createdAt)}</td>
              <td className="px-4 py-3">
                {b.active ? (
                  <Badge tone="red" dot>
                    {b.permanent ? "Kalıcı" : relativeDays(b.expiresAt)}
                  </Badge>
                ) : (
                  <Badge tone="gray">Kaldırıldı</Badge>
                )}
              </td>
              <td className="px-4 py-3 text-right">
                {b.active ? (
                  <UnbanButton serverId={server.id} banId={b.id} />
                ) : (
                  <span className="text-xs text-slate-600">—</span>
                )}
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
