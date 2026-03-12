import * as local from '../datasources/localMediaDataSource';
import * as remote from '../datasources/remoteMediaDataSource';
import { MediaItem } from '../models/MediaItem';
import {
  ensureDir,
  fullPath,
  getRootPath,
} from '../../core/storage/romMediaStorage';
import RNFS from 'react-native-fs';

let saveToRom = true;

export async function init(): Promise<void> {
  await local.init();
}

export function loadInitial(): MediaItem[] {
  return local.loadCachedMedia();
}

export async function checkVersionAndUpdateIfNeeded(): Promise<MediaItem[] | null> {
  const localVersion = local.getPlaylistVersion();
  const remoteVersion = await remote.fetchVersion();
  if (remoteVersion <= 0 || remoteVersion <= localVersion) return null;
  const updated = await refreshFromRemote();
  if (updated.length > 0) {
    local.savePlaylistVersion(remoteVersion);
    return updated;
  }
  return null;
}

async function downloadToRom(items: MediaItem[]): Promise<MediaItem[]> {
  await ensureDir();
  const root = await getRootPath();
  const result: MediaItem[] = [];
  for (const item of items) {
    if (item.type !== 'image' && item.type !== 'video') {
      result.push(item);
      continue;
    }
    if (!item.url.startsWith('http')) {
      result.push(item);
      continue;
    }
    try {
      const filename = item.url.split('/').pop() ?? `media_${item.id}`;
      const subdir = item.type === 'video' ? 'videos' : 'images';
      const dest = `${root}/${subdir}/${filename}`;
      await RNFS.downloadFile({ fromUrl: item.url, toFile: dest }).promise;
      result.push({ ...item, localPath: `${subdir}/${filename}` });
    } catch {
      result.push(item);
    }
  }
  return result;
}

export async function refreshFromRemote(): Promise<MediaItem[]> {
  const remoteItems = await remote.fetchMediaList();
  if (remoteItems.length === 0) return remoteItems;

  const toSave = saveToRom ? await downloadToRom(remoteItems) : remoteItems;
  local.saveMedia(toSave);
  return toSave;
}

/** Resolve relative localPath to full path. */
export function resolveLocalPath(relativePath: string): string | null {
  return fullPath(relativePath);
}

export function setSaveToRom(value: boolean): void {
  saveToRom = value;
}

export { getRootPath };
