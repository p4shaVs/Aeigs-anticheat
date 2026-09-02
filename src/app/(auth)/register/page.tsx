import type { Metadata } from "next";
import { Suspense } from "react";
import { AuthForm } from "@/components/auth-form";

export const metadata: Metadata = { title: "Kayıt Ol" };

export default function RegisterPage() {
  return (
    <Suspense fallback={<div className="text-sm text-slate-500">Yükleniyor…</div>}>
      <AuthForm mode="register" />
    </Suspense>
  );
}
