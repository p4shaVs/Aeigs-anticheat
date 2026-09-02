import { getOwnedServer } from "@/lib/guards";
import { parseJson } from "@/lib/utils";
import { sanitizeRules } from "@/lib/rules";
import { RulesEditor } from "./rules-editor";

export const dynamic = "force-dynamic";

export default async function RulesPage({
  params,
}: {
  params: { id: string };
}) {
  const { server } = await getOwnedServer(params.id);
  const config = parseJson<{ rules?: Record<string, boolean> }>(server.config, {});
  const rules = sanitizeRules(config.rules);

  return <RulesEditor serverId={server.id} initialRules={rules} />;
}
