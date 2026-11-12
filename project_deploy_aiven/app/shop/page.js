"use client";

import { useEffect, useState } from "react";

const money = (value) =>
  new Intl.NumberFormat("id-ID", {
    style: "currency",
    currency: "IDR",
    maximumFractionDigits: 0,
  }).format(value);

export default function ShopPage() {
  const [products, setProducts] = useState([]);
  const [user, setUser] = useState(null);
  const [quantities, setQuantities] = useState({});
  const [orderingId, setOrderingId] = useState(null);
  const [requestProduct, setRequestProduct] = useState(null);
  const [requestMessage, setRequestMessage] = useState("");
  const [error, setError] = useState("");
  const [notice, setNotice] = useState("");
  const [loading, setLoading] = useState(true);

  async function loadProducts() {
    const response = await fetch("/api/products", { cache: "no-store" });
    const result = await response.json();
    if (!response.ok) throw new Error(result.message || "Gagal memuat produk.");
    setProducts(result.data || []);
  }

  useEffect(() => {
    Promise.all([
      loadProducts(),
      fetch("/api/auth/me", { cache: "no-store" })
        .then((response) => response.json())
        .then((result) => setUser(result.data || null)),
    ])
      .catch((loadError) => setError(loadError.message))
      .finally(() => setLoading(false));
  }, []);
  useEffect(() => {
    if (user?.role === "admin") {
      window.location.replace("/admin");
    }
  }, [user]);
  useEffect(() => {
    const refreshProducts = () => {
      fetch("/api/products", { cache: "no-store" })
        .then((response) => response.json())
        .then((result) => {
          if (!result.success) throw new Error(result.message || "Gagal memuat produk.");
          setProducts(result.data || []);
        })
        .catch((refreshError) => setError(refreshError.message));
    };
    const intervalId = window.setInterval(refreshProducts, 30000);
    window.addEventListener("focus", refreshProducts);
    return () => {
      window.clearInterval(intervalId);
      window.removeEventListener("focus", refreshProducts);
    };
  }, []);

  async function placeOrder(product) {
    setError("");
    setNotice("");
    setOrderingId(product.id);
    try {
      const response = await fetch("/api/orders", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          productId: product.id,
          quantity: Number(quantities[product.id] || 1),
        }),
      });
      const result = await response.json();
      if (!response.ok) throw new Error(result.message || "Gagal membuat pesanan.");
      setNotice(result.message);
      await loadProducts();
    } catch (orderError) {
      setError(orderError.message);
    } finally {
      setOrderingId(null);
    }
  }

  async function sendRequest(event) {
    event.preventDefault();
    setError("");
    setNotice("");
    try {
      const response = await fetch("/api/requests", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          productName: requestProduct.name,
          message: requestMessage,
        }),
      });
      const result = await response.json();
      if (!response.ok) throw new Error(result.message || "Gagal mengirim permintaan.");

      setNotice(result.message);
      setRequestProduct(null);
      setRequestMessage("");
      if (result.data.adminEmail) {
        const subject = encodeURIComponent(`Permintaan barang: ${requestProduct.name}`);
        const body = encodeURIComponent(
          `Nama: ${user.name}\nEmail: ${user.email}\nBarang: ${requestProduct.name}\n\n${requestMessage}`,
        );
        window.location.href = `mailto:${result.data.adminEmail}?subject=${subject}&body=${body}`;
      }
    } catch (requestError) {
      setError(requestError.message);
    }
  }

  return (
    <>
      <header className="header">
        <a className="brand brand-link" href="/shop">
          MERCH<span>BOX</span>
        </a>
        <nav className="header-actions">
          {user ? (
            <>
              <span className="muted">Halo, {user.name}</span>
              {user.role === "admin" && (
                <a className="btn secondary" href="/admin">
                  Panel Admin
                </a>
              )}
              <button
                className="btn secondary"
                onClick={async () => {
                  try {
                    const response = await fetch("/api/auth/logout", { method: "POST" });
                    const result = await response.json();
                    if (!response.ok) {
                      throw new Error(result.message || "Logout gagal.");
                    }
                    setUser(null);
                  } catch (logoutError) {
                    setError(logoutError.message);
                  }
                }}
              >
                Logout
              </button>
            </>
          ) : (
            <a className="btn secondary" href="/auth?next=%2Fshop">
              Login untuk membeli
            </a>
          )}
        </nav>
      </header>

      <section className="hero shop-hero">
        <div className="eyebrow">Koleksi MerchBox</div>
        <h1>
          Temukan barang
          <br />
          favoritmu.
        </h1>
        <p>Produk pilihan yang sudah tersedia untuk dipesan.</p>
        <a className="btn primary" href="#produk">
          Lihat produk
        </a>
      </section>

      <main className="main" id="produk">
        <div className="shop-heading">
          <div>
            <h2>Produk tersedia</h2>
            <p className="muted">Pesanan akan menunggu konfirmasi admin.</p>
          </div>
          <span className="muted">{products.length} produk</span>
        </div>
        {error && <p className="error">{error}</p>}
        {notice && <p className="notice">{notice}</p>}
        {loading ? (
          <p className="muted">Memuat produk...</p>
        ) : products.length ? (
          <div className="grid">
            {products.map((product) => (
              <article className="product" key={product.id}>
                <div className="art">
                  {product.imageUrl ? (
                    <img src={product.imageUrl} alt={product.name} />
                  ) : (
                    { Pin: "📌", "Gantungan Kunci": "🔑" }[product.category] || "🎁"
                  )}
                </div>
                <div className="info">
                  <span className="tag">{product.category}</span>
                  <h3>{product.name}</h3>
                  <p className="desc">{product.description}</p>
                  <div className="price-row">
                    <b>{money(product.price)}</b>
                    <span className="muted">Stok {product.stock}</span>
                  </div>
                  {user ? (
                    <div className="shop-actions">
                      <label className="quantity-field">
                        Jumlah
                        <input
                          aria-label={`Jumlah ${product.name}`}
                          type="number"
                          min="1"
                          max={product.stock}
                          value={quantities[product.id] || 1}
                          onChange={(event) =>
                            setQuantities({
                              ...quantities,
                              [product.id]: event.target.value,
                            })
                          }
                        />
                      </label>
                      <button
                        className="btn primary"
                        disabled={
                          orderingId === product.id ||
                          !Number.isInteger(Number(quantities[product.id] || 1)) ||
                          Number(quantities[product.id] || 1) < 1 ||
                          Number(quantities[product.id] || 1) > product.stock
                        }
                        onClick={() => placeOrder(product)}
                      >
                        {orderingId === product.id ? "Memesan..." : "Pesan"}
                      </button>
                      <button
                        className="link-button"
                        onClick={() => {
                          setRequestProduct(product);
                          setRequestMessage("");
                        }}
                      >
                        Minta barang
                      </button>
                    </div>
                  ) : (
                    <a className="btn primary shop-login" href="/auth?next=%2Fshop">
                      Login untuk memesan
                    </a>
                  )}
                </div>
              </article>
            ))}
          </div>
        ) : (
          <p className="empty-state">Belum ada produk yang dipublikasikan.</p>
        )}
      </main>

      {requestProduct && (
        <div className="modal-backdrop" role="presentation">
          <section
            aria-labelledby="request-title"
            aria-modal="true"
            className="request-modal"
            role="dialog"
          >
            <button
              aria-label="Tutup form"
              className="modal-close"
              onClick={() => setRequestProduct(null)}
            >
              ×
            </button>
            <div className="eyebrow">Kirim pesan ke admin</div>
            <h2 id="request-title">Minta {requestProduct.name}</h2>
            <p className="muted">
              Pesan akan masuk ke notifikasi admin. Jika email admin sudah diatur,
              aplikasi email Anda juga akan terbuka.
            </p>
            <form className="request-form" onSubmit={sendRequest}>
              <label>
                Pesan
                <textarea
                  autoFocus
                  maxLength="3000"
                  placeholder="Tulis jumlah atau detail barang yang Anda inginkan..."
                  required
                  value={requestMessage}
                  onChange={(event) => setRequestMessage(event.target.value)}
                />
              </label>
              <button className="btn primary" type="submit">
                Kirim permintaan
              </button>
            </form>
          </section>
        </div>
      )}
      <footer className="footer">MerchBox · Merchandise pilihan</footer>
    </>
  );
}
