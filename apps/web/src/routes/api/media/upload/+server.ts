import { json, error } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import {
  r2Configured,
  progressPhotoKey,
  putJpeg,
  decodeBase64Image
} from '$lib/server/r2';
import { randomBytes } from 'node:crypto';

/**
 * Upload a progress photo to Cloudflare R2.
 * Body JSON: { jpegBase64, id?, date?, note? }
 * Returns metadata only (no bytes) for storage in app_state / luxifit.progressphotos.
 */
export const POST: RequestHandler = async ({ request, locals }) => {
  if (!locals.user) throw error(401, 'Not logged in');
  if (!r2Configured()) throw error(503, 'Media storage is not configured');

  let body: {
    jpegBase64?: string;
    id?: string;
    date?: string;
    note?: string | null;
    createdAt?: number;
  };
  try {
    body = await request.json();
  } catch {
    throw error(400, 'Expected JSON body');
  }

  if (!body.jpegBase64 || typeof body.jpegBase64 !== 'string') {
    throw error(400, 'jpegBase64 is required');
  }

  const id =
    (typeof body.id === 'string' && body.id.trim()) ||
    randomBytes(16).toString('hex');
  const date =
    (typeof body.date === 'string' && /^\d{4}-\d{2}-\d{2}$/.test(body.date) && body.date) ||
    new Date().toISOString().slice(0, 10);
  const note =
    typeof body.note === 'string' && body.note.trim() ? body.note.trim().slice(0, 500) : null;
  const createdAt =
    typeof body.createdAt === 'number' && Number.isFinite(body.createdAt)
      ? body.createdAt
      : Date.now() / 1000;

  let bytes: Buffer;
  try {
    bytes = decodeBase64Image(body.jpegBase64);
  } catch (e) {
    throw error(400, e instanceof Error ? e.message : 'Invalid image data');
  }

  const key = progressPhotoKey(locals.user.id, id);

  try {
    await putJpeg(key, bytes);
  } catch (e) {
    console.error('[r2] put failed', e);
    throw error(502, 'Failed to store photo in R2');
  }

  // Metadata for app_state — no base64. Clients load via GET /api/media?key=...
  return json({
    id,
    date,
    key,
    note,
    createdAt,
    // Convenience relative URL (auth cookie required)
    url: `/api/media?key=${encodeURIComponent(key)}`
  });
};
