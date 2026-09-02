import { getOwnedServer } from "@/lib/guards";
import { parseJson } from "@/lib/utils";
import { ServerSettings } from "./server-settings";

export const dynamic = "force-dynamic";

export default async function SettingsPage({
  params,
}: {
  params: { id: string };
}) {
  const { server } = await getOwnedServer(params.id);
  const config = parseJson<{ discordWebhook?: string }>(server.config, {});

  return (
    <ServerSettings
      server={{
        id: server.id,
        name: server.name,
        ip: server.ip,
        maxSlots: server.maxSlots,
        discordWebhook: config.discordWebhook ?? "",
        hasToken: !!server.apiTokenHash,
      }}
      appUrl={process.env.APP_URL ?? ""}
    />
  );
}
