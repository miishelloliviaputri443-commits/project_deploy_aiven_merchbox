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
Autentikasi pengguna tersedia melalui POST `/api/auth/register`, POST `/api/auth/login`, POST `/api/auth/logout`, dan GET `/api/auth/me`. Password disimpan sebagai hash, sedangkan login disimpan dalam cookie bertanda tangan menggunakan `AUTH_SECRET`. Database hanya membutuhkan tabel `users`.
