import {
  S3Client,
  PutObjectCommand,
  GetObjectCommand,
  DeleteObjectCommand
} from '@aws-sdk/client-s3';
import { env } from '$env/dynamic/private';

/** R2 env is required only when media routes run — fail clearly if missing. */
export function r2Configured(): boolean {
  return Boolean(
    env.R2_ACCESS_KEY_ID &&
      env.R2_SECRET_ACCESS_KEY &&
      env.R2_BUCKET &&
      (env.R2_ENDPOINT || env.R2_ACCOUNT_ID)
  );
}

function endpoint(): string {
  if (env.R2_ENDPOINT) return env.R2_ENDPOINT.replace(/\/$/, '');
  if (env.R2_ACCOUNT_ID) {
    return `https://${env.R2_ACCOUNT_ID}.r2.cloudflarestorage.com`;
  }
  throw new Error('R2_ENDPOINT or R2_ACCOUNT_ID is required');
}

let _client: S3Client | null = null;

export function r2(): S3Client {
  if (!r2Configured()) {
    throw new Error('Cloudflare R2 is not configured (set R2_* env vars)');
  }
  if (!_client) {
    _client = new S3Client({
      region: 'auto',
      endpoint: endpoint(),
      credentials: {
        accessKeyId: env.R2_ACCESS_KEY_ID!,
        secretAccessKey: env.R2_SECRET_ACCESS_KEY!
      },
      forcePathStyle: true
    });
  }
  return _client;
}

export function r2Bucket(): string {
  return env.R2_BUCKET || 'fitos-media';
}

/** Object key for a progress photo — scoped per user so auth can enforce ownership. */
export function progressPhotoKey(userId: number, photoId: string): string {
  const safeId = photoId.replace(/[^a-zA-Z0-9_-]/g, '').slice(0, 64) || 'photo';
  return `progress/${userId}/${safeId}.jpg`;
}

/** True if this key belongs to the given user (prevents cross-user reads). */
export function keyOwnedBy(key: string, userId: number): boolean {
  return key === `progress/${userId}/` || key.startsWith(`progress/${userId}/`);
}

export async function putJpeg(key: string, body: Buffer | Uint8Array): Promise<void> {
  await r2().send(
    new PutObjectCommand({
      Bucket: r2Bucket(),
      Key: key,
      Body: body,
      ContentType: 'image/jpeg',
      CacheControl: 'private, max-age=31536000, immutable'
    })
  );
}

export async function getObjectBytes(key: string): Promise<{
  bytes: Uint8Array;
  contentType?: string;
}> {
  const out = await r2().send(
    new GetObjectCommand({
      Bucket: r2Bucket(),
      Key: key
    })
  );
  if (!out.Body) throw Object.assign(new Error('Empty body'), { name: 'NotFound' });
  const bytes = await out.Body.transformToByteArray();
  return { bytes, contentType: out.ContentType };
}

export async function deleteObject(key: string): Promise<void> {
  await r2().send(
    new DeleteObjectCommand({
      Bucket: r2Bucket(),
      Key: key
    })
  );
}

/** Decode data-URI or raw base64 into bytes. */
export function decodeBase64Image(input: string): Buffer {
  const raw = input.includes(',') ? input.split(',')[1]! : input;
  const buf = Buffer.from(raw, 'base64');
  if (!buf.length) throw new Error('Empty image data');
  // ~2.5 MB decoded cap (client compresses to ~80–150 KB)
  if (buf.length > 2_500_000) throw new Error('Image too large (max ~2.5 MB)');
  return buf;
}
