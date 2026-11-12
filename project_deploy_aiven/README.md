# Merchandise Delivery — project_deploy_aiven
Struktur satu aplikasi Next.js mengikuti screenshot: app/, app/api/products, lib/db.js, .env.local, ca.pem, package.json, schema.sql.

1. Jalankan schema.sql di Aiven MySQL.
2. Salin .env.local.example menjadi .env.local dan isi data koneksi Aiven. Aplikasi menerima nama variabel `MYSQL_HOST`, `MYSQL_PORT`, `MYSQL_USER`, `MYSQL_PASSWORD`, `MYSQL_DATABASE`, atau alias `DB_HOST`, `DB_PORT`, `DB_USER`, `DB_PASSWORD`, `DB_DATABASE`.
   Untuk verifikasi sertifikat, isi `MYSQL_CA_CERT` dan gunakan `MYSQL_SSL_REJECT_UNAUTHORIZED=true`. Tanpa CA, aplikasi memakai mode kompatibilitas Aiven dengan verifikasi sertifikat dimatikan.
3. Jalankan `npm install` lalu `npm run dev`.
4. Deploy repository ini ke Vercel dan masukkan environment variables yang sama di Project Settings.

CRUD produk: GET/POST /api/products dan GET/PUT/DELETE /api/products/:id.
Database produk mendukung kategori `Gantungan Kunci` dan `Pin`. Form dan API memvalidasi agar hanya dua kategori ini yang dapat digunakan.
Edit produk disimpan langsung ke MySQL Aiven melalui endpoint `PUT /api/products/:id`, sehingga tetap tersimpan setelah server direstart. Menjalankan ulang schema tidak menimpa data produk yang sudah ada.
Autentikasi pengguna tersedia melalui POST `/api/auth/register`, POST `/api/auth/login`, POST `/api/auth/logout`, dan GET `/api/auth/me`. Password disimpan sebagai hash, sedangkan login disimpan dalam cookie bertanda tangan menggunakan `AUTH_SECRET`.

## Toko dan permintaan pengguna

- Jalankan ulang `schema.sql` untuk menambahkan status publikasi, tabel pesanan, dan kotak masuk permintaan.
- Jalankan `schema.sql`, daftarkan akun pengelola, lalu promosikan akun tersebut langsung di MySQL dengan `UPDATE users SET role='admin' WHERE email='email-pengelola-anda';`. Jangan jadikan pendaftaran publik sebagai cara memberikan akses admin.
- Opsional: atur `ADMIN_EMAIL` ke alamat pengelola agar form permintaan juga membuka aplikasi email pengguna dengan pesan yang sudah disiapkan.
- Halaman pengguna tersedia di `/shop`. Pengunjung dapat melihat barang tayang dengan stok; pengguna login dapat membuat pesanan yang menahan stok dan berstatus menunggu konfirmasi admin.
- Halaman pengelolaan admin tersedia di `/admin`. Setelah login, admin otomatis diarahkan ke halaman ini; akun pengguna diarahkan ke `/shop`. Admin dapat mengedit atau menghapus barang langsung dari tabel, dan menambah barang lewat tombol “Tambah Barang”.
- Form “Minta barang” menyimpan nama, email, barang, dan pesan ke kotak masuk notifikasi panel admin. Jika `ADMIN_EMAIL` diatur, aplikasi email pengguna juga dibuka dengan pesan yang sudah disiapkan. Pesan tersimpan di aplikasi walaupun email tidak dikirim.
- Pengelola dapat menayangkan atau menyimpan produk sebagai draft dari panel admin di `/admin`. Produk baru secara default berupa draft.
