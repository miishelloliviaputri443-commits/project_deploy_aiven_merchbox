import { NextResponse } from "next/server";
import getPool from "@/lib/db";
import { createSession, hashPassword, normalizeEmail } from "@/lib/auth";

export const runtime = "nodejs";

export async function POST(request) {
  try {
    const body = await request.json();
    const name = typeof body.name === "string" ? body.name.trim() : "";
    const email = normalizeEmail(body.email);
    const password = typeof body.password === "string" ? body.password : "";
    if (name.length < 2 || !email.includes("@") || password.length < 8) {
      return NextResponse.json(
        { success: false, message: "Nama, email valid, dan password minimal 8 karakter wajib diisi." },
        { status: 400 },
      );
    }
    const [result] = await getPool().execute(
      "INSERT INTO users(name,email,password_hash) VALUES(?,?,?)",
      [name, email, hashPassword(password)],
    );
    await createSession(result.insertId);
    return NextResponse.json({ success: true, message: "Registrasi berhasil." }, { status: 201 });
  } catch (error) {
    if (error instanceof SyntaxError) {
      return NextResponse.json({ success: false, message: "JSON tidak valid." }, { status: 400 });
    }
    if (error.code === "ER_DUP_ENTRY") {
      return NextResponse.json({ success: false, message: "Email sudah terdaftar." }, { status: 409 });
    }
    console.error(error);
    return NextResponse.json({ success: false, message: "Registrasi gagal." }, { status: 500 });
  }
}
