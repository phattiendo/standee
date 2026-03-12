/**
 * Registry để background fetch (hoặc watchdog) gọi refresh playlist
 * từ bên ngoài StandeePlayerScreen.
 */
let refreshFn: (() => Promise<void>) | null = null;

export function registerPlaylistRefresh(fn: (() => Promise<void>) | null): void {
  refreshFn = fn;
}

export function getPlaylistRefresh(): (() => Promise<void>) | null {
  return refreshFn;
}
