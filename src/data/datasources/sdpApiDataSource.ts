/**
 * API chỉ cho SDP: air-quality, speedtest, standee.
 * Không dùng cho video/nhạc.
 */
import { getHttpClient } from '../../core/network/httpClient';
import { apiConstants } from '../../core/constants/apiConstants';

export interface AirQualityData {
  time?: string;
  pm2_5?: number;
  pm10?: number;
  sulphur_dioxide?: number;
  nitrogen_dioxide?: number;
  ozone?: number;
  carbon_monoxide?: number;
  us_aqi?: number;
  aqi?: number;
  pm25?: number;
  [key: string]: unknown;
}

export interface SpeedTestData {
  download?: number;
  upload?: number;
  downloadSpeed?: number;
  uploadSpeed?: number;
  ping?: number;
  [key: string]: unknown;
}

export interface StandeeInfoData {
  id?: string;
  standeeId?: string;
  name?: string;
  alias?: string;
  displayDuration?: number;
  [key: string]: unknown;
}

/** Item trả về từ GET /api/standee (result[]). */
export interface StandeeListItem {
  standeeId: string;
  standeeName: string;
  alias: string;
  mainTitle?: string;
  subTitle?: string;
  displayDuration?: number;
  spaceId?: string;
}

export interface WeatherData {
  temp?: number;
  feelsLike?: number;
  high?: number;
  low?: number;
  humidity?: number;
  uv?: number;
  location?: string;
  description?: string;
  hourly?: Array<{ time?: string; temp?: number }>;
  [key: string]: unknown;
}

/** Lấy object bên trong nếu API trả về { data: ... } hoặc { result: ... } */
function unwrap<T = unknown>(raw: unknown): T | null {
  if (raw == null) return null;
  if (typeof raw !== 'object') return null;
  const o = raw as Record<string, unknown>;
  const inner = o.data ?? o.result ?? o;
  return (inner && typeof inner === 'object' ? inner : raw) as T;
}

/** GET /api/weather/air-quality — response: { code, result: { time, pm2_5, pm10, us_aqi, ... } } */
export async function fetchAirQuality(): Promise<AirQualityData | null> {
  try {
    const res = await getHttpClient().get(apiConstants.airQualityPath);
    const data = unwrap<AirQualityData>(res.data);
    if (data && typeof data === 'object') {
      data.aqi = data.aqi ?? data.us_aqi;
      data.pm25 = data.pm25 ?? data.pm2_5;
      return data;
    }
    return (res.data && typeof res.data === 'object' ? res.data : null) as AirQualityData | null;
  } catch (e) {
    console.warn('[fetchAirQuality]', e instanceof Error ? e.message : e);
    return null;
  }
}

export async function fetchSpeedTest(): Promise<SpeedTestData | null> {
  try {
    const res = await getHttpClient().get(apiConstants.speedTestPath);
    const raw = unwrap(res.data);
    if (Array.isArray(raw) && raw.length > 0) return raw[0] as SpeedTestData;
    if (raw && typeof raw === 'object') return raw as SpeedTestData;
    const data = res.data;
    if (Array.isArray(data) && data.length > 0) return data[0] as SpeedTestData;
    if (data && typeof data === 'object') return data as SpeedTestData;
    return null;
  } catch {
    return null;
  }
}

/** Lấy danh sách standee từ GET /api/standee (response.result). */
export async function fetchStandeeList(): Promise<StandeeListItem[]> {
  try {
    const res = await getHttpClient().get(apiConstants.standeeInfoPath);
    const raw = unwrap(res.data);
    if (Array.isArray(raw)) {
      return raw.filter(
        (x): x is StandeeListItem =>
          x != null && typeof x === 'object' && typeof (x as StandeeListItem).standeeId === 'string'
      ) as StandeeListItem[];
    }
    return [];
  } catch {
    return [];
  }
}

/** Lấy standee hiện tại (theo apiConstants.standeeId) và format name = "Standee " + alias. */
export async function fetchStandeeInfo(): Promise<StandeeInfoData | null> {
  try {
    const list = await fetchStandeeList();
    const current = list.find((s) => s.standeeId === apiConstants.standeeId) ?? list[0];
    if (!current) return null;
    const name = 'Standee ' + (current.alias ?? current.standeeName ?? 'STANDEE').trim();
    return {
      id: current.standeeId,
      standeeId: current.standeeId,
      name,
      alias: current.alias,
      displayDuration: current.displayDuration,
    };
  } catch {
    return null;
  }
}

export async function fetchWeather(): Promise<WeatherData | null> {
  try {
    const url = `${apiConstants.baseUrl}${apiConstants.weatherPath}`;
    console.log('[Weather REST] GET', url);
    const res = await getHttpClient().get(apiConstants.weatherPath);
    const data = unwrap<WeatherData>(res.data);
    const out = (data && typeof data === 'object' ? data : (res.data && typeof res.data === 'object' ? res.data : null)) as WeatherData | null;
    console.log('[Weather REST] OK', out ? { temp: out.temp, humidity: out.humidity } : 'null');
    return out;
  } catch (e) {
    console.warn('[Weather REST] Error', e);
    return null;
  }
}
