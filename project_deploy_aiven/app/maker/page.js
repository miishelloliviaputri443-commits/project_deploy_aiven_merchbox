"use client";
import { useEffect, useState } from "react";
const money = (n) =>
  new Intl.NumberFormat("id-ID", {
    style: "currency",
    currency: "IDR",
    maximumFractionDigits: 0,
  }).format(n);
const empty = {
  name: "",
  description: "",
  category: "Gantungan Kunci",
  price: "8000",
  stock: "10",
  imageUrl: "",
  isPublished: false,
};
export default function MakerPage() {
  const [products, setProducts] = useState([]),
    [requests, setRequests] = useState([]),
    [error, setError] = useState(""),
    [message, setMessage] = useState(""),
    [show, setShow] = useState(false),
    [showRequests, setShowRequests] = useState(false),
    [form, setForm] = useState(empty),
    [editId, setEditId] = useState(null),
    [user, setUser] = useState(null),
    [checkingSession, setCheckingSession] = useState(true);
  async function load() {
    try {
      const r = await fetch("/api/products?admin=1", { cache: "no-store" }),
        j = await r.json();
      if (!r.ok) throw Error(j.message || "Gagal memuat produk");
      setProducts(j.data || []);
      setError("");
    } catch (e) {
      setError(e.message);
    }
  }
  async function loadRequests() {
    const r = await fetch("/api/requests", { cache: "no-store" });
    const j = await r.json();
    if (!r.ok) throw Error(j.message || "Gagal memuat permintaan");
    setRequests(j.data || []);
  }
  useEffect(() => {
    fetch("/api/auth/me", { cache: "no-store" })
      .then((r) => r.json())
      .then((j) => {
        if (!j.data) {
          window.location.href = "/auth";
          return;
        }
        if (j.data.role !== "admin") {
          window.location.href = "/shop";
          return;
        }
        setUser(j.data);
        load();
        loadRequests().catch((e) => setError(e.message));
      })
      .catch((sessionError) => {
        setError(sessionError.message || "Gagal memeriksa sesi admin.");
        window.location.replace("/auth");
      })
      .finally(() => setCheckingSession(false));
  }, []);
  useEffect(() => {
    if (user?.role !== "admin") return;
    const intervalId = window.setInterval(() => {
      loadRequests().catch((e) => setError(e.message));
    }, 30000);
    return () => window.clearInterval(intervalId);
  }, [user]);
  async function logout() {
    const r = await fetch("/api/auth/logout", { method: "POST" });
    const j = await r.json();
    if (!r.ok) {
      setError(j.message || "Logout gagal");
      return;
    }
    setUser(null);
    window.location.href = "/auth";
  }
  if (checkingSession) {
    return <main className="auth-page"><p className="muted">Memuat halaman...</p></main>;
  }
  if (!user) {
    return (
      <main className="auth-page">
        <section className="auth-panel">
          <h1>Akses admin diperlukan</h1>
          <p className="muted">{error || "Silakan login menggunakan akun admin."}</p>
          <a className="btn primary" href="/auth">Ke halaman login</a>
        </section>
      </main>
    );
  }
  async function save(e) {
    e.preventDefault();
    try {
      const r = await fetch(
          editId ? `/api/products/${editId}` : "/api/products",
          {
            method: editId ? "PUT" : "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({
              ...form,
              price: Number(form.price),
              stock: Number(form.stock),
              isPublished: form.isPublished,
            }),
          },
        ),
        j = await r.json();
      if (!r.ok) throw Error(j.message || "Gagal menyimpan");
      setMessage(j.message || "Berhasil");
      setForm(empty);
      setEditId(null);
      setShow(false);
      await load();
    } catch (e) {
      setError(e.message);
    }
  }
  async function remove(p) {
    if (!confirm(`Hapus ${p.name}?`)) return;
    try {
      const r = await fetch(`/api/products/${p.id}`, { method: "DELETE" }),
        j = await r.json();
      if (!r.ok) throw Error(j.message || "Gagal menghapus");
      setMessage("Produk berhasil dihapus");
      await load();
    } catch (e) {
      setError(e.message);
    }
  }
  async function markRequestRead(requestId) {
    try {
      const r = await fetch(`/api/requests/${requestId}`, { method: "PATCH" });
      const j = await r.json();
      if (!r.ok) throw Error(j.message || "Gagal memperbarui permintaan");
      await loadRequests();
    } catch (e) {
      setError(e.message);
    }
  }
  return (
    <>
      <header className="header">
        <div className="brand">
          MERCH<span>BOX</span>
        </div>
        <div className="header-actions">
          {user && (
            <>
              <span className="muted">Halo, {user.name}</span>
              <button
                className="btn secondary"
                onClick={() => setShowRequests(!showRequests)}
              >
                Permintaan masuk ({requests.filter((request) => !request.isRead).length})
              </button>
              <button className="btn secondary" onClick={logout}>Logout</button>
              <button
                className="btn primary"
                onClick={() => {
                  setEditId(null);
                  setForm(empty);
                  setShow(!show);
                }}
              >
                {show ? "Tutup Form" : "Tambah Barang"}
              </button>
            </>
          )}
        </div>
      </header>
      <section className="hero">
        <div className="eyebrow">Halaman Maker · Admin MerchBox</div>
        <h1>
          Kelola
          <br />
          merchandise.
        </h1>
        <p>Tambah, edit, hapus, dan publikasikan barang untuk pengguna.</p>
      </section>
      <main className="main">
        <h2>Kelola Barang</h2>
        <p className="muted">Tambah barang baru, ubah data, hapus, atau atur status publikasi.</p>
        {error && <p className="error">{error}</p>}
        {message && <p className="notice">{message}</p>}
        {user && showRequests && (
          <section className="admin">
            <h2>Notifikasi permintaan barang</h2>
            {!requests.length ? (
              <p className="muted">Belum ada permintaan barang.</p>
            ) : (
              <div className="request-list">
                {requests.map((request) => (
                  <article className={`request-item${request.isRead ? "" : " unread"}`} key={request.id}>
                    <div className="request-item-heading">
                      <div>
                        <b>{request.productName}</b>
                        <p className="muted">
                          {request.name} · <a href={`mailto:${request.email}`}>{request.email}</a>
                        </p>
                      </div>
                      {!request.isRead && (
                        <button
                          className="btn secondary"
                          onClick={() => markRequestRead(request.id)}
                        >
                          Tandai dibaca
                        </button>
                      )}
                    </div>
                    <p>{request.message}</p>
                    <small className="muted">{new Date(request.createdAt).toLocaleString("id-ID")}</small>
                  </article>
                ))}
              </div>
            )}
          </section>
        )}
        {show && (
          <section className="admin">
            <h2>{editId ? "Edit Produk" : "Tambah Produk"}</h2>
            <form className="form" onSubmit={save}>
              <input
                placeholder="Nama produk"
                required
                value={form.name}
                onChange={(e) => setForm({ ...form, name: e.target.value })}
              />
              <select
                required
                value={form.category}
                aria-label="Kategori"
                onChange={(e) => setForm({ ...form, category: e.target.value })}
              >
                <option value="Gantungan Kunci">Gantungan Kunci</option>
                <option value="Pin">Pin</option>
              </select>
              <input
                placeholder="Harga"
                type="number"
                min="0"
                required
                value={form.price}
                onChange={(e) => setForm({ ...form, price: e.target.value })}
              />
              <input
                placeholder="Stok"
                type="number"
                min="0"
                required
                value={form.stock}
                onChange={(e) => setForm({ ...form, stock: e.target.value })}
              />
              <input
                placeholder="URL gambar (opsional)"
                value={form.imageUrl}
                onChange={(e) => setForm({ ...form, imageUrl: e.target.value })}
              />
              <label className="publish-option">
                <input
                  type="checkbox"
                  checked={form.isPublished}
                  onChange={(e) =>
                    setForm({ ...form, isPublished: e.target.checked })
                  }
                />
                Publikasikan agar tampil dan dapat dipesan pengguna
              </label>
              <textarea
                placeholder="Deskripsi"
                required
                value={form.description}
                onChange={(e) =>
                  setForm({ ...form, description: e.target.value })
                }
              />
              <button className="btn primary">
                {editId ? "Simpan Perubahan" : "Tambah Produk"}
              </button>
              <button
                className="btn secondary"
                type="button"
                onClick={() => {
                  setShow(false);
                  setEditId(null);
                  setForm(empty);
                }}
              >
                Batal
              </button>
            </form>
          </section>
        )}
        <section className="maker-products">
          <div className="shop-heading">
            <div>
              <h2>Data Merchandise</h2>
              <p className="muted">Perubahan yang disimpan akan tampil di katalog pengguna.</p>
            </div>
            <span className="muted">{products.length} produk</span>
          </div>
          {products.length ? (
            <div className="grid">
              {products.map((p) => (
                <article className="product" key={p.id}>
                  <div className="art">
                    {p.imageUrl ? (
                      <img src={p.imageUrl} alt={p.name} />
                    ) : (
                      { Pin: "📌", "Gantungan Kunci": "🔑" }[p.category] || "🎁"
                    )}
                  </div>
                  <div className="info">
                    <span className="tag">{p.category}</span>
                    <h3>{p.name}</h3>
                    <p className="desc">{p.description}</p>
                    <div className="price-row">
                      <b>{money(p.price)}</b>
                      <span className="muted">Stok {p.stock}</span>
                    </div>
                    <div className="maker-actions">
                      <button
                        className="btn secondary"
                        onClick={() => {
                          setEditId(p.id);
                          setForm({
                            name: p.name,
                            description: p.description,
                            category: p.category,
                            price: String(p.price),
                            stock: String(p.stock),
                            imageUrl: p.imageUrl || "",
                            isPublished: Boolean(p.isPublished),
                          });
                          setShow(true);
                          window.scrollTo({ top: 0, behavior: "smooth" });
                        }}
                      >
                        Edit
                      </button>
                      <button className="btn secondary" onClick={() => remove(p)}>
                        Hapus
                      </button>
                    </div>
                  </div>
                </article>
              ))}
            </div>
          ) : (
            <p className="empty-state">Belum ada data merchandise.</p>
          )}
        </section>
      </main>
      <footer className="footer">Next.js · Vercel · Aiven MySQL</footer>
    </>
  );
}
