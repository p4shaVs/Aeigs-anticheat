import { NextRequest } from "next/server";
import { headers } from "next/headers";
import { z } from "zod";
import { db } from "@/lib/db";
import { handler, ok, ApiError } from "@/lib/api";
import { requireOwnedServer } from "@/lib/api-guards";
import { audit } from "@/lib/audit";
import { clientIp } from "@/lib/session";

const schema = z.object({
  identifier: z.string().trim().min(2).max(120),
  displayName: z.string().trim().max(60).optional(),
  role: z.enum(["OWNER", "ADMIN", "MODERATOR"]).default("MODERATOR"),
});

export const POST = handler(
  async (req: NextRequest, ctx: { params: { id: string } }) => {
    const { server, user } = await requireOwnedServer(ctx.params.id);
    const body = schema.parse(await req.json());

    const exists = await db.serverAdmin.findFirst({
      where: { serverId: server.id, identifier: body.identifier },
    });
    if (exists) throw new ApiError(409, "Bu tanımlayıcı zaten yetkili");

    const admin = await db.serverAdmin.create({
      data: {
        serverId: server.id,
        identifier: body.identifier,
        displayName: body.displayName,
        role: body.role,
      },
    });

    await audit({
      userId: user.id,
      action: "SERVER_ADMIN_ADD",
      targetType: "Server",
      targetId: server.id,
      ip: clientIp(headers()),
      meta: { identifier: body.identifier, role: body.role },
    });

    return ok({ id: admin.id }, 201);
  }
);
