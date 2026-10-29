import "./globals.css";

export const metadata = {
  title: "MerchBox",
  description: "Koleksi merchandise pilihan",
};

export default function RootLayout({ children }) {
  return (
    <html lang="id">
      <body>{children}</body>
    </html>
  );
}
