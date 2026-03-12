import { useCallback, useEffect, useRef, useState } from 'react';
import { fetchStandeeInfo } from '../data/datasources/sdpApiDataSource';
import { fetchPosters } from '../data/datasources/remoteMediaDataSource';
import { apiConstants } from '../core/constants/apiConstants';
import { registerPlaylistRefresh } from '../core/playlistRefreshRegistry';
import type { MediaItem } from '../data/models/MediaItem';
import { buildStandeePlaylist, type SlideItem } from '../data/types/playlist';

const REFRESH_INTERVAL_MS = 30 * 60 * 1000; // 30 phút

export function useStandeePlaylist(enabled: boolean) {
  const [playlist, setPlaylist] = useState<SlideItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const mountedRef = useRef(true);

  const refresh = useCallback(async () => {
    if (!enabled) return;
    setLoading(true);
    setError(null);
    try {
      const standeeInfo = await fetchStandeeInfo();
      const standeeId = standeeInfo?.standeeId ?? standeeInfo?.id ?? apiConstants.standeeId;
      let posters: MediaItem[] = [];
      if (apiConstants.slideshowShowPosters && standeeId) {
        posters = await fetchPosters(standeeId);
      }
      const duration =
        (standeeInfo?.displayDuration as number | undefined) ?? apiConstants.sdpDurationSeconds;
      const next = buildStandeePlaylist(posters, duration);
      if (mountedRef.current) {
        setPlaylist(next);
        setLoading(false);
        setError(null);
      }
    } catch (e) {
      const msg = e instanceof Error ? e.message : String(e);
      if (mountedRef.current) {
        setError(msg);
        const duration =
          apiConstants.sdpDurationSeconds;
        setPlaylist(buildStandeePlaylist([], duration));
        setLoading(false);
      }
    }
  }, [enabled]);

  useEffect(() => {
    mountedRef.current = true;
    return () => {
      mountedRef.current = false;
    };
  }, []);

  useEffect(() => {
    if (!enabled) return;
    refresh();
    const id = setInterval(refresh, REFRESH_INTERVAL_MS);
    return () => clearInterval(id);
  }, [enabled, refresh]);

  useEffect(() => {
    registerPlaylistRefresh(refresh);
    return () => registerPlaylistRefresh(null);
  }, [refresh]);

  return { playlist, loading, error, refresh };
}
