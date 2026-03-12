/**
 * Thời tiết: REST GET /api/weather (lấy đủ data + hourly) + WebSocket /topic/weather (cập nhật realtime).
 * Mount: đọc cache ROM, gọi REST 1 lần để có hourly thật; WebSocket cập nhật khi có message.
 */
import { useEffect, useRef, useState } from 'react';
import { apiConstants } from '../core/constants/apiConstants';
import { getWeatherCacheJson, setWeatherCacheJson } from '../core/storage/mmkvStorage';
import { fetchWeather } from '../data/datasources/sdpApiDataSource';

export interface WeatherData {
  temp?: number;
  feelsLike?: number;
  high?: number;
  low?: number;
  humidity?: number;
  uv?: number;
  time?: string;
  weatherCode?: number;
  hourly?: Array<{ time: string; temp: number; weatherCode?: number }>;
}

/** Lấy chuỗi JSON từ body — có thể là raw STOMP frame (MESSAGE\n...\n\n{json}\u0000). */
function extractJsonBody(body: string): string {
  if (!body || typeof body !== 'string') return '';
  const trimmed = body.replace(/\u0000/g, '').trim();
  const idx = trimmed.indexOf('{');
  if (idx >= 0) {
    const rest = trimmed.slice(idx);
    let depth = 0;
    for (let i = 0; i < rest.length; i++) {
      if (rest[i] === '{') depth++;
      else if (rest[i] === '}') {
        depth--;
        if (depth === 0) return rest.slice(0, i + 1);
      }
    }
    return rest;
  }
  const afterHeaders = trimmed.split('\n\n')[1];
  return afterHeaders ? afterHeaders.trim() : trimmed;
}

/** Chuẩn hóa hourly từ API — giữ đủ 24 slot (00:00–23:00), UI sẽ slice từ giờ hiện tại. */
function normalizeHourly(rawHourly: unknown): WeatherData['hourly'] {
  if (!rawHourly || typeof rawHourly !== 'object') return undefined;
  const h = rawHourly as Record<string, unknown>;
  const timeArr = h.time as string[] | undefined;
  const tempArr = h.temperature_2m as number[] | undefined;
  const codeArr = (h.weather_code as number[] | undefined) ?? (h.weatherCode as number[] | undefined);
  if (Array.isArray(timeArr) && timeArr.length > 0) {
    return timeArr.slice(0, 24).map((time, i) => ({
      time: typeof time === 'string' ? (time.length >= 16 ? time.slice(11, 16) : time) : '--',
      temp: Array.isArray(tempArr) ? (tempArr[i] ?? 0) : 0,
      weatherCode: Array.isArray(codeArr) ? codeArr[i] : undefined,
    }));
  }
  if (Array.isArray(h)) {
    return (h as Array<Record<string, unknown>>).slice(0, 24).map((o) => ({
      time: typeof o.time === 'string' ? (o.time.length >= 16 ? o.time.slice(11, 16) : o.time) : '--',
      temp: typeof o.temp === 'number' ? o.temp : (o.temperature_2m as number) ?? 0,
      weatherCode: (o.weather_code as number) ?? (o.weatherCode as number),
    }));
  }
  return undefined;
}

/** Lấy số đầu tiên khác null/undefined từ nhiều key (để map đúng theo nhiều format API). */
function pickNumber(...sources: (number | unknown)[]): number | undefined {
  for (const v of sources) {
    if (typeof v === 'number' && !Number.isNaN(v)) return v;
  }
  return undefined;
}

/** Chuẩn hóa weather từ REST API (current/daily/hourly hoặc flat). Hỗ trợ nhiều tên trường. */
function normalizeRestWeather(rest: Record<string, unknown> | null): WeatherData | null {
  if (!rest || typeof rest !== 'object') return null;
  const cur = rest.current as Record<string, unknown> | undefined;
  const daily = rest.daily as Record<string, unknown> | undefined;
  const hourly = normalizeHourly(rest.hourly ?? (cur && (cur as Record<string, unknown>).hourly));
  const humidity = pickNumber(
    cur?.humidity,
    cur?.relative_humidity,
    cur?.relativeHumidity,
    rest.humidity,
    rest.relative_humidity
  );
  const uvRaw = pickNumber(cur?.uv_index, cur?.uvIndex, rest.uv_index, rest.uvIndex, rest.uv);
  return {
    temp: pickNumber(cur?.temperature, rest.temp),
    feelsLike: pickNumber(cur?.temperature, cur?.feels_like, rest.feelsLike, rest.feels_like),
    high: pickNumber(daily?.temperature_2m_max, rest.high, rest.temp_max),
    low: pickNumber(daily?.temperature_2m_min, rest.low, rest.temp_min),
    humidity,
    uv: uvRaw != null ? Math.round(uvRaw) : undefined,
    time: (cur?.time as string) ?? (rest.time as string),
    weatherCode: pickNumber(cur?.weatherCode, cur?.weather_code, rest.weatherCode, rest.weather_code),
    hourly: hourly?.length ? hourly : normalizeHourly(rest.hourly),
  };
}

