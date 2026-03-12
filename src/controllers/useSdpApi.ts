import { useCallback, useEffect, useRef, useState } from 'react';
import {
  fetchAirQuality,
  fetchSpeedTest,
  fetchStandeeInfo,
  type AirQualityData,
  type SpeedTestData,
  type StandeeInfoData,
} from '../data/datasources/sdpApiDataSource';
import { fetchPosters } from '../data/datasources/remoteMediaDataSource';
import type { MediaItem } from '../data/models/MediaItem';
import { apiConstants } from '../core/constants/apiConstants';
import { getSdpCacheJson, setSdpCacheJson } from '../core/storage/mmkvStorage';

const POLL_INTERVAL_MS = 5 * 60 * 1000; // 5 phút — chỉ cập nhật khi data đổi, hiển thị luôn từ ROM

function parseSdpCache(json: string | undefined): Partial<SdpApiState> | null {
  if (!json) return null;
  try {
    const raw = JSON.parse(json) as Record<string, unknown>;
    return {
      airQuality: (raw.airQuality as AirQualityData) ?? null,
      speedTest: (raw.speedTest as SpeedTestData) ?? null,
      standeeInfo: (raw.standeeInfo as StandeeInfoData) ?? null,
      posters: Array.isArray(raw.posters) ? (raw.posters as MediaItem[]) : [],
      displayDurationSeconds:
        typeof raw.displayDurationSeconds === 'number' ? raw.displayDurationSeconds : apiConstants.sdpDurationSeconds,
    };
  } catch {
    return null;
  }
}

export interface SdpApiState {
  airQuality: AirQualityData | null;
  speedTest: SpeedTestData | null;
  standeeInfo: StandeeInfoData | null;
  posters: MediaItem[];
  displayDurationSeconds: number;
  loading: boolean;
  error: string | null;
}

const emptyState: SdpApiState = {
  airQuality: null,
  speedTest: null,
  standeeInfo: null,
  posters: [],
  displayDurationSeconds: apiConstants.sdpDurationSeconds,
  loading: true,
  error: null,
};

export function useSdpApi(enabled: boolean) {
  const [state, setState] = useState<SdpApiState>(() => {
    const cached = parseSdpCache(getSdpCacheJson());
    if (cached) {
      return { ...emptyState, ...cached, loading: false, error: null };
    }
    return emptyState;
  });
  const mountedRef = useRef(true);

  const refresh = useCallback(async () => {
    if (!enabled) return;
    const hasCache = getSdpCacheJson() != null;
    if (!hasCache) {
      setState((s) => ({ ...s, loading: true, error: null }));
    }
    console.log('[SDP API] Refresh start', hasCache ? '(background)' : '(initial)');
    try {
      const [airResult, speedResult, standeeResult] = await Promise.allSettled([
        fetchAirQuality(),
        fetchSpeedTest(),
        fetchStandeeInfo(),
      ]);
      const airQuality = airResult.status === 'fulfilled' ? airResult.value : null;
      const speedTest = speedResult.status === 'fulfilled' ? speedResult.value : null;
      const standeeInfo = standeeResult.status === 'fulfilled' ? standeeResult.value : null;
      if (airResult.status === 'rejected') console.warn('[SDP API] Air quality failed', airResult.reason);
      if (speedResult.status === 'rejected') console.warn('[SDP API] Speed test failed', speedResult.reason);
      if (standeeResult.status === 'rejected') console.warn('[SDP API] Standee info failed', standeeResult.reason);
      const standeeId = standeeInfo?.standeeId ?? standeeInfo?.id ?? apiConstants.standeeId;
      const displayDurationSeconds =
        (standeeInfo?.displayDuration as number | undefined) ?? apiConstants.sdpDurationSeconds;
      let posters: MediaItem[] = [];
      if (standeeId) {
        try {
          posters = await fetchPosters(standeeId);
        } catch (_) {}
      }
      if (!mountedRef.current) return;
      const next = {
        airQuality,
        speedTest,
        standeeInfo,
        posters,
        displayDurationSeconds,
        loading: false,
        error: null,
      };
      setSdpCacheJson(JSON.stringify(next));
      console.log('[SDP API] Refresh OK, saved to ROM', { standee: standeeInfo?.name, posters: posters.length });
      setState(next);
    } catch (e) {
      if (!mountedRef.current) return;
      const msg = e instanceof Error ? e.message : String(e);
      console.warn('[SDP API] Refresh error', msg);
      setState((s) => ({ ...s, loading: false, error: msg }));
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
    const id = setInterval(refresh, POLL_INTERVAL_MS);
    return () => clearInterval(id);
  }, [enabled, refresh]);

  return { ...state, refresh };
}
