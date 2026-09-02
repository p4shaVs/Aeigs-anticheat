import { NextRequest } from "next/server";
import { z } from "zod";
import { db } from "@/lib/db";
import { handler, ok, ApiError } from "@/lib/api";
import { authenticateServer } from "@/lib/server-auth";
import { rateLimit } from "@/lib/ratelimit";
import { parseJson } from "@/lib/utils";

// Kaynak, bir hile tespitini raporlar. severity CRITICAL ve lisansta auto_ban
// açıksa otomatik ban oluşturulur ve kaynağa "ban" komutu döndürülür.
const schema = z.object({
  type: z.string().max(40),
  severity: z.enum(["LOW", "MEDIUM", "HIGH", "CRITICAL"]).default("MEDIUM"),
  playerName: z.string().max(80),
  license: z.string().max(120).optional(),
  details: z.record(z.any()).optional(),
});

export const POST = handler(async (req: NextRequest) => {
  const server = await authenticateServer(req);
  const rl = rateLimit(`det:${server.id}`, 240, 60_000);
  if (!rl.success) throw new ApiError(429, "Rate limit");

  const body = schema.parse(await req.json());

  const player = body.license
    ? await db.player.findUnique({
        where: { serverId_license: { serverId: server.id, license: body.license } },
      })
    : null;

  await db.detection.create({
    data: {
      serverId: server.id,
      playerId: player?.id,
      type: body.type,
      severity: body.severity,
      playerName: body.playerName,
      details: JSON.stringify(body.details ?? {}),
    },
  });

  await db.serverLog.create({
    data: {
      serverId: server.id,
      level: "DETECTION",
      source: "anticheat",
      message: `${body.type} (${body.severity}) → ${body.playerName}`,
    },
  });

  // Güven skorunu düşür.
  if (player) {
    const penalty = body.severity === "CRITICAL" ? 60 : body.severity === "HIGH" ? 30 : 10;
    await db.player.update({
      where: { id: player.id },
      data: { trustScore: Math.max(0, player.trustScore - penalty) },
    });
  }

  // Otomatik ban değerlendirmesi
  const features = parseJson<string[]>(
    (server as any).licenseKey?.features ?? "[]",
    []
  );
  const autoBan =
    body.severity === "CRITICAL" && features.includes("auto_ban") && player;

  if (autoBan && player) {
    await db.$transaction([
      db.ban.create({
        data: {
          serverId: server.id,
          playerId: player.id,
          license: player.license,
          steam: player.steam,
          discord: player.discord,
          ip: player.ip,
          playerName: player.name,
          reason: `Otomatik ban: ${body.type}`,
          bannedBy: "AntiCheat",
          active: true,
          permanent: true,
        },
      }),
      db.player.update({
        where: { id: player.id },
        data: { online: false, trustScore: 0 },
      }),
    ]);
  }

  return ok({ recorded: true, autoBan: !!autoBan });
});