/** Parse payload WebSocket — map humidity/uv từ current hoặc root, nhiều tên trường. */
function parseWeatherPayload(body: string): WeatherData | null {
  const jsonStr = extractJsonBody(body);
  if (!jsonStr) return null;
  try {
    const raw = JSON.parse(jsonStr) as Record<string, unknown>;
    const cur = raw?.current as Record<string, unknown> | undefined;
    const daily = raw?.daily as Record<string, unknown> | undefined;
    const hourly = normalizeHourly(raw?.hourly);
    const humidity = pickNumber(cur?.humidity, cur?.relative_humidity, cur?.relativeHumidity, raw.humidity);
    const uvRaw = pickNumber(cur?.uv_index, cur?.uvIndex, raw.uv_index, raw.uv);
    return {
      temp: cur?.temperature as number | undefined,
      feelsLike: (cur?.temperature as number) ?? undefined,
      high: daily?.temperature_2m_max as number | undefined,
      low: daily?.temperature_2m_min as number | undefined,
      humidity: humidity ?? undefined,
      uv: uvRaw != null ? Math.round(uvRaw) : undefined,
      time: cur?.time as string | undefined,
      weatherCode: (cur?.weatherCode as number) ?? (cur?.weather_code as number),
      hourly: hourly?.length ? hourly : undefined,
    };
  } catch {
    return null;
  }
}

function parseWeatherCache(json: string | undefined): WeatherData | null {
  if (!json) return null;
  try {
    return JSON.parse(json) as WeatherData;
  } catch {
    return null;
  }
}

export function useWeatherWebSocket(_enabled: boolean) {
  const [weather, setWeather] = useState<WeatherData | null>(() => parseWeatherCache(getWeatherCacheJson()));
  const [connected, setConnected] = useState(false);
  const [lastUpdatedAt, setLastUpdatedAt] = useState<Date | null>(null);
  const clientRef = useRef<{ deactivate: () => void } | null>(null);

  useEffect(() => {
    let cancelled = false;
    fetchWeather()
      .then((rest) => {
        if (cancelled) return;
        const data = rest && typeof rest === 'object' ? normalizeRestWeather(rest as Record<string, unknown>) : null;
        if (data) {
          setWeather((prev) => {
            const next = { ...prev, ...data };
            if (!next.hourly?.length && prev?.hourly?.length) next.hourly = prev.hourly;
            if (next.temp != null || next.hourly?.length) setWeatherCacheJson(JSON.stringify(next));
            return next;
          });
          console.log('[Weather REST] Loaded', { temp: data.temp, hourly: data.hourly?.length });
        }
      })
      .catch((e) => console.warn('[Weather REST]', e));
    return () => { cancelled = true; };
  }, []);

  useEffect(() => {
    let cancelled = false;
    const useSockJs = apiConstants.weatherUseSockJs;
    const connect = (Client: typeof import('@stomp/stompjs').Client) => {
      if (cancelled) return;
      const client = new Client({
        brokerURL: useSockJs ? '' : apiConstants.weatherWsConnectUrl,
        reconnectDelay: 5000,
        heartbeatIncoming: 4000,
        heartbeatOutgoing: 4000,
      });
      client.onConnect = () => {
        if (cancelled) return;
        setConnected(true);
        console.log('[Weather WS] Connected, subscribe:', apiConstants.weatherWsPath);
        client.subscribe(apiConstants.weatherWsPath, (message) => {
          if (cancelled) return;
          const data = parseWeatherPayload(message.body);
          if (data) {
            setWeather((prev) => {
              const next = { ...prev, ...data };
              if (!next.hourly?.length && prev?.hourly?.length) next.hourly = prev.hourly;
              setWeatherCacheJson(JSON.stringify(next));
              return next;
            });
            setLastUpdatedAt(new Date());
            console.log('[Weather WS] Received', { temp: data.temp, humidity: data.humidity, hourly: data.hourly?.length });
          } else {
            console.log('[Weather WS] Parse failed, body length:', message?.body?.length);
          }
        });
      };
      client.onStompError = (e) => {
        console.warn('[Weather WS] STOMP error', e);
        setConnected(false);
      };
      client.onWebSocketClose = () => {
        console.log('[Weather WS] Closed');
        setConnected(false);
      };
      if (useSockJs) {
        import('sockjs-client').then((SockJS) => {
          if (cancelled) return;
          (client as unknown as { webSocketFactory: () => unknown }).webSocketFactory = () =>
            new SockJS.default(apiConstants.weatherWsSockJsUrl);
          console.log('[Weather WS] Connecting (SockJS):', apiConstants.weatherWsSockJsUrl);
          client.activate();
          clientRef.current = client;
        }).catch((e) => console.warn('[Weather WS] SockJS load failed', e));
      } else {
        console.log('[Weather WS] Connecting:', apiConstants.weatherWsConnectUrl);
        client.activate();
        clientRef.current = client;
      }
    };
    import('@stomp/stompjs').then(({ Client }) => {
      connect(Client);
    }).catch((err) => {
      console.warn('[Weather WS] Init failed', err);
    });

    return () => {
      cancelled = true;
      clientRef.current?.deactivate?.();
      clientRef.current = null;
      setConnected(false);
    };
  }, []);

  return { weather, connected, lastUpdatedAt };
}
