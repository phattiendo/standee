import RNFS from 'react-native-fs';

const DIR_NAME = 'standee_media';
const IMAGES_DIR = 'images';
const VIDEOS_DIR = 'videos';
const AUDIO_DIR = 'audio';
const CACHE_DIR = 'cache';

let rootPath: string | null = null;

export async function getRootPath(): Promise<string> {
  if (rootPath) return rootPath;
  const docs = RNFS.DocumentDirectoryPath;
  rootPath = `${docs}/${DIR_NAME}`;
  return rootPath;
}

export async function ensureDir(): Promise<void> {
  const base = await getRootPath();
  for (const sub of [IMAGES_DIR, VIDEOS_DIR, AUDIO_DIR, CACHE_DIR]) {
    const dir = `${base}/${sub}`;
    const exists = await RNFS.exists(dir);
    if (!exists) await RNFS.mkdir(dir);
  }
}

/** Full path cho relative localPath (vd. images/xxx.jpg). */
export function fullPath(relativePath: string): string | null {
  if (!relativePath || !rootPath) return null;
  if (relativePath.startsWith('/')) return relativePath;
  return `${rootPath}/${relativePath}`;
}

/** Path ROM cho video local (sau khi copy asset). */
let localVideoRomPath: string | null = null;
export function getLocalVideoRomPath(): string | null {
  return localVideoRomPath;
}
export function setLocalVideoRomPath(path: string | null): void {
  localVideoRomPath = path;
}

/** Path nhạc nền ROM. */
let backgroundMusicRomPath: string | null = null;
export function getBackgroundMusicRomPath(): string | null {
  return backgroundMusicRomPath;
}
export function setBackgroundMusicRomPath(path: string | null): void {
  backgroundMusicRomPath = path;
}
