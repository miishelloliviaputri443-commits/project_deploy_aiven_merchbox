import { NextResponse } from "next/server";
import getPool from "@/lib/db";
export const runtime = "nodejs";
export async function GET() {
  try {
    const [data] = await getPool().query(
      "SELECT * FROM orders ORDER BY id DESC",
    );
    return NextResponse.json({ success: true, data });
  } catch (e) {
    console.error(e);
    return NextResponse.json(
      { success: false, message: "Gagal mengambil pesanan" },
      { status: 500 },
    );
  }
}
export async function POST(req) {
  let b;
  try {
    b = await req.json();
  } catch {
    return NextResponse.json(
      { success: false, message: "JSON tidak valid" },
      { status: 400 },
    );
  }
  if (
    !b.customerName ||
    !b.email ||
    !b.phone ||
    !b.address ||
    !Array.isArray(b.items) ||
    !b.items.length
  )
    return NextResponse.json(
      { success: false, message: "Data pesanan belum lengkap" },
      { status: 400 },
    );
  const c = await getPool().getConnection();
  try {
    await c.beginTransaction();
    let total = 0;
    const items = [];
    for (const i of b.items) {
      const [rows] = await c.execute(
        "SELECT id,name,price,stock FROM products WHERE id=? FOR UPDATE",
        [Number(i.productId)],
      );
      const p = rows[0],
        q = Number(i.quantity);
      if (!p || !Number.isInteger(q) || q < 1 || p.stock < q)
        throw Error("Produk tidak ditemukan atau stok tidak cukup");
      await c.execute("UPDATE products SET stock=stock-? WHERE id=?", [
        q,
        p.id,
      ]);
      total += p.price * q;
      items.push({
        productId: p.id,
        name: p.name,
        price: p.price,
        quantity: q,
      });
    }
    const [r] = await c.execute(
      "INSERT INTO orders(customer_name,email,phone,address,items,total) VALUES(?,?,?,?,?,?)",
      [
        b.customerName,
        b.email,
        b.phone,
        b.address,
        JSON.stringify(items),
        total,
      ],
    );
    await c.commit();
    return NextResponse.json(
      { success: true, data: { id: r.insertId, total } },
      { status: 201 },
    );
  } catch (e) {
    await c.rollback();
    return NextResponse.json(
      { success: false, message: e.message },
      { status: 400 },
    );
  } finally {
    c.release();
  }
}
