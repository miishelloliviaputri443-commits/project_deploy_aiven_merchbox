"use client";

import { useEffect, useState } from "react";

export default function HomePage() {
  const [checking, setChecking] = useState(true);

  useEffect(() => {
    fetch("/api/auth/me", { cache: "no-store" })
      .then((response) => response.json())
      .then((result) => {
        window.location.replace(result.data?.role === "admin" ? "/admin" : "/shop");
      })
      .catch(() => {
        window.location.replace("/shop");
      })
      .finally(() => setChecking(false));
  }, []);

  return (
    <main className="auth-page">
      <p className="muted">{checking ? "Mengarahkan ke halaman..." : "Memuat..."}</p>
    </main>
  );
}
