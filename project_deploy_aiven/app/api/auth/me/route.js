import { NextResponse } from "next/server";
import { getCurrentUser } from "@/lib/auth";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

export async function GET() {
  try {
    return NextResponse.json({ success: true, data: await getCurrentUser() });
  } catch (error) {
    console.error(error);
    return NextResponse.json({ success: false, message: "Gagal memeriksa sesi." }, { status: 500 });
  }
}
