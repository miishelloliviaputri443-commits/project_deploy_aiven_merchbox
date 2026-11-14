import { NextResponse } from "next/server";
import getPool from "@/lib/db";
import { getCurrentUser } from "@/lib/auth";
import { releaseExpiredReservations } from "@/lib/cart-reservations";

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
    const isCartCheckout = Array.isArray(body.items);
    const requestedItems = isCartCheckout
      ? body.items
      : [{ productId: body.productId, quantity: body.quantity }];
    if (!requestedItems.length || requestedItems.length > 20) {
      return NextResponse.json(
        { success: false, message: "Keranjang harus berisi 1 sampai 20 produk." },
        { status: 400 },
      );
    }

    const itemsById = new Map();
    for (const item of requestedItems) {
      const productId = Number(item?.productId);
      const quantity = Number(item?.quantity);
      if (
        !Number.isInteger(productId) ||
        productId < 1 ||
        !Number.isInteger(quantity) ||
        quantity < 1
      ) {
        return NextResponse.json(
          { success: false, message: "Produk atau jumlah pesanan tidak valid." },
          { status: 400 },
        );
      }
      const totalQuantity = (itemsById.get(productId) || 0) + quantity;
      if (totalQuantity > 99) {
        return NextResponse.json(
          { success: false, message: "Maksimal 99 unit untuk setiap produk." },
          { status: 400 },
        );
      }
      itemsById.set(productId, totalQuantity);
    }

    connection = await getPool().getConnection();
    await connection.beginTransaction();
    await releaseExpiredReservations(connection);
    const orders = [];
    let totalPrice = 0;
    for (const [productId, quantity] of [...itemsById.entries()].sort(
      ([firstId], [secondId]) => firstId - secondId,
    )) {
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

      let reservedQuantity = 0;
      if (isCartCheckout) {
        const [reservations] = await connection.execute(
          "SELECT quantity FROM cart_reservations WHERE user_id=? AND product_id=? AND expires_at>CURRENT_TIMESTAMP FOR UPDATE",
          [user.id, productId],
        );
        reservedQuantity = Number(reservations[0]?.quantity || 0);
        if (reservedQuantity < quantity) {
          await connection.rollback();
          return NextResponse.json(
            {
              success: false,
              message: "Reservasi keranjang sudah kedaluwarsa. Tambahkan ulang produk.",
            },
            { status: 409 },
          );
        }
      } else if (product.stock < quantity) {
        await connection.rollback();
        return NextResponse.json(
          { success: false, message: `Stok ${product.name} tidak mencukupi.` },
          { status: 409 },
        );
      }

      const itemTotal = Number(product.price) * quantity;
      totalPrice += itemTotal;
      if (isCartCheckout) {
        if (reservedQuantity > quantity) {
          await connection.execute(
            "UPDATE products SET stock=stock+? WHERE id=?",
            [reservedQuantity - quantity, productId],
          );
        }
        await connection.execute(
          "DELETE FROM cart_reservations WHERE user_id=? AND product_id=?",
          [user.id, productId],
        );
      } else {
        await connection.execute(
          "UPDATE products SET stock=stock-? WHERE id=?",
          [quantity, productId],
        );
      }
      const [result] = await connection.execute(
        "INSERT INTO orders(user_id,product_id,product_name,quantity,unit_price,total_price) VALUES(?,?,?,?,?,?)",
        [user.id, productId, product.name, quantity, product.price, itemTotal],
      );
      orders.push({ id: result.insertId, productId, quantity, totalPrice: itemTotal });
    }
    await connection.commit();
    return NextResponse.json(
      {
        success: true,
        message: "Pesanan dibuat. Admin akan menghubungi Anda untuk konfirmasi pembayaran.",
        data: { id: orders[0].id, totalPrice, orders },
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
