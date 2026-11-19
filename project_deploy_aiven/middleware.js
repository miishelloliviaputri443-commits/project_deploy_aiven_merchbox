import { NextResponse } from "next/server";

const allowedMethods = "GET,POST,PUT,PATCH,DELETE,OPTIONS";
const allowedHeaders = "Accept,Content-Type";

export function middleware(request) {
  const origin = request.headers.get("origin");
  const allowedOrigins = (process.env.FLUTTER_WEB_ORIGINS || "")
    .split(",")
    .map((value) => value.trim())
    .filter(Boolean);
  const isAllowed = origin && allowedOrigins.includes(origin);

  if (request.method === "OPTIONS") {
    const response = new NextResponse(null, { status: 204 });
    response.headers.set("Vary", "Origin");
    if (isAllowed) {
      response.headers.set("Access-Control-Allow-Origin", origin);
      response.headers.set("Access-Control-Allow-Credentials", "true");
      response.headers.set("Access-Control-Allow-Methods", allowedMethods);
      response.headers.set("Access-Control-Allow-Headers", allowedHeaders);
      response.headers.set("Access-Control-Max-Age", "600");
    }
    return response;
  }

  const response = NextResponse.next();
  if (origin) {
    response.headers.append("Vary", "Origin");
    if (isAllowed) {
      response.headers.set("Access-Control-Allow-Origin", origin);
      response.headers.set("Access-Control-Allow-Credentials", "true");
    }
  }
  return response;
}

export const config = {
  matcher: "/api/:path*",
};
