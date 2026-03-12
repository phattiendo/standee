import { getHttpClient } from '../../core/network/httpClient';
import { apiConstants } from '../../core/constants/apiConstants';
import { MediaItem, mediaItemFromJson } from '../models/MediaItem';

function extractPosterList(value: unknown, depth = 0): unknown[] {
  if (value == null) return [];
  if (Array.isArray(value)) return value;
  if (typeof value !== 'object') return [];
  if (depth > 4) return [];

  const obj = value as Record<string, unknown>;
  for (const key of ['result', 'data', 'items', 'posters', 'activePosters']) {
    const v = obj[key];
    if (Array.isArray(v)) return v;
    if (v && typeof v === 'object') {
      const nested = extractPosterList(v, depth + 1);
      if (nested.length > 0) return nested;
    }
  }
  for (const v of Object.values(obj)) {
    if (Array.isArray(v)) return v;
    if (v && typeof v === 'object') {
      const nested = extractPosterList(v, depth + 1);
      if (nested.length > 0) return nested;
    }
  }
  return [];
}

function mapPosterToMedia(json: Record<string, unknown>): MediaItem | null {
  let url: string | undefined =
    (json.posterURL as string) ??
    (json.url as string) ??
    (json.mediaUrl as string) ??
    (json.imageUrl as string) ??
    (json.src as string);

  const media = json.media as Record<string, unknown> | undefined;
  if (!url && media && typeof media === 'object') {
    url = (media.url as string) ?? (media.mediaUrl as string) ?? (media.src as string);
  }
  if (!url || url.length === 0) return null;

  const base = apiConstants.baseUrl.replace(/\/$/, '');
  if (!url.startsWith('http://') && !url.startsWith('https://') && !url.startsWith('asset:')) {
    url = url.startsWith('/') ? `${base}${url}` : `${base}/${url}`;
  }

  let typeStr = String(json.type ?? '').toLowerCase();
  if (!typeStr) {
    typeStr = url.endsWith('.mp4') || url.endsWith('.webm') ? 'video' : 'image';
  }

  const duration =
    (json.duration as number) ??
    (json.displayDuration as number) ??
    (json.durationSeconds as number) ??
    10;
  const id = String(json.id ?? json.posterId ?? '');

  return mediaItemFromJson({
    id,
    url,
    type: typeStr === 'video' ? 'video' : 'image',
    durationSeconds: duration > 0 ? duration : 10,
  });
}

export async function fetchVersion(): Promise<number> {
  try {
    const res = await getHttpClient().get<{ version?: number }>(apiConstants.versionPath);
    const data = res.data;
    if (data?.version != null) return Number(data.version);
    return 0;
  } catch {
    return 0;
  }
}

export async function fetchMediaList(): Promise<MediaItem[]> {
  return fetchPosters(apiConstants.standeeId);
}

/** Lấy danh sách poster active cho standee: GET /api/poster/{standeeId}/withActivePosters */
export async function fetchPosters(standeeId: string): Promise<MediaItem[]> {
  const path = apiConstants.getPosterPath(standeeId);
  const res = await getHttpClient().get(path);
  const list = extractPosterList(res.data);
  return list
    .filter((e): e is Record<string, unknown> => e != null && typeof e === 'object')
    .map(mapPosterToMedia)
    .filter((m): m is MediaItem => m != null);
}
