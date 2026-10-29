import { NextResponse } from "next/server";
import getPool from "@/lib/db";
export const runtime = "nodejs";
export async function GET() {
  try {
    const [data] = await getPool().query(
      "SELECT id,name,description,category,price,stock,image_url AS imageUrl FROM products ORDER BY id DESC",
    );
    return NextResponse.json({ success: true, data });
  } catch (e) {
    if (e instanceof SyntaxError)
      return NextResponse.json(
        { success: false, message: "JSON tidak valid." },
        { status: 400 },
      );
    console.error(e);
    return NextResponse.json(
      {
        success: false,
        message:
          "Gagal mengambil produk. Periksa konfigurasi Aiven dan schema.sql.",
      },
      { status: 500 },
    );
  }
}
export async function POST(request) {
  try {
    const b = await request.json();
    if (
      !b.name?.trim() ||
      !b.description?.trim() ||
      !b.category?.trim() ||
      !Number.isInteger(Number(b.price)) ||
      Number(b.price) < 0 ||
      !Number.isInteger(Number(b.stock)) ||
      Number(b.stock) < 0
    )
      return NextResponse.json(
        {
          success: false,
          message: "Nama, deskripsi, kategori, harga, dan stok wajib valid.",
        },
        { status: 400 },
      );
    const [r] = await getPool().execute(
      "INSERT INTO products(name,description,category,price,stock,image_url) VALUES(?,?,?,?,?,?)",
      [
        b.name.trim(),
        b.description.trim(),
        b.category.trim(),
        Number(b.price),
        Number(b.stock),
        b.imageUrl?.trim() || null,
      ],
    );
    return NextResponse.json(
      {
        success: true,
        message: "Produk berhasil ditambahkan.",
        data: { id: r.insertId },
      },
      { status: 201 },
    );
  } catch (e) {
    console.error(e);
    return NextResponse.json(
      { success: false, message: "Gagal menambahkan produk." },
      { status: 500 },
    );
  }
}
