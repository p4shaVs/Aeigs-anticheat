import { NextRequest, NextResponse } from "next/server";
import { verifySession } from "@/lib/jwt";
import { SESSION_COOKIE } from "@/lib/session";

// Edge middleware: /dashboard ve /admin için kaba erişim kontrolü.
// DB doğrulaması route/sayfa seviyesinde (getCurrentUser) yeniden yapılır.

export async function middleware(req: NextRequest) {
  const { pathname } = req.nextUrl;
  const token = req.cookies.get(SESSION_COOKIE)?.value;
  const claims = token ? await verifySession(token) : null;

  const isDashboard = pathname.startsWith("/dashboard");
  const isAdmin = pathname.startsWith("/admin");
  const isAuthPage = pathname === "/login" || pathname === "/register";

  // Giriş yapmamışsa korumalı alanları engelle.
  if ((isDashboard || isAdmin) && !claims) {
    const url = new URL("/login", req.url);
    url.searchParams.set("next", pathname);
    return NextResponse.redirect(url);
  }

  // Admin alanı yalnızca ADMIN.
  if (isAdmin && claims?.role !== "ADMIN") {
    return NextResponse.redirect(new URL("/dashboard", req.url));
  }

  // Giriş yapmış kullanıcı login/register görürse panele gönder.
  if (isAuthPage && claims) {
    const dest = claims.role === "ADMIN" ? "/admin" : "/dashboard";
    return NextResponse.redirect(new URL(dest, req.url));
  }

  return NextResponse.next();
}

export const config = {
  matcher: ["/dashboard/:path*", "/admin/:path*", "/login", "/register"],
};
