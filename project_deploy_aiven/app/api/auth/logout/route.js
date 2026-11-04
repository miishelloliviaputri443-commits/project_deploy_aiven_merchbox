import { NextResponse } from "next/server";
import { clearSession } from "@/lib/auth";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

export async function POST() {
  try {
    await clearSession();
    return NextResponse.json({ success: true, message: "Logout berhasil." });
  } catch (error) {
    console.error(error);
    return NextResponse.json({ success: false, message: "Logout gagal." }, { status: 500 });
  }
}
