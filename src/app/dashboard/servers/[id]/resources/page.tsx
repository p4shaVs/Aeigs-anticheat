import { getOwnedServer } from "@/lib/guards";
import { PageHeader, Card, Badge } from "@/components/ui";
import { Icons } from "@/components/icons";

export const dynamic = "force-dynamic";

// FiveM kaynak (resource) yönetimi — canlı liste oyun içi entegrasyonla dolacak.
// Şimdilik yapıyı ve örnek görünümü sağlar.
const SAMPLE = [
  { name: "aeigs-anticheat", status: "started" },
  { name: "es_extended", status: "started" },
  { name: "oxmysql", status: "started" },
  { name: "spawnmanager", status: "started" },
  { name: "chat", status: "started" },
  { name: "mapmanager", status: "started" },
];

export default async function ResourcesPage({ params }: { params: { id: string } }) {
  await getOwnedServer(params.id);

  return (
    <>
      <PageHeader
        title="Kaynaklar"
        description="Sunucudaki FiveM kaynaklarını görüntüle ve yönet."
      />
      <div className="mb-4 flex items-center gap-2 rounded-xl border border-amber-500/20 bg-amber-500/5 px-4 py-2.5 text-sm text-amber-200/80">
        <Icons.bolt size={16} className="text-amber-300" />
        Canlı kaynak listesi ve başlat/durdur oyun içi entegrasyonla aktifleşecek. Aşağıdaki liste örnektir.
      </div>
      <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
        {SAMPLE.map((r) => (
          <Card key={r.name} className="flex items-center justify-between p-4">
            <div className="flex items-center gap-3">
              <span className="grid h-9 w-9 place-items-center rounded-lg bg-white/5 text-brand-300">
                <Icons.cube size={16} />
              </span>
              <span className="font-mono text-sm text-slate-200">{r.name}</span>
            </div>
            <Badge tone="green" dot>Çalışıyor</Badge>
          </Card>
        ))}
      </div>
    </>
  );
}
