import type { Metadata } from "next";
import { Suspense } from "react";
import { AuthForm } from "@/components/auth-form";

export const metadata: Metadata = { title: "Giriş Yap" };

export default function LoginPage() {
  return (
    <Suspense fallback={<div className="text-sm text-slate-500">Yükleniyor…</div>}>
      <AuthForm mode="login" />
    </Suspense>
  );
}
