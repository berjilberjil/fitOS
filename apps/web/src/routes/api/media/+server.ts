import { error } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { r2Configured, getObjectBytes, deleteObject, keyOwnedBy } from '$lib/server/r2';

/**
 * GET /api/media?key=progress/{userId}/{id}.jpg
 * Returns the JPEG from R2. Requires session; key must belong to the user.
 */
export const GET: RequestHandler = async ({ url, locals }) => {
  if (!locals.user) throw error(401, 'Not logged in');
  if (!r2Configured()) throw error(503, 'Media storage is not configured');

  const key = url.searchParams.get('key')?.trim();
  if (!key || key.includes('..') || key.startsWith('/')) {
    throw error(400, 'Missing or invalid key');
  }
  if (!keyOwnedBy(key, locals.user.id)) {
    throw error(403, 'Forbidden');
  }

  try {
    const { bytes, contentType } = await getObjectBytes(key);
    return new Response(bytes, {
      headers: {
        'Content-Type': contentType || 'image/jpeg',
        'Cache-Control': 'private, max-age=86400',
        'Content-Length': String(bytes.byteLength)
      }
    });
  } catch (e) {
    if (e && typeof e === 'object' && 'status' in e) throw e;
    const name = e && typeof e === 'object' && 'name' in e ? String((e as { name: string }).name) : '';
    if (name === 'NoSuchKey' || name === 'NotFound') throw error(404, 'Not found');
    console.error('[r2] get failed', e);
    throw error(502, 'Failed to load photo from R2');
  }
};

/**
 * DELETE /api/media  JSON { key }
 * Removes the object from R2 (metadata must still be removed from app_state by the client).
 */
export const DELETE: RequestHandler = async ({ request, locals }) => {
  if (!locals.user) throw error(401, 'Not logged in');
  if (!r2Configured()) throw error(503, 'Media storage is not configured');

  let key: string | undefined;
  try {
    const body = await request.json();
    key = typeof body?.key === 'string' ? body.key.trim() : undefined;
  } catch {
    throw error(400, 'Expected JSON { key }');
  }

  if (!key || key.includes('..')) throw error(400, 'Missing or invalid key');
  if (!keyOwnedBy(key, locals.user.id)) throw error(403, 'Forbidden');

  try {
    await deleteObject(key);
  } catch (e) {
    console.error('[r2] delete failed', e);
    throw error(502, 'Failed to delete photo from R2');
  }

  return new Response(JSON.stringify({ ok: true }), {
    headers: { 'Content-Type': 'application/json' }
  });
};
