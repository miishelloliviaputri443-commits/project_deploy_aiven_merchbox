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
};
export default function HomePage() {
  const [products, setProducts] = useState([]),
    [error, setError] = useState(""),
    [message, setMessage] = useState(""),
    [show, setShow] = useState(false),
    [form, setForm] = useState(empty),
    [editId, setEditId] = useState(null);
  async function load() {
    try {
      const r = await fetch("/api/products", { cache: "no-store" }),
        j = await r.json();
      if (!r.ok) throw Error(j.message || "Gagal memuat produk");
      setProducts(j.data || []);
      setError("");
    } catch (e) {
      setError(e.message);
    }
  }
  useEffect(() => {
    load();
  }, []);
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
            }),
          },
        ),
        j = await r.json();
      if (!r.ok) throw Error(j.message || "Gagal menyimpan");
      setMessage(j.message || "Berhasil");
      setForm(empty);
      setEditId(null);
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
  return (
    <>
      <header className="header">
        <div className="brand">
          MERCH<span>BOX</span>
        </div>
        <button className="btn secondary" onClick={() => setShow(!show)}>
          {show ? "Tutup CRUD" : "Kelola Produk (CRUD)"}
        </button>
      </header>
      <section className="hero">
        <div className="eyebrow">Merchandise Delivery</div>
        <h1>
          Barang kecil,
          <br />
          kenangan besar.
        </h1>
        <p>Pin, gantungan kunci akrilik, dan merchandise pilihan.</p>
      </section>
      <main className="main">
        <h2>Koleksi Merchandise</h2>
        <p className="muted">Produk tersimpan di MySQL Aiven.</p>
        {error && <p className="error">{error}</p>}
        {message && <p className="notice">{message}</p>}
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
              <input
                placeholder="Kategori"
                required
                value={form.category}
                onChange={(e) => setForm({ ...form, category: e.target.value })}
              />
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
            </form>
            <h3>Data Produk</h3>
            <div style={{ overflowX: "auto" }}>
              <table className="admin-table">
                <thead>
                  <tr>
                    <th>Nama</th>
                    <th>Kategori</th>
                    <th>Harga</th>
                    <th>Stok</th>
                    <th>Aksi</th>
                  </tr>
                </thead>
                <tbody>
                  {products.map((p) => (
                    <tr key={p.id}>
                      <td>{p.name}</td>
                      <td>{p.category}</td>
                      <td>{money(p.price)}</td>
                      <td>{p.stock}</td>
                      <td>
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
                            });
                          }}
                        >
                          Edit
                        </button>{" "}
                        <button
                          className="btn secondary"
                          onClick={() => remove(p)}
                        >
                          Hapus
                        </button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </section>
        )}
        <div className="grid">
          {products.map((p) => (
            <article className="product" key={p.id}>
              <div className="art">
                {p.imageUrl ? (
                  <img
                    src={p.imageUrl}
                    alt={p.name}
                    style={{
                      width: "100%",
                      height: "100%",
                      objectFit: "cover",
                    }}
                  />
                ) : (
                  { Pin: "📌", "Gantungan Kunci": "🔑", Stiker: "✨" }[
                    p.category
                  ] || "🎁"
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
              </div>
            </article>
          ))}
        </div>
      </main>
      <footer className="footer">Next.js · Vercel · Aiven MySQL</footer>
    </>
  );
}
