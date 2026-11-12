import crypto from "node:crypto";
import { cookies } from "next/headers";
import getPool from "@/lib/db";

const SESSION_COOKIE = "merchbox_session";
const SESSION_DAYS = 7;
const SESSION_SECRET = process.env.AUTH_SECRET || "change-this-auth-secret";

export function hashPassword(password, salt = crypto.randomBytes(16).toString("hex")) {
  const hash = crypto.scryptSync(password, salt, 64).toString("hex");
  return `${salt}:${hash}`;
}

export function verifyPassword(password, storedHash) {
  const [salt, expected] = storedHash.split(":");
  if (!salt || !expected) return false;
  const actual = crypto.scryptSync(password, salt, 64).toString("hex");
  return expected.length === actual.length &&
    crypto.timingSafeEqual(Buffer.from(expected), Buffer.from(actual));
}

export async function createSession(userId) {
  const expiresAt = Math.floor(Date.now() / 1000) + SESSION_DAYS * 86400;
  const payload = `${userId}.${expiresAt}`;
  const signature = crypto
    .createHmac("sha256", SESSION_SECRET)
    .update(payload)
    .digest("hex");
  cookies().set(SESSION_COOKIE, `${payload}.${signature}`, {
    httpOnly: true,
    sameSite: "lax",
    secure: process.env.NODE_ENV === "production",
    maxAge: SESSION_DAYS * 86400,
    path: "/",
  });
}

export async function getCurrentUser() {
  const value = cookies().get(SESSION_COOKIE)?.value;
  if (!value) return null;
  const [userId, expiresAt, signature] = value.split(".");
  if (!userId || !expiresAt || !signature || Number(expiresAt) < Math.floor(Date.now() / 1000)) {
    return null;
  }
  const payload = `${userId}.${expiresAt}`;
  const expected = crypto.createHmac("sha256", SESSION_SECRET).update(payload).digest("hex");
  if (signature.length !== expected.length ||
      !crypto.timingSafeEqual(Buffer.from(signature), Buffer.from(expected))) {
    return null;
  }
  const [rows] = await getPool().execute(
    "SELECT id,name,email,role FROM users WHERE id=?",
    [Number(userId)],
  );
  return rows[0] || null;
}

export async function clearSession() {
  cookies().set(SESSION_COOKIE, "", { httpOnly: true, expires: new Date(0), path: "/" });
}

export function normalizeEmail(email) {
  return typeof email === "string" ? email.trim().toLowerCase() : "";
}
