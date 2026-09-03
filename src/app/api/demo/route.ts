import { NextRequest, NextResponse } from "next/server";
import { db } from "@/lib/db";
import { createSession } from "@/lib/session";

// Tek tıkla demo girişi: demo hesabıyla oturum açar ve panele yönlendirir.
// (electron-services'teki "Demo" akışının karşılığı)
export async function GET(req: NextRequest) {
  const demo = await db.user.findUnique({ where: { email: "demo@aeigs.gg" } });
  if (!demo) {
    // Seed yapılmadıysa normal giriş sayfasına gönder.
    return NextResponse.redirect(new URL("/login", req.url));
  }
  await createSession(demo.id);
  return NextResponse.redirect(new URL("/dashboard", req.url));
}
