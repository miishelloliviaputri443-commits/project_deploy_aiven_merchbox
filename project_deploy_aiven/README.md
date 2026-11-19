# Merchandise Delivery — project_deploy_aiven
Frontend MerchBox tersedia sebagai aplikasi Flutter Web di `flutter_app/`. Backend Next.js di folder ini tetap melayani autentikasi, katalog, reservasi keranjang, pesanan, permintaan barang, dan koneksi Aiven MySQL.

1. Jalankan schema.sql di Aiven MySQL.
2. Salin .env.local.example menjadi .env.local dan isi data koneksi Aiven. Aplikasi menerima nama variabel `MYSQL_HOST`, `MYSQL_PORT`, `MYSQL_USER`, `MYSQL_PASSWORD`, `MYSQL_DATABASE`, atau alias `DB_HOST`, `DB_PORT`, `DB_USER`, `DB_PASSWORD`, `DB_DATABASE`.
   Untuk verifikasi sertifikat, isi `MYSQL_CA_CERT` dan gunakan `MYSQL_SSL_REJECT_UNAUTHORIZED=true`. Tanpa CA, aplikasi memakai mode kompatibilitas Aiven dengan verifikasi sertifikat dimatikan.
3. Jalankan `npm install` lalu `npm run dev`.
4. Jalankan Flutter Web di terminal lain:

   ```powershell
   cd flutter_app
   flutter pub get
   flutter run -d chrome --web-port 5000 --dart-define=API_BASE_URL=http://localhost:3000
   ```

5. Tambahkan `FLUTTER_WEB_ORIGINS=http://localhost:5000` ke `.env.local` Next.js. Middleware API membatasi CORS ke origin yang didaftarkan dan mengizinkan cookie sesi; origin tidak menggunakan wildcard.
6. Untuk rilis, jalankan `flutter build web --release --dart-define=API_BASE_URL=https://alamat-api-anda` dari `flutter_app`. Deploy isi `flutter_app/build/web` ke hosting web dan set `FLUTTER_WEB_ORIGINS` di backend Next.js ke origin Flutter Web yang persis. Agar cookie sesi `SameSite=Lax` tetap dikirim, host frontend dan API di domain yang sama/site yang sama (misalnya subdomain dari domain yang sama). Seluruh variabel koneksi database tetap berada di backend dan jangan dimasukkan ke aplikasi Flutter.

CRUD produk: GET/POST /api/products dan GET/PUT/DELETE /api/products/:id.
Database produk mendukung kategori `Gantungan Kunci` dan `Pin`. Form dan API memvalidasi agar hanya dua kategori ini yang dapat digunakan.
Edit produk disimpan langsung ke MySQL Aiven melalui endpoint `PUT /api/products/:id`, sehingga tetap tersimpan setelah server direstart. Menjalankan ulang schema tidak menimpa data produk yang sudah ada.
Autentikasi pengguna tersedia melalui POST `/api/auth/register`, POST `/api/auth/login`, POST `/api/auth/logout`, dan GET `/api/auth/me`. Password disimpan sebagai hash, sedangkan login disimpan dalam cookie bertanda tangan menggunakan `AUTH_SECRET`.

## Toko dan permintaan pengguna

- Jalankan ulang `schema.sql` untuk menambahkan status publikasi, tabel pesanan, reservasi keranjang, dan kotak masuk permintaan.
- Atur `ADMIN_EMAIL` di `.env.local` ke email akun pengelola, lalu restart aplikasi. Email tersebut otomatis mendapat akses admin walaupun kolom `role` masih `customer`. Sebagai alternatif, promosikan akun langsung di MySQL dengan `UPDATE users SET role='admin' WHERE email='email-pengelola-anda';`. Jangan jadikan pendaftaran publik sebagai cara memberikan akses admin.
- Jika `ADMIN_EMAIL` diatur, form permintaan juga membuka aplikasi email pengguna dengan pesan yang sudah disiapkan.
- Di Flutter Web, halaman toko, autentikasi (`/auth`), serta panel maker (`/maker`) menggantikan antarmuka Next.js. Pengunjung dapat melihat barang tayang dengan stok; pengguna login dapat membuat pesanan yang menahan stok dan berstatus menunggu konfirmasi admin.
- Stok produk langsung dikurangi di database saat barang masuk keranjang dan dikembalikan saat barang dikeluarkan atau pengguna logout. Reservasi otomatis kedaluwarsa setelah dua jam; stok yang kedaluwarsa dilepas saat katalog/keranjang dimuat.
- Admin otomatis diarahkan ke `/maker`; akun pengguna diarahkan ke `/shop`. URL lama `/admin` mengarah ke panel maker. Admin dapat mengedit, menghapus, dan mengatur status publikasi produk, serta meninjau notifikasi permintaan barang.
- Form “Minta barang” menyimpan nama, email, barang, dan pesan ke kotak masuk notifikasi panel admin. Jika `ADMIN_EMAIL` diatur, aplikasi email pengguna juga dibuka dengan pesan yang sudah disiapkan. Pesan tersimpan di aplikasi walaupun email tidak dikirim.
- Pengelola dapat menayangkan atau menyimpan produk sebagai draft dari panel maker di `/maker`. Produk baru secara default berupa draft.
