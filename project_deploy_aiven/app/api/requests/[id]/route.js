import { NextResponse } from "next/server";
import getPool from "@/lib/db";
import { getCurrentUser } from "@/lib/auth";

export const runtime = "nodejs";

export async function PATCH(_request, { params }) {
  const user = await getCurrentUser();
  if (user?.role !== "admin") {
    return NextResponse.json(
      { success: false, message: "Akses admin diperlukan." },
      { status: 403 },
    );
  }

  const id = Number(params.id);
  if (!Number.isInteger(id) || id < 1) {
    return NextResponse.json(
      { success: false, message: "ID permintaan tidak valid." },
      { status: 400 },
    );
  }

  try {
    const [result] = await getPool().execute(
      "UPDATE product_requests SET is_read=1 WHERE id=?",
      [id],
    );
    if (!result.affectedRows) {
      return NextResponse.json(
        { success: false, message: "Permintaan tidak ditemukan." },
        { status: 404 },
      );
    }
    return NextResponse.json({ success: true, message: "Permintaan ditandai sudah dibaca." });
  } catch (error) {
    console.error(error);
    return NextResponse.json(
      { success: false, message: "Gagal memperbarui permintaan." },
      { status: 500 },
    );
  }
}
