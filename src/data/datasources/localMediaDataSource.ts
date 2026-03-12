import * as mmkv from '../../core/storage/mmkvStorage';
import { MediaItem, mediaItemFromJson, mediaItemToJson } from '../models/MediaItem';

export async function init(): Promise<void> {
  // MMKV is sync; no async init needed
}

export function loadCachedMedia(): MediaItem[] {
  const jsonStr = mmkv.getMediaListJson();
  if (!jsonStr) return [];

  try {
    const decoded = JSON.parse(jsonStr) as unknown[];
    if (!Array.isArray(decoded)) return [];
    return decoded
      .filter((e): e is Record<string, unknown> => e != null && typeof e === 'object')
      .map(mediaItemFromJson);
  } catch {
    return [];
  }
}

export function saveMedia(items: MediaItem[]): void {
  if (items.length === 0) return;
  const list = items.map(mediaItemToJson);
  mmkv.setMediaListJson(JSON.stringify(list));
}

export function getPlaylistVersion(): number {
  return mmkv.getPlaylistVersion();
}

export function savePlaylistVersion(version: number): void {
  mmkv.setPlaylistVersion(version);
}
