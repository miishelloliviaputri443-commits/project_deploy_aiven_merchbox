export async function releaseExpiredReservations(connection) {
  const [expired] = await connection.query(
    "SELECT DISTINCT product_id AS productId FROM cart_reservations WHERE expires_at<=CURRENT_TIMESTAMP ORDER BY product_id",
  );

  for (const { productId } of expired) {
    await connection.execute("SELECT id FROM products WHERE id=? FOR UPDATE", [
      productId,
    ]);
    const [reservations] = await connection.execute(
      "SELECT id,quantity FROM cart_reservations WHERE product_id=? AND expires_at<=CURRENT_TIMESTAMP FOR UPDATE",
      [productId],
    );
    if (!reservations.length) continue;

    const quantity = reservations.reduce(
      (total, reservation) => total + Number(reservation.quantity),
      0,
    );
    await connection.execute("UPDATE products SET stock=stock+? WHERE id=?", [
      quantity,
      productId,
    ]);
    const ids = reservations.map((reservation) => reservation.id);
    await connection.execute(
      `DELETE FROM cart_reservations WHERE id IN (${ids.map(() => "?").join(",")})`,
      ids,
    );
  }
}
