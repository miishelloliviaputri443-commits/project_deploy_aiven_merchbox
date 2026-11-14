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
  const [searchQuery, setSearchQuery] = useState("");
  const [user, setUser] = useState(null);
  const [quantities, setQuantities] = useState({});
  const [cart, setCart] = useState([]);
  const [cartOpen, setCartOpen] = useState(false);
  const [checkingOut, setCheckingOut] = useState(false);
  const [updatingCartId, setUpdatingCartId] = useState(null);
  const [requestOpen, setRequestOpen] = useState(false);
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

  async function loadCart() {
    const response = await fetch("/api/cart", { cache: "no-store" });
    const result = await response.json();
    if (!response.ok) throw new Error(result.message || "Gagal memuat keranjang.");
    setCart(result.data || []);
  }

  useEffect(() => {
    async function initializeShop() {
      try {
        const [sessionResponse] = await Promise.all([
          fetch("/api/auth/me", { cache: "no-store" }),
          loadProducts(),
        ]);
        const session = await sessionResponse.json();
        if (!sessionResponse.ok) {
          throw new Error(session.message || "Gagal memeriksa sesi.");
        }
        setUser(session.data || null);
        if (session.data && session.data.role !== "admin") {
          await loadCart();
        }
      } catch (loadError) {
        setError(loadError.message);
      } finally {
        setLoading(false);
      }
    }
    initializeShop();
  }, []);
  useEffect(() => {
    if (user?.role === "admin") {
      window.location.replace("/maker");
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
      if (user && user.role !== "admin") {
        loadCart().catch((refreshError) => setError(refreshError.message));
      }
    };
    const intervalId = window.setInterval(refreshProducts, 30000);
    window.addEventListener("focus", refreshProducts);
    return () => {
      window.clearInterval(intervalId);
      window.removeEventListener("focus", refreshProducts);
    };
  }, [user]);

  async function addToCart(product) {
    setError("");
    setNotice("");
    const quantity = Number(quantities[product.id] || 1);
    if (!Number.isInteger(quantity) || quantity < 1 || quantity > product.stock) {
      setError("Jumlah produk tidak valid atau melebihi stok.");
      return;
    }

    const currentItem = cart.find((item) => item.productId === product.id);
    setUpdatingCartId(product.id);
    try {
      const response = await fetch("/api/cart", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          productId: product.id,
          quantity: (currentItem?.quantity || 0) + quantity,
        }),
      });
      const result = await response.json();
      if (!response.ok) throw new Error(result.message || "Gagal menambahkan barang.");
      await Promise.all([loadCart(), loadProducts()]);
      setNotice(`${product.name} ditambahkan ke keranjang dan stok direservasi.`);
    } catch (cartError) {
      setError(cartError.message);
    } finally {
      setUpdatingCartId(null);
    }
  }

  async function updateCartQuantity(productId, quantity) {
    setError("");
    setUpdatingCartId(productId);
    try {
      const response = await fetch("/api/cart", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ productId, quantity }),
      });
      const result = await response.json();
      if (!response.ok) throw new Error(result.message || "Gagal mengubah jumlah.");
      await Promise.all([loadCart(), loadProducts()]);
    } catch (cartError) {
      setError(cartError.message);
    } finally {
      setUpdatingCartId(null);
    }
  }

  async function removeCartItem(productId) {
    setError("");
    setUpdatingCartId(productId);
    try {
      const response = await fetch(`/api/cart?productId=${productId}`, {
        method: "DELETE",
      });
      const result = await response.json();
      if (!response.ok) throw new Error(result.message || "Gagal menghapus barang.");
      await Promise.all([loadCart(), loadProducts()]);
    } catch (cartError) {
      setError(cartError.message);
    } finally {
      setUpdatingCartId(null);
    }
  }

  async function checkout() {
    if (!user) {
      window.location.href = "/auth?next=%2Fshop";
      return;
    }
    if (!cart.length) return;

    setError("");
    setNotice("");
    setCheckingOut(true);
    try {
      const response = await fetch("/api/orders", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          items: cart.map(({ productId, quantity }) => ({ productId, quantity })),
        }),
      });
      const result = await response.json();
      if (!response.ok) throw new Error(result.message || "Checkout gagal.");
      setNotice(result.message);
      setCart([]);
      setCartOpen(false);
      await loadProducts();
    } catch (checkoutError) {
      setError(checkoutError.message);
    } finally {
      setCheckingOut(false);
    }
  }

  const cartCount = cart.reduce((total, item) => total + item.quantity, 0);
  const cartTotal = cart.reduce(
    (total, item) => total + Number(item.price || 0) * item.quantity,
    0,
  );
  const normalizedSearch = searchQuery.trim().toLowerCase();
  const filteredProducts = products.filter((product) =>
    [product.name, product.category, product.description]
      .filter(Boolean)
      .some((value) => value.toLowerCase().includes(normalizedSearch)),
  );

  async function sendRequest(event) {
    event.preventDefault();
    setError("");
    setNotice("");
    try {
      const response = await fetch("/api/requests", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          message: requestMessage,
        }),
      });
      const result = await response.json();
      if (!response.ok) throw new Error(result.message || "Gagal mengirim permintaan.");

      setNotice(result.message);
      setRequestOpen(false);
      if (result.data.adminEmail) {
        const subject = encodeURIComponent("Permintaan barang dari pengguna");
        const body = encodeURIComponent(
          `Nama: ${user.name}\nEmail: ${user.email}\n\n${requestMessage}`,
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
              <button
                className="btn secondary"
                onClick={async () => {
                  try {
                    const cartResponse = await fetch("/api/cart", {
                      method: "DELETE",
                    });
                    const cartResult = await cartResponse.json();
                    if (!cartResponse.ok) {
                      throw new Error(
                        cartResult.message || "Gagal melepas reservasi keranjang.",
                      );
                    }
                    const response = await fetch("/api/auth/logout", { method: "POST" });
                    const result = await response.json();
                    if (!response.ok) {
                      throw new Error(result.message || "Logout gagal.");
                    }
                    setUser(null);
                    setCart([]);
                  } catch (logoutError) {
                    setError(logoutError.message);
                  }
                }}
              >
                Logout
              </button>
              <button
                className="btn secondary cart-button"
                onClick={() => setCartOpen(true)}
              >
                🛒 Keranjang <span className="cart-count">{cartCount}</span>
              </button>
            </>
          ) : (
            <>
              <a className="btn secondary" href="/auth?next=%2Fshop">
                Login untuk membeli
              </a>
              <button
                className="btn secondary cart-button"
                onClick={() => setCartOpen(true)}
              >
                🛒 Keranjang <span className="cart-count">{cartCount}</span>
              </button>
            </>
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
        <div className="shop-search">
          <label htmlFor="product-search">Cari barang</label>
          <input
            id="product-search"
            type="search"
            placeholder="Cari nama barang, kategori, atau deskripsi..."
            value={searchQuery}
            onChange={(event) => setSearchQuery(event.target.value)}
          />
        </div>
        <div className="shop-heading">
          <div>
            <h2>Produk tersedia</h2>
            <p className="muted">Pesanan akan menunggu konfirmasi admin.</p>
          </div>
          <span className="muted">
            {normalizedSearch
              ? `${filteredProducts.length} dari ${products.length} produk`
              : `${products.length} produk`}
          </span>
        </div>
        {error && <p className="error">{error}</p>}
        {notice && <p className="notice">{notice}</p>}
        {loading ? (
          <p className="muted">Memuat produk...</p>
        ) : filteredProducts.length ? (
          <div className="grid">
            {filteredProducts.map((product) => {
              const availableStock = Number(product.stock);
              return (
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
                    <span className="muted">Stok {availableStock}</span>
                  </div>
                  {user ? (
                    <>
                      <div className="shop-actions">
                        <label className="quantity-field">
                          Jumlah
                          <input
                            aria-label={`Jumlah ${product.name}`}
                            type="number"
                            min="1"
                            max={Math.min(availableStock, 99)}
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
                            updatingCartId === product.id ||
                            !Number.isInteger(Number(quantities[product.id] || 1)) ||
                            Number(quantities[product.id] || 1) < 1 ||
                            Number(quantities[product.id] || 1) > availableStock
                          }
                          onClick={() => addToCart(product)}
                        >
                          {updatingCartId === product.id
                            ? "Menyimpan..."
                            : "Tambah ke keranjang"}
                        </button>
                      </div>
                    </>
                  ) : (
                    <a className="btn primary shop-login" href="/auth?next=%2Fshop">
                      Login untuk memesan
                    </a>
                  )}
                </div>
              </article>
              );
            })}
          </div>
        ) : products.length ? (
          <p className="empty-state">Tidak ada barang yang cocok dengan pencarian.</p>
        ) : (
          <p className="empty-state">Belum ada produk yang dipublikasikan.</p>
        )}
        {user && (
          <section className="request-catalog">
            <p className="muted">Tidak menemukan barang yang dicari?</p>
            <button
              className="btn secondary"
              onClick={() => {
                setRequestMessage("");
                setRequestOpen(true);
              }}
            >
              Request Barang
            </button>
          </section>
        )}
      </main>

      {requestOpen && (
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
              onClick={() => setRequestOpen(false)}
            >
              ×
            </button>
            <div className="eyebrow">Kirim pesan ke admin</div>
            <h2 id="request-title">Request Barang</h2>
            <p className="muted">
              Tulis permintaan barang Anda. Pesan akan masuk ke notifikasi admin.
            </p>
            <form className="request-form" onSubmit={sendRequest}>
              <label>
                Pesan
                <textarea
                  autoFocus
                  maxLength="3000"
                  placeholder="Tulis barang atau permintaan Anda..."
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
      {cartOpen && (
        <div className="modal-backdrop" role="presentation">
          <section
            aria-labelledby="cart-title"
            aria-modal="true"
            className="request-modal cart-modal"
            role="dialog"
          >
            <button
              aria-label="Tutup keranjang"
              className="modal-close"
              onClick={() => setCartOpen(false)}
            >
              ×
            </button>
            <div className="eyebrow">Belanjaan Anda</div>
            <h2 id="cart-title">Keranjang ({cartCount})</h2>
            {cart.length ? (
              <>
                <div className="cart-items">
                  {cart.map((item) => {
                    const product = products.find(
                      (entry) => entry.id === item.productId,
                    );
                    return (
                      <article className="cart-item" key={item.productId}>
                        <div>
                          <b>{item.name}</b>
                          <p className="muted">
                            {money(product?.price ?? item.price)} × {item.quantity}
                          </p>
                        </div>
                        <div className="cart-item-actions">
                          <input
                            aria-label={`Jumlah ${item.name} di keranjang`}
                            type="number"
                            min="1"
                            max="99"
                            value={item.quantity}
                            onChange={(event) => {
                              const quantity = Number(event.target.value);
                              if (
                                Number.isInteger(quantity) &&
                                quantity > 0 &&
                                quantity <= 99
                              ) {
                                updateCartQuantity(item.productId, quantity);
                              }
                            }}
                            disabled={updatingCartId === item.productId}
                          />
                          <button
                            className="link-button"
                            disabled={updatingCartId === item.productId}
                            onClick={() => removeCartItem(item.productId)}
                          >
                            Hapus
                          </button>
                        </div>
                      </article>
                    );
                  })}
                </div>
                <div className="cart-total">
                  <b>Total</b>
                  <b>{money(cartTotal)}</b>
                </div>
                <button
                  className="btn primary cart-checkout"
                  disabled={checkingOut}
                  onClick={checkout}
                >
                  {checkingOut ? "Memproses..." : "Checkout"}
                </button>
              </>
            ) : (
              <>
                <p className="muted">Keranjang masih kosong.</p>
                <button
                  className="btn secondary"
                  onClick={() => setCartOpen(false)}
                >
                  Lihat produk
                </button>
              </>
            )}
          </section>
        </div>
      )}
      <footer className="footer">MerchBox · Merchandise pilihan</footer>
    </>
  );
}
