import { NextResponse } from "next/server";
import getPool from "@/lib/db";
import { getCurrentUser } from "@/lib/auth";
export const runtime = "nodejs";
export async function GET(request) {
  try {
    const adminView = new URL(request.url).searchParams.get("admin") === "1";
    if (adminView && (await getCurrentUser())?.role !== "admin") {
      return NextResponse.json(
        { success: false, message: "Akses admin diperlukan." },
        { status: 403 },
      );
    }
    const where = adminView ? "" : "WHERE is_published=1 AND stock>0";
    const [data] = await getPool().query(
      `SELECT id,name,description,category,price,stock,image_url AS imageUrl,is_published AS isPublished FROM products ${where} ORDER BY id DESC`,
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
    if ((await getCurrentUser())?.role !== "admin") {
      return NextResponse.json(
        { success: false, message: "Akses admin diperlukan." },
        { status: 403 },
      );
    }
    const b = await request.json();
    if (
      !b.name?.trim() ||
      !b.description?.trim() ||
      !["Gantungan Kunci", "Pin"].includes(b.category?.trim()) ||
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
      "INSERT INTO products(name,description,category,price,stock,image_url,is_published) VALUES(?,?,?,?,?,?,?)",
      [
        b.name.trim(),
        b.description.trim(),
        b.category.trim(),
        Number(b.price),
        Number(b.stock),
        b.imageUrl?.trim() || null,
        b.isPublished === true,
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
