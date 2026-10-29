import mysql from "mysql2/promise";
let pool;
export default function getPool() {
  if (pool) return pool;
  const config = {
    host: process.env.MYSQL_HOST || process.env.DB_HOST,
    port: process.env.MYSQL_PORT || process.env.DB_PORT,
    user: process.env.MYSQL_USER || process.env.DB_USER,
    password: process.env.MYSQL_PASSWORD || process.env.DB_PASSWORD,
    database: process.env.MYSQL_DATABASE || process.env.DB_DATABASE,
  };
  const missing = Object.entries(config)
    .filter(([, value]) => !value)
    .map(([key]) => key);
  if (missing.length) throw new Error(`Environment variable belum diisi: ${missing.join(", ")}`);
  const ca = process.env.MYSQL_CA_CERT?.replace(/\\n/g, "\n");
  const rejectUnauthorized =
    process.env.MYSQL_SSL_REJECT_UNAUTHORIZED !== "false" && Boolean(ca);
  pool = mysql.createPool({
    ...config,
    port: Number(config.port || 3306),
    ssl: ca ? { ca, rejectUnauthorized: true } : { rejectUnauthorized },
    waitForConnections: true,
    connectionLimit: 5,
  });
  return pool;
}
