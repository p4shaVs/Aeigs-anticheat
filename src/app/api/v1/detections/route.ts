import { NextRequest } from "next/server";
import { z } from "zod";
import { db } from "@/lib/db";
import { handler, ok, ApiError } from "@/lib/api";
import { authenticateServer } from "@/lib/server-auth";
import { rateLimit } from "@/lib/ratelimit";
import { generateBanCode } from "@/lib/keys";
import { parseJson } from "@/lib/utils";
import { isWhitelisted } from "@/lib/bypass";
import { sendWebhook } from "@/lib/discord";

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

  // Bypass (whitelist) kontrolü — muaf oyuncular otomatik banlanmaz.
  const whitelisted = player
    ? await isWhitelisted(server.id, {
        license: player.license,
        discord: player.discord,
        steam: player.steam,
        ip: player.ip,
      })
    : false;

  // Detection webhook'u (bypass'lı oyuncu için de bildirilir ama ban atılmaz)
  void sendWebhook(server.config, "detection", server.name, {
    player: body.playerName,
    reason: `${body.type} (${body.severity})${whitelisted ? " — BYPASS'LI" : ""}`,
    identifiers: player
      ? { license: player.license, discord: player.discord, steam: player.steam, ip: player.ip }
      : undefined,
  });

  // Otomatik ban değerlendirmesi
  const features = parseJson<string[]>(
    (server as any).licenseKey?.features ?? "[]",
    []
  );
  const eligible =
    body.severity === "CRITICAL" && features.includes("auto_ban") && !!player && !whitelisted;

  // Tekrarlı ban engeli: oyuncunun zaten aktif bir banı varsa yeni ban atma.
  // (noclip + teleport + superjump aynı anda geldiğinde 3 ban oluşmasını önler.)
  let existingBan: { code: string | null } | null = null;
  if (eligible && player) {
    existingBan = await db.ban.findFirst({
      where: { serverId: server.id, playerId: player.id, active: true },
      select: { code: true },
    });
  }

  const autoBan = eligible && player && !existingBan;
  let banCode: string | null = existingBan?.code ?? null;

  if (autoBan && player) {
    banCode = generateBanCode();
    await db.$transaction([
      db.ban.create({
        data: {
          serverId: server.id,
          playerId: player.id,
          code: banCode,
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
      // Kuyruğa BAN aksiyonu ekle — kaynak pollActions ile oyuncuyu anında atar.
      db.punishAction.create({
        data: {
          serverId: server.id,
          playerId: player.id,
          type: "BAN",
          reason: `Otomatik ban: ${body.type}`,
          issuedBy: "AntiCheat",
          playerName: player.name,
          status: "PENDING",
        },
      }),
      db.player.update({
        where: { id: player.id },
        data: { online: false, trustScore: 0 },
      }),
    ]);

    void sendWebhook(server.config, "autoban", server.name, {
      player: player.name,
      reason: body.type,
      code: banCode,
      by: "AntiCheat",
      identifiers: { license: player.license, discord: player.discord, steam: player.steam, ip: player.ip },
    });
  }

  // banned=true → kaynak bu oyuncuyu (yeni ban ya da mevcut ban) hemen atmalı.
  return ok({ recorded: true, autoBan: !!autoBan, banned: eligible && !!player, banCode, whitelisted });
});
