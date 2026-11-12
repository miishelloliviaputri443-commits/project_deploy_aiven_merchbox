import { NextResponse } from "next/server";
import getPool from "@/lib/db";
import { getCurrentUser } from "@/lib/auth";

export const runtime = "nodejs";

export async function POST(request) {
  let connection;
  try {
    const user = await getCurrentUser();
    if (!user) {
      return NextResponse.json(
        { success: false, message: "Silakan login untuk membuat pesanan." },
        { status: 401 },
      );
    }

    const body = await request.json();
    if (!body || typeof body !== "object" || Array.isArray(body)) {
      return NextResponse.json(
        { success: false, message: "Data pesanan tidak valid." },
        { status: 400 },
      );
    }
    const productId = Number(body.productId);
    const quantity = Number(body.quantity);
    if (
      !Number.isInteger(productId) ||
      productId < 1 ||
      !Number.isInteger(quantity) ||
      quantity < 1 ||
      quantity > 99
    ) {
      return NextResponse.json(
        { success: false, message: "Produk atau jumlah pesanan tidak valid." },
        { status: 400 },
      );
    }

    connection = await getPool().getConnection();
    await connection.beginTransaction();
    const [products] = await connection.execute(
      "SELECT id,name,price,stock FROM products WHERE id=? AND is_published=1 FOR UPDATE",
      [productId],
    );
    const product = products[0];
    if (!product) {
      await connection.rollback();
      return NextResponse.json(
        { success: false, message: "Produk tidak tersedia." },
        { status: 404 },
      );
    }
    if (product.stock < quantity) {
      await connection.rollback();
      return NextResponse.json(
        { success: false, message: "Stok tidak mencukupi." },
        { status: 409 },
      );
    }

    const totalPrice = Number(product.price) * quantity;
    await connection.execute(
      "UPDATE products SET stock=stock-? WHERE id=?",
      [quantity, productId],
    );
    const [result] = await connection.execute(
      "INSERT INTO orders(user_id,product_id,product_name,quantity,unit_price,total_price) VALUES(?,?,?,?,?,?)",
      [user.id, productId, product.name, quantity, product.price, totalPrice],
    );
    await connection.commit();
    return NextResponse.json(
      {
        success: true,
        message: "Pesanan dibuat. Admin akan menghubungi Anda untuk konfirmasi pembayaran.",
        data: { id: result.insertId, totalPrice },
      },
      { status: 201 },
    );
  } catch (error) {
    if (error instanceof SyntaxError) {
      return NextResponse.json(
        { success: false, message: "JSON tidak valid." },
        { status: 400 },
      );
    }
    if (connection) await connection.rollback();
    console.error(error);
    return NextResponse.json(
      { success: false, message: "Gagal membuat pesanan." },
      { status: 500 },
    );
  } finally {
    connection?.release();
  }
}
