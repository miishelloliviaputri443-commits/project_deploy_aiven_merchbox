import { NextResponse } from "next/server";
import getPool from "@/lib/db";
import { getCurrentUser } from "@/lib/auth";
import { releaseExpiredReservations } from "@/lib/cart-reservations";

export const runtime = "nodejs";

export async function GET() {
  let connection;
  try {
    const user = await getCurrentUser();
    if (!user || user.role === "admin") {
      return NextResponse.json(
        { success: false, message: "Login sebagai pengguna untuk membuka keranjang." },
        { status: 401 },
      );
    }

    connection = await getPool().getConnection();
    await connection.beginTransaction();
    await releaseExpiredReservations(connection);
    const [data] = await connection.execute(
      "SELECT r.product_id AS productId,r.quantity,p.name,p.price,p.stock,p.image_url AS imageUrl FROM cart_reservations r JOIN products p ON p.id=r.product_id WHERE r.user_id=? ORDER BY r.created_at",
      [user.id],
    );
    await connection.commit();
    return NextResponse.json({ success: true, data });
  } catch (error) {
    if (connection) await connection.rollback();
    console.error(error);
    return NextResponse.json(
      { success: false, message: "Gagal memuat keranjang." },
      { status: 500 },
    );
  } finally {
    connection?.release();
  }
}

export async function POST(request) {
  let connection;
  try {
    const user = await getCurrentUser();
    if (!user || user.role === "admin") {
      return NextResponse.json(
        { success: false, message: "Login sebagai pengguna untuk memesan barang." },
        { status: 401 },
      );
    }

    const body = await request.json();
    const productId = Number(body?.productId);
    const quantity = Number(body?.quantity);
    if (
      !Number.isInteger(productId) ||
      productId < 1 ||
      !Number.isInteger(quantity) ||
      quantity < 1 ||
      quantity > 99
    ) {
      return NextResponse.json(
        { success: false, message: "Produk atau jumlah tidak valid." },
        { status: 400 },
      );
    }

    connection = await getPool().getConnection();
    await connection.beginTransaction();
    await releaseExpiredReservations(connection);
    const [products] = await connection.execute(
      "SELECT id,stock FROM products WHERE id=? AND is_published=1 FOR UPDATE",
      [productId],
    );
    if (!products.length) {
      await connection.rollback();
      return NextResponse.json(
        { success: false, message: "Produk tidak tersedia." },
        { status: 404 },
      );
    }

    const [existingRows] = await connection.execute(
      "SELECT quantity FROM cart_reservations WHERE user_id=? AND product_id=? FOR UPDATE",
      [user.id, productId],
    );
    const existingQuantity = Number(existingRows[0]?.quantity || 0);
    const difference = quantity - existingQuantity;
    if (difference > Number(products[0].stock)) {
      await connection.rollback();
      return NextResponse.json(
        { success: false, message: "Stok tidak mencukupi untuk jumlah tersebut." },
        { status: 409 },
      );
    }

    if (difference !== 0) {
      await connection.execute("UPDATE products SET stock=stock-? WHERE id=?", [
        difference,
        productId,
      ]);
    }
    await connection.execute(
      "INSERT INTO cart_reservations(user_id,product_id,quantity,expires_at) VALUES(?,?,?,DATE_ADD(CURRENT_TIMESTAMP, INTERVAL 2 HOUR)) ON DUPLICATE KEY UPDATE quantity=VALUES(quantity),expires_at=VALUES(expires_at)",
      [user.id, productId, quantity],
    );
    await connection.commit();
    return NextResponse.json({
      success: true,
      message: "Stok berhasil direservasi ke keranjang.",
      data: { productId, quantity },
    });
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
      { success: false, message: "Gagal memperbarui keranjang." },
      { status: 500 },
    );
  } finally {
    connection?.release();
  }
}

export async function DELETE(request) {
  let connection;
  try {
    const user = await getCurrentUser();
    if (!user || user.role === "admin") {
      return NextResponse.json(
        { success: false, message: "Login sebagai pengguna untuk mengubah keranjang." },
        { status: 401 },
      );
    }

    const productIdValue = new URL(request.url).searchParams.get("productId");
    const productId = productIdValue === null ? null : Number(productIdValue);
    if (productIdValue !== null && (!Number.isInteger(productId) || productId < 1)) {
      return NextResponse.json(
        { success: false, message: "ID produk tidak valid." },
        { status: 400 },
      );
    }

    connection = await getPool().getConnection();
    await connection.beginTransaction();
    await releaseExpiredReservations(connection);
    const [rows] = productId === null
      ? await connection.execute(
          "SELECT product_id AS productId FROM cart_reservations WHERE user_id=? ORDER BY product_id",
          [user.id],
        )
      : [[{ productId }]];

    for (const row of rows) {
      await connection.execute("SELECT id FROM products WHERE id=? FOR UPDATE", [
        row.productId,
      ]);
      const [reservations] = await connection.execute(
        "SELECT quantity FROM cart_reservations WHERE user_id=? AND product_id=? FOR UPDATE",
        [user.id, row.productId],
      );
      if (!reservations.length) continue;

      await connection.execute("UPDATE products SET stock=stock+? WHERE id=?", [
        reservations[0].quantity,
        row.productId,
      ]);
      await connection.execute(
        "DELETE FROM cart_reservations WHERE user_id=? AND product_id=?",
        [user.id, row.productId],
      );
    }
    await connection.commit();
    return NextResponse.json({
      success: true,
      message: "Reservasi stok di keranjang telah dilepas.",
    });
  } catch (error) {
    if (connection) await connection.rollback();
    console.error(error);
    return NextResponse.json(
      { success: false, message: "Gagal menghapus barang dari keranjang." },
      { status: 500 },
    );
  } finally {
    connection?.release();
  }
}
