import { MMKV } from 'react-native-mmkv';

const storage = new MMKV({ id: 'standee-storage' });

const KEY_MEDIA_LIST = 'media_list';
const KEY_PLAYLIST_VERSION = 'playlist_version';
const KEY_SDP_CACHE = 'sdp_cache';
const KEY_WEATHER_CACHE = 'weather_cache';

export function getMediaListJson(): string | undefined {
  return storage.getString(KEY_MEDIA_LIST);
}

export function setMediaListJson(json: string): void {
  storage.set(KEY_MEDIA_LIST, json);
}

export function getPlaylistVersion(): number {
  const v = storage.getString(KEY_PLAYLIST_VERSION);
  if (v == null) return 0;
  const n = parseInt(v, 10);
  return isNaN(n) ? 0 : n;
}

export function setPlaylistVersion(version: number): void {
  storage.set(KEY_PLAYLIST_VERSION, String(version));
}

/** Cache SDP (standee, AQI, speedtest, posters) — đọc khi hiển thị SDP, ghi sau khi fetch xong. */
export function getSdpCacheJson(): string | undefined {
  return storage.getString(KEY_SDP_CACHE);
}

export function setSdpCacheJson(json: string): void {
  storage.set(KEY_SDP_CACHE, json);
}

/** Cache thời tiết — đọc khi hiển thị SDP, ghi khi WebSocket nhận payload mới. */
export function getWeatherCacheJson(): string | undefined {
  return storage.getString(KEY_WEATHER_CACHE);
}

export function setWeatherCacheJson(json: string): void {
  storage.set(KEY_WEATHER_CACHE, json);
}
