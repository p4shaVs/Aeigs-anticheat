"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { Card, Badge, EmptyState } from "@/components/ui";
import { Icons } from "@/components/icons";
import { cn } from "@/lib/utils";

export interface BlacklistRow {
  id: string;
  kind: string;
  model: string;
  label: string | null;
  action: string;
  enabled: boolean;
}

const KINDS = [
  { key: "vehicle", label: "Araç", ph: "adder" },
  { key: "weapon", label: "Silah", ph: "weapon_rpg" },
  { key: "object", label: "Nesne", ph: "prop_..." },
  { key: "ped", label: "Ped", ph: "s_m_y_cop_01" },
] as const;

const ACTIONS = [
  { key: "REMOVE", label: "Kaldır" },
  { key: "KICK", label: "At (Kick)" },
  { key: "BAN", label: "Yasakla" },
] as const;

const kindTone: Record<string, "green" | "amber" | "red" | "blue" | "violet"> = {
  vehicle: "blue",
  weapon: "red",
  object: "amber",
  ped: "violet",
};
const actionTone: Record<string, "green" | "amber" | "red"> = {
  REMOVE: "amber",
  KICK: "amber",
  BAN: "red",
};

export function BlacklistManager({ serverId, rows }: { serverId: string; rows: BlacklistRow[] }) {
  const router = useRouter();
  const [kind, setKind] = useState<(typeof KINDS)[number]["key"]>("vehicle");
  const [model, setModel] = useState("");
  const [label, setLabel] = useState("");
  const [action, setAction] = useState<(typeof ACTIONS)[number]["key"]>("REMOVE");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function add() {
    if (model.trim().length < 1) {
      setError("Model adı girin.");
      return;
    }
    setLoading(true);
    setError(null);
    try {
      const res = await fetch(`/api/servers/${serverId}/blacklist`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ kind, model: model.trim(), label: label.trim() || undefined, action }),
      });
      const json = await res.json();
      if (!res.ok || !json.ok) throw new Error(json.error ?? "Eklenemedi");
      setModel("");
      setLabel("");
      router.refresh();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Hata");
    } finally {
      setLoading(false);
    }
  }

  async function toggle(id: string, enabled: boolean) {
    await fetch(`/api/servers/${serverId}/blacklist`, {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ id, enabled }),
    });
    router.refresh();
  }

  async function remove(id: string) {
    await fetch(`/api/servers/${serverId}/blacklist`, {
      method: "DELETE",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ id }),
    });
    router.refresh();
  }

  const active = KINDS.find((k) => k.key === kind)!;

  return (
    <div className="grid gap-4 lg:grid-cols-[340px_1fr]">
      <Card className="h-fit">
        <h3 className="mb-3 flex items-center gap-2 text-sm font-semibold text-white">
          <Icons.ban size={16} className="text-rose-400" /> Kara Listeye Ekle
        </h3>
        <label className="label">Tür</label>
        <div className="mb-3 grid grid-cols-2 gap-1.5">
          {KINDS.map((k) => (
            <button
              key={k.key}
              onClick={() => setKind(k.key)}
              className={cn(
                "rounded-lg border px-2 py-1.5 text-xs font-medium transition",
                kind === k.key ? "border-brand-500/50 bg-brand-500/10 text-white" : "border-white/10 text-slate-400 hover:bg-white/5"
              )}
            >
              {k.label}
            </button>
          ))}
        </div>
        <label className="label">Model adı / hash</label>
        <input
          className="input mb-3 font-mono"
          placeholder={active.ph}
          value={model}
          onChange={(e) => setModel(e.target.value)}
          onKeyDown={(e) => e.key === "Enter" && add()}
        />
        <label className="label">Etiket (opsiyonel)</label>
        <input
          className="input mb-3"
          placeholder="Örn. Yasak spor araba"
          value={label}
          onChange={(e) => setLabel(e.target.value)}
        />
        <label className="label">İhlal halinde</label>
        <div className="mb-3 grid grid-cols-3 gap-1.5">
          {ACTIONS.map((a) => (
            <button
              key={a.key}
              onClick={() => setAction(a.key)}
              className={cn(
                "rounded-lg border px-2 py-1.5 text-xs font-medium transition",
                action === a.key ? "border-brand-500/50 bg-brand-500/10 text-white" : "border-white/10 text-slate-400 hover:bg-white/5"
              )}
            >
              {a.label}
            </button>
          ))}
        </div>
        {error && <p className="mb-2 text-sm text-rose-400">{error}</p>}
        <button className="btn-primary w-full" onClick={add} disabled={loading}>
          <Icons.plus size={16} /> {loading ? "Ekleniyor…" : "Kara Listeye Ekle"}
        </button>
      </Card>

      <div className="overflow-hidden rounded-2xl border border-white/5 bg-base-850/60">
        {rows.length === 0 ? (
          <EmptyState icon="ban" title="Kara liste boş" description="Yasaklamak istediğiniz araç, silah, ped veya nesne modelini ekleyin." />
        ) : (
          <table className="w-full min-w-[620px] text-sm">
            <thead>
              <tr className="border-b border-white/5 text-left text-xs uppercase tracking-wide text-slate-500">
                <th className="px-4 py-3 font-medium">Tür</th>
                <th className="px-4 py-3 font-medium">Model</th>
                <th className="px-4 py-3 font-medium">Etiket</th>
                <th className="px-4 py-3 font-medium">İşlem</th>
                <th className="px-4 py-3 font-medium">Durum</th>
                <th className="px-4 py-3 text-right font-medium"></th>
              </tr>
            </thead>
            <tbody>
              {rows.map((r) => (
                <tr key={r.id} className={cn("border-b border-white/5 last:border-0 hover:bg-white/[0.02]", !r.enabled && "opacity-50")}>
                  <td className="px-4 py-3"><Badge tone={kindTone[r.kind] ?? "blue"}>{r.kind}</Badge></td>
                  <td className="px-4 py-3 font-mono text-xs text-slate-300">{r.model}</td>
                  <td className="px-4 py-3 text-slate-500">{r.label ?? "—"}</td>
                  <td className="px-4 py-3"><Badge tone={actionTone[r.action] ?? "amber"}>{r.action}</Badge></td>
                  <td className="px-4 py-3">
                    <button
                      onClick={() => toggle(r.id, !r.enabled)}
                      className={cn(
                        "rounded-md px-2 py-1 text-xs font-medium transition",
                        r.enabled ? "bg-emerald-500/10 text-emerald-300 hover:bg-emerald-500/20" : "bg-white/5 text-slate-400 hover:bg-white/10"
                      )}
                    >
                      {r.enabled ? "Aktif" : "Pasif"}
                    </button>
                  </td>
                  <td className="px-4 py-3 text-right">
                    <button
                      onClick={() => remove(r.id)}
                      title="Sil"
                      className="grid h-8 w-8 place-items-center rounded-lg border border-white/10 text-slate-400 transition hover:border-rose-500/40 hover:text-rose-300"
                    >
                      <Icons.trash size={15} />
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );
}
