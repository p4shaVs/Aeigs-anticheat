import { getOwnedServer } from "@/lib/guards";
import { db } from "@/lib/db";
import { MapView, type MapPlayer } from "./map-view";

export const dynamic = "force-dynamic";

export default async function MapPage({
  params,
}: {
  params: { id: string };
}) {
  const { server } = await getOwnedServer(params.id);
  const players = await db.player.findMany({
    where: { serverId: server.id, online: true },
    orderBy: { trustScore: "asc" },
    take: 300,
  });

  const rows: MapPlayer[] = players.map((p) => ({
    id: p.id,
    name: p.name,
    trustScore: p.trustScore,
    license: p.license,
    playtimeSec: p.playtimeSec,
  }));

  return <MapView players={rows} maxSlots={server.maxSlots} />;
}
