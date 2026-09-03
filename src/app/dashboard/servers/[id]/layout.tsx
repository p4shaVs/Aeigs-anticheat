import { getOwnedServer } from "@/lib/guards";

// Sunucu menüsü artık sol sidebar'da (PanelShell) gösteriliyor.
// Bu layout sadece sahiplik kontrolü yapar.
export default async function ServerLayout({
  children,
  params,
}: {
  children: React.ReactNode;
  params: { id: string };
}) {
  await getOwnedServer(params.id);
  return <>{children}</>;
}
