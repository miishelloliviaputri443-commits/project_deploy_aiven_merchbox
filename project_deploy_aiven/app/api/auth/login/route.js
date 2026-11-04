import { NextResponse } from "next/server";
import getPool from "@/lib/db";
import { createSession, normalizeEmail, verifyPassword } from "@/lib/auth";

export const runtime = "nodejs";

export async function POST(request) {
  try {
    const body = await request.json();
    const email = normalizeEmail(body.email);
    const password = typeof body.password === "string" ? body.password : "";
    const [rows] = await getPool().execute(
      "SELECT id,name,email,password_hash FROM users WHERE email=?",
      [email],
    );
    if (!rows[0] || !verifyPassword(password, rows[0].password_hash)) {
      return NextResponse.json({ success: false, message: "Email atau password salah." }, { status: 401 });
    }
    await createSession(rows[0].id);
    return NextResponse.json({
      success: true,
      message: "Login berhasil.",
      data: { id: rows[0].id, name: rows[0].name, email: rows[0].email },
    });
  } catch (error) {
    if (error instanceof SyntaxError) {
      return NextResponse.json({ success: false, message: "JSON tidak valid." }, { status: 400 });
    }
    console.error(error);
    return NextResponse.json({ success: false, message: "Login gagal." }, { status: 500 });
  }
}
