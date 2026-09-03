import { getOwnedServer } from "@/lib/guards";
import { db } from "@/lib/db";
import { PageHeader } from "@/components/ui";
import { BlacklistManager, type BlacklistRow } from "./blacklist-manager";

export const dynamic = "force-dynamic";

export default async function BlacklistPage({ params }: { params: { id: string } }) {
  const { server } = await getOwnedServer(params.id);
  const rows = await db.blacklist.findMany({
    where: { serverId: server.id },
    orderBy: { createdAt: "desc" },
    take: 1000,
  });

  const list: BlacklistRow[] = rows.map((r) => ({
    id: r.id,
    kind: r.kind,
    model: r.model,
    label: r.label,
    action: r.action,
    enabled: r.enabled,
  }));

  return (
    <>
      <PageHeader
        title="Kara Liste"
        description="Yasaklı araç, ped, nesne ve silahlar. Oyuncu spawn etmeye çalıştığında oyun içinde otomatik engellenir."
      />
      <BlacklistManager serverId={server.id} rows={list} />
    </>
  );
}
