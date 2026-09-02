import { NextRequest } from "next/server";
import { db } from "@/lib/db";
import { handler, ok } from "@/lib/api";
import { authenticateServer } from "@/lib/server-auth";

export const dynamic = "force-dynamic";

// Panelden verilen bekleyen cezaları (WARN/KICK/BAN/UNBAN) kaynağa iletir.
export const GET = handler(async (req: NextRequest) => {
  const server = await authenticateServer(req);

  const actions = await db.punishAction.findMany({
    where: { serverId: server.id, status: "PENDING" },
    orderBy: { createdAt: "asc" },
    take: 100,
    include: {
      player: {
        select: { license: true, steam: true, discord: true, ip: true },
      },
    },
  });

  return ok({
    actions: actions.map((a) => ({
      id: a.id,
      type: a.type,
      reason: a.reason,
      issuedBy: a.issuedBy,
      playerName: a.playerName,
      identifiers: {
        license: a.player?.license ?? null,
        steam: a.player?.steam ?? null,
        discord: a.player?.discord ?? null,
        ip: a.player?.ip ?? null,
      },
    })),
  });
});
