import { NextResponse } from "next/server";
import getPool from "@/lib/db";
import { getCurrentUser } from "@/lib/auth";

export const runtime = "nodejs";

export async function GET() {
  try {
    const user = await getCurrentUser();
    if (user?.role !== "admin") {
      return NextResponse.json(
        { success: false, message: "Akses admin diperlukan." },
        { status: 403 },
      );
    }
    const [data] = await getPool().query(
      "SELECT id,name,email,product_name AS productName,message,is_read AS isRead,created_at AS createdAt FROM product_requests ORDER BY is_read ASC,created_at DESC LIMIT 100",
    );
    return NextResponse.json({ success: true, data });
  } catch (error) {
    console.error(error);
    return NextResponse.json(
      { success: false, message: "Gagal mengambil permintaan barang." },
      { status: 500 },
    );
  }
}

export async function POST(request) {
  try {
    const user = await getCurrentUser();
    if (!user) {
      return NextResponse.json(
        { success: false, message: "Silakan login untuk mengirim permintaan." },
        { status: 401 },
      );
    }
    const body = await request.json();
    if (!body || typeof body !== "object" || Array.isArray(body)) {
      return NextResponse.json(
        { success: false, message: "Data permintaan tidak valid." },
        { status: 400 },
      );
    }
    const message = typeof body.message === "string" ? body.message.trim() : "";
    if (!message || message.length > 3000) {
      return NextResponse.json(
        { success: false, message: "Pesan wajib diisi (maksimal 3000 karakter)." },
        { status: 400 },
      );
    }

    await getPool().execute(
      "INSERT INTO product_requests(user_id,name,email,product_name,message) VALUES(?,?,?,?,?)",
      [user.id, user.name, user.email, "Permintaan barang", message],
    );
    const adminEmail = process.env.ADMIN_EMAIL?.trim() || "";
    return NextResponse.json(
      {
        success: true,
        message: "Permintaan tersimpan dan sudah masuk notifikasi admin.",
        data: { adminEmail },
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
    console.error(error);
    return NextResponse.json(
      { success: false, message: "Gagal mengirim permintaan barang." },
      { status: 500 },
    );
  }
}
