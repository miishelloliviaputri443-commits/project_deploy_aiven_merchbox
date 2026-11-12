"use client";

import { useEffect, useState } from "react";

export default function AuthPage() {
  const [mode, setMode] = useState("login");
  const [form, setForm] = useState({ name: "", email: "", password: "" });
  const [error, setError] = useState("");
  const [message, setMessage] = useState("");
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetch("/api/auth/me", { cache: "no-store" })
      .then((response) => response.json())
      .then((result) => {
        if (result.data) {
          window.location.href =
            result.data.role === "admin" ? "/admin" : "/shop";
        }
      })
      .catch(() => {})
      .finally(() => setLoading(false));
  }, []);

  async function submit(event) {
    event.preventDefault();
    setError("");
    setMessage("");
    try {
      const response = await fetch(`/api/auth/${mode}`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(form),
      });
      const result = await response.json();
      if (!response.ok) throw new Error(result.message || "Autentikasi gagal.");
      const sessionResponse = await fetch("/api/auth/me", { cache: "no-store" });
      const session = await sessionResponse.json();
      if (!sessionResponse.ok || !session.data) {
        throw new Error(session.message || "Gagal memeriksa sesi.");
      }
      window.location.href = session.data.role === "admin" ? "/admin" : "/shop";
    } catch (submitError) {
      setError(submitError.message);
    }
  }

  if (loading) return <main className="auth-page"><p className="muted">Memeriksa sesi...</p></main>;

  return (
    <main className="auth-page">
      <section className="auth-panel">
        <div className="brand">MERCH<span>BOX</span></div>
        <p className="eyebrow">Merchandise Maker & Shop</p>
        <h1>{mode === "login" ? "Selamat datang kembali." : "Buat akun baru."}</h1>
        <p className="muted">
          {mode === "login"
            ? "Login untuk memesan produk dan mengirim permintaan barang."
            : "Buat akun untuk berbelanja dan menghubungi pengelola."}
        </p>
        {error && <p className="error">{error}</p>}
        {message && <p className="notice">{message}</p>}
        <form className="auth-form" onSubmit={submit}>
          {mode === "register" && (
            <input
              placeholder="Nama"
              required
              value={form.name}
              onChange={(event) => setForm({ ...form, name: event.target.value })}
            />
          )}
          <input
            type="email"
            placeholder="Email"
            required
            value={form.email}
            onChange={(event) => setForm({ ...form, email: event.target.value })}
          />
          <input
            type="password"
            placeholder="Password minimal 8 karakter"
            minLength="8"
            required
            value={form.password}
            onChange={(event) => setForm({ ...form, password: event.target.value })}
          />
          <button className="btn primary" type="submit">
            {mode === "login" ? "Login" : "Register"}
          </button>
        </form>
        <button
          className="link-button"
          onClick={() => {
            setMode(mode === "login" ? "register" : "login");
            setError("");
            setMessage("");
          }}
        >
          {mode === "login" ? "Belum punya akun? Register" : "Sudah punya akun? Login"}
        </button>
      </section>
    </main>
  );
}
