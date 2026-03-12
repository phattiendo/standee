/**
 * Media type: image | video | sdp (Special Dynamic Poster)
 */
export type MediaType = 'image' | 'video' | 'sdp';

export interface MediaItem {
  id: string;
  url: string;
  type: MediaType;
  durationSeconds: number;
  sdpBackgroundAsset?: string;
  localPath?: string;
}

/** URL/path dùng để phát: ưu tiên file local (ROM). */
export function getPlaybackUrl(item: MediaItem, resolveLocalPath?: (relative: string) => string | null): string {
  if (item.localPath && item.localPath.length > 0) {
    const full = resolveLocalPath?.(item.localPath) ?? item.localPath;
    if (full) return full;
  }
  return item.url;
}

export function mediaItemFromJson(json: Record<string, unknown>): MediaItem {
  const id = (json.id as string) ?? '';
  const url = (json.url as string) ?? '';
  const typeStr = ((json.type as string) ?? 'image').toLowerCase();
  const duration =
    (json.durationSeconds as number) ?? (json.duration as number) ?? 10;

  let type: MediaType = 'image';
  if (typeStr === 'video') type = 'video';
  else if (typeStr === 'sdp') type = 'sdp';

  return {
    id,
    url,
    type,
    durationSeconds: duration > 0 ? duration : 10,
    sdpBackgroundAsset: json.sdpBackgroundAsset as string | undefined,
    localPath: json.localPath as string | undefined,
  };
}

export function mediaItemToJson(item: MediaItem): Record<string, unknown> {
  const out: Record<string, unknown> = {
    url: item.url,
    type: item.type,
    durationSeconds: item.durationSeconds,
  };
  if (item.id) out.id = item.id;
  if (item.sdpBackgroundAsset) out.sdpBackgroundAsset = item.sdpBackgroundAsset;
  if (item.localPath) out.localPath = item.localPath;
  return out;
}

export function createSdpItem(options?: {
  id?: string;
  durationSeconds?: number;
  posterUrl?: string;
  backgroundAsset?: string;
}): MediaItem {
  return {
    id: options?.id ?? 'sdp',
    url: options?.posterUrl ?? '',
    type: 'sdp',
    durationSeconds: options?.durationSeconds ?? 40,
    sdpBackgroundAsset: options?.backgroundAsset,
  };
}

export function createVideoItem(options: {
  id?: string;
  url: string;
  durationSeconds?: number;
  localPath?: string;
}): MediaItem {
  return {
    id: options.id ?? '',
    url: options.url,
    type: 'video',
    durationSeconds: options.durationSeconds ?? 30,
    localPath: options.localPath,
  };
}

export function createImageItem(options: {
  id?: string;
  url: string;
  durationSeconds?: number;
  localPath?: string;
}): MediaItem {
  return {
    id: options.id ?? '',
    url: options.url,
    type: 'image',
    durationSeconds: options.durationSeconds ?? 10,
    localPath: options.localPath,
  };
}
