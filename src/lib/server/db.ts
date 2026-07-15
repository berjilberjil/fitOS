import postgres from 'postgres';
import { env } from '$env/dynamic/private';

// Single shared Postgres connection pool for the whole server.
export const sql = postgres(env.DATABASE_URL ?? 'postgresql://localhost:5432/luxifit', {
  onnotice: () => {}
});
