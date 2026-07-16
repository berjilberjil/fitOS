import postgres from 'postgres';
import { env } from '$env/dynamic/private';

const url = env.DATABASE_URL ?? 'postgresql://localhost:5432/luxifit';
const isSupabase = url.includes('supabase') || url.includes('pooler');

// Single shared Postgres connection pool for the whole server.
// Supabase pooler needs TLS and, on the transaction pooler (:6543), no prepared
// statements — `prepare: false` keeps it compatible with both poolers + serverless.
export const sql = postgres(url, {
  onnotice: () => {},
  prepare: false,
  ssl: isSupabase ? 'require' : false
});
