/**
 * SDP layout: kích thước theo màn hình, header có logo trái (iic15) + tên standee giữa + powerd-by-IIC phải.
 * Ô thời tiết thu gọn, đủ chỗ ô khuyến nghị sức khỏe; ngày/giờ dùng date-fns.
 * Poster lấy từ API /api/poster/{standeeId}/withActivePosters; nhạc nền /audio/nhacbuoisang.mp3.
 */
import React, { useEffect, useRef, useState } from 'react';
import {
  Image,
  ImageBackground,
  StyleSheet,
  Text,
  TextStyle,
  View,
  useWindowDimensions,
} from 'react-native';
import Video from 'react-native-video';
import { format } from 'date-fns';
import { vi } from 'date-fns/locale';
import { AqiGauge } from '../components/AqiGauge';
import { AqiIconView } from '../components/AqiIconView';
import { GlassView } from '../components/GlassView';
import { MediaImage } from '../components/MediaImage';
import { MediaVideo } from '../components/MediaVideo';
import { SpeedGauge } from '../components/SpeedGauge';
import { getWeatherEffect, WeatherLottieView } from '../components/WeatherLottieView';
import { useSdpApi } from '../controllers/useSdpApi';
import { useWeatherWebSocket } from '../controllers/useWeatherWebSocket';
import { apiConstants } from '../core/constants/apiConstants';
import { FONT_BOLD, FONT_ITALIC, FONT_REGULAR, FONT_SEMI_BOLD } from '../core/theme/typography';
import type { MediaItem } from '../data/models/MediaItem';

const TETVE_BG = require('../../assets/tetve.jpg');
const LOGO_LEFT_PNG = require('../../assets/iic15.png');
const LOGO_RIGHT_PNG = require('../../assets/powerd-by-IIC-logo.png');

function formatTemp(n: number | undefined): string {
  if (n == null) return '--';
  return `${Math.round(n)}°`;
}

function formatSpeed(n: number | undefined): string {
  if (n == null) return '--';
  const mbps = n > 10_000 ? n / 1_000_000 : n;
  return `${Math.round(mbps * 10) / 10} Mbps`;
}

/** Chỉ số tốc độ (để đè lên gauge), vd. "92.3". */
function formatSpeedValueOnly(n: number | undefined): string {
  if (n == null) return '--';
  const mbps = n > 10_000 ? n / 1_000_000 : n;
  return String(Math.round(mbps * 10) / 10);
}

/** Ping là thời gian (ms), không phải Mbps. */
function formatPing(ms: number | undefined): string {
  if (ms == null) return '--';
  return `${Math.round(ms)} ms`;
}

function formatAqi(n: number | undefined): string {
  if (n == null) return '--';
  return String(Math.round(n));
}

/** Mô tả ngắn theo US AQI (giống ảnh "Great air here today"). */
function getAqiDescription(aqi: number | undefined): string {
  if (aqi == null) return '--';
  const v = Math.round(aqi);
  if (v <= 50) return 'Không khí tốt';
  if (v <= 100) return 'Chất lượng trung bình';
  if (v <= 150) return 'Nhạy cảm nên hạn chế ra ngoài';
  if (v <= 200) return 'Không tốt cho sức khỏe';
  return 'Rất không tốt';
}

function getSpeedMbps(n: number | undefined): number {
  if (n == null) return 0;
  return n > 10_000 ? n / 1_000_000 : n;
}

function formatHourLabel(timeStr: string | undefined, index: number): string {
  if (index === 0) return 'Now';
  return timeStr ?? '--';
}

/** Chuẩn giờ hiển thị sang 24h "HH:mm" (9:00 → 09:00, 13:00 giữ nguyên). */
function to24hLabel(timeStr: string | undefined): string {
  if (!timeStr || typeof timeStr !== 'string') return '--';
  const m = timeStr.trim().match(/^(\d{1,2})\s*:\s*(\d{1,2})/i) ?? timeStr.match(/^(\d{1,2})/);
  if (!m) return timeStr;
  const h = parseInt(m[1], 10) % 24;
  const min = m[2] != null ? parseInt(m[2], 10) % 60 : 0;
  return `${String(h).padStart(2, '0')}:${String(min).padStart(2, '0')}`;
}

/** Lấy 12 slot hourly từ giờ hiện tại. Nếu có đủ 24 phần tử thì index = giờ (0=00:00 .. 23=23:00). */
function getHourlyFromNow(
  hourly: Array<{ time: string; temp: number; weatherCode?: number }>,
  maxItems: number
): Array<{ time: string; temp: number; weatherCode?: number }> {
  if (!hourly.length) return [];
  const nowHour = new Date().getHours();
  let start: number;
  if (hourly.length >= 24) {
    start = nowHour;
  } else {
    const parseHour = (t: string) => {
      const match = t?.match(/^(\d{1,2})/);
      return match ? parseInt(match[1], 10) % 24 : 0;
    };
    start = 0;
    for (let i = 0; i < hourly.length; i++) {
      if (parseHour(hourly[i].time) >= nowHour) {
        start = i;
        break;
      }
    }
  }
  const out: Array<{ time: string; temp: number; weatherCode?: number }> = [];
  const n = hourly.length;
  for (let i = 0; i < maxItems; i++) {
    const item = hourly[(start + i) % n];
    const hour = n >= 24 ? (start + i) % 24 : undefined;
    const timeLabel = hour != null ? `${String(hour).padStart(2, '0')}:00` : to24hLabel(item.time);
    out.push({ ...item, time: timeLabel });
  }
  return out;
}

/** Icon thời tiết đơn giản theo WMO code (0=clear, 1-3=cloudy, 80+=mưa/g storms). */
function WeatherIcon({ code, iconStyle }: { code?: number; iconStyle?: TextStyle }) {
  const s = iconStyle ?? styles.weatherIcon;
  const c = code ?? 0;
  if (c >= 80) return <Text style={s}>🌧</Text>;
  if (c >= 61) return <Text style={s}>🌧</Text>;
  if (c >= 50) return <Text style={s}>🌫</Text>;
  if (c >= 1) return <Text style={s}>⛅</Text>;
  return <Text style={s}>☀</Text>;
}

const PAD_H = 24;
const PAD_TOP = 16;
const PAD_BOTTOM = 16;
const HEADER_HEIGHT_RATIO = 0.06;
const WEATHER_FLEX = 0.28;
const MAIN_ROW_FLEX = 0.42;
const HEALTH_FLEX = 0.25;
const MAIN_ROW_LEFT_RATIO = 0.48;
const GAP = 12;
/** Khoảng cách cắt giữa các khối: trên, dưới, trái, phải mỗi khối đều có margin này */
const BLOCK_GAP = 10;

/** Nhạc nền: phát /audio/nhacbuoisang.mp3 khi mount (ẩn, chỉ audio). */
function BackgroundAudio() {
  return (
    <Video
      source={{ uri: apiConstants.audioUrl }}
      style={styles.backgroundAudio}
      repeat
      muted={false}
      ignoreSilentSwitch="ignore"
      resizeMode="none"
      // @ts-expect-error - audioOnly có thể có trong react-native-video
      audioOnly
    />
  );
}

/** Mỗi slide (SDP hoặc poster) hiển thị 15 giây rồi chuyển. */
const SDP_POSTER_DURATION_SECONDS = 15;

/** Chu kỳ poster: poster0 → poster1 → ... → posterN → lặp lại, không hiển thị SDP trong ô phải. */
function PosterSlideshow({
  posters,
  panelHeight,
}: {
  posters: MediaItem[];
  panelHeight: number;
}) {
  const [index, setIndex] = useState(0);
  const intervalRef = useRef<ReturnType<typeof setInterval> | null>(null);

  useEffect(() => {
    if (posters.length <= 1) return;
    intervalRef.current = setInterval(() => {
      setIndex((i) => (i + 1) % posters.length);
    }, SDP_POSTER_DURATION_SECONDS * 1000);
    return () => {
      if (intervalRef.current) clearInterval(intervalRef.current);
    };
  }, [posters.length]);

  if (posters.length === 0) {
    return <Text style={styles.posterPlaceholder}>Chưa có poster</Text>;
  }

  const poster = posters[index % posters.length];
  const url = (poster.url ?? '').trim();

  return (
    <View style={[StyleSheet.absoluteFill, { height: panelHeight }]}>
      {poster.type === 'video' ? <MediaVideo url={url} /> : <MediaImage url={url} />}
    </View>
  );
}

export function SDPScreen() {
  const { width: screenWidth, height: screenHeight } = useWindowDimensions();
  const { weather, connected, lastUpdatedAt } = useWeatherWebSocket(true);
  const { airQuality, speedTest, standeeInfo, posters, loading } = useSdpApi(true);
  const [now, setNow] = useState(() => new Date());
  useEffect(() => {
    const id = setInterval(() => setNow(new Date()), 1000);
    return () => clearInterval(id);
  }, []);
  const locationLabel = standeeInfo?.name ?? 'BINH DUONG - TP HO CHI MINH';
  const dateLabel = format(now, 'dd/MM HH:mm MMMM', { locale: vi });
  const updatedLabel = lastUpdatedAt ? format(lastUpdatedAt, 'HH:mm', { locale: vi }) : (connected ? 'live' : '--:--');
  const speedUpdatedTime = format(now, 'HH:mm', { locale: vi });

  const contentWidth = screenWidth - PAD_H * 2;
  const blockWidth = contentWidth - BLOCK_GAP * 2;
  const contentHeight = screenHeight - PAD_TOP - PAD_BOTTOM;
  const headerHeight = Math.max(28, contentHeight * HEADER_HEIGHT_RATIO);
  const logoSize = Math.min(72, headerHeight * 0.8);
  const bodyHeight = contentHeight - headerHeight - GAP - BLOCK_GAP * 2;
  const availableBody = bodyHeight - BLOCK_GAP * 6;
  const weatherPanelHeight = availableBody * WEATHER_FLEX;
  const mainRowHeight = availableBody * MAIN_ROW_FLEX;
  const healthPanelMinHeight = availableBody * HEALTH_FLEX;
  const halfMain = mainRowHeight / 2;
  const blockMargin = BLOCK_GAP;
  const leftColWidth = blockWidth * MAIN_ROW_LEFT_RATIO;
  /** Gauge + số Mbps + header + hàng Ping/Download/Upload phải vừa trong nửa ô: trừ chỗ header ~44, label ~58, footer ~44. */
  const speedGaugeSize = Math.min(leftColWidth - 24, Math.max(70, halfMain - 146));

  const standeeName = standeeInfo?.name ?? 'STANDEE';
  const hourlyRaw = weather?.hourly ?? [];
  const maxHourly = Math.min(12, Math.floor(blockWidth / 52));
  const hourly = getHourlyFromNow(hourlyRaw, maxHourly);

  return (
    <ImageBackground
      source={TETVE_BG}
      style={[styles.bg, { width: screenWidth, height: screenHeight }]}
      resizeMode="cover"
    >
      <BackgroundAudio />
      <View
        style={[
          styles.sdpContent,
          {
            width: screenWidth,
            height: screenHeight,
            paddingHorizontal: PAD_H,
            paddingTop: PAD_TOP,
            paddingBottom: PAD_BOTTOM,
          },
        ]}
      >
        {/* Header: 1 cụm = logo trái + text + logo phải */}
        <GlassView style={StyleSheet.flatten([styles.header, { height: headerHeight, width: blockWidth, margin: blockMargin }])}>
          <View style={styles.headerGroup}>
            <View style={[styles.headerLogoWrap, { width: logoSize * 2.6, height: logoSize }]}>
              <Image source={LOGO_LEFT_PNG} style={{ width: logoSize * 2.6, height: logoSize }} resizeMode="contain" />
            </View>
            <Text style={styles.headerTitle} numberOfLines={1}>
              {standeeName}
            </Text>
            <View style={[styles.headerLogoWrap, { width: logoSize * 2.6, height: logoSize }]}>
              <Image source={LOGO_RIGHT_PNG} style={{ width: logoSize * 2.6, height: logoSize }} resizeMode="contain" />
            </View>
          </View>
        </GlassView>

        {/* Body: weather + main row + health — chia theo tỷ lệ, không tràn màn hình */}
        <View style={[styles.body, { flex: 1, minHeight: 0 }]}>
          {/* Ô thời tiết */}
          <GlassView style={StyleSheet.flatten([styles.weatherPanel, { width: blockWidth, height: weatherPanelHeight, margin: blockMargin }])}>
            <View style={styles.weatherEffectWrap} pointerEvents="none">
              <WeatherLottieView
                weatherCode={weather?.weatherCode}
                style={StyleSheet.absoluteFillObject}
                width={blockWidth}
                height={weatherPanelHeight}
              />
            </View>
            {(apiConstants.weatherEffectOverride ?? getWeatherEffect(weather?.weatherCode)) === 'storm' && (
              <View style={styles.weatherStormOverlay} pointerEvents="none" />
            )}
            <View style={styles.weatherContentWrap}>
            <View style={styles.weatherHeader}>
              <View>
                <Text style={styles.weatherLocation} numberOfLines={1}>{locationLabel}</Text>
                <Text style={styles.weatherDate} numberOfLines={1}>{dateLabel}</Text>
              </View>
              <View style={styles.weatherUpdatedWrap}>
                <View style={styles.weatherUpdatedIcon} />
                <Text style={styles.weatherUpdated}>Updated</Text>
                <Text style={styles.weatherUpdatedTime}>{updatedLabel}</Text>
              </View>
            </View>
            <View style={styles.weatherTop}>
              <View style={styles.weatherSideBlock}>
                <Text style={styles.bigValue}>{weather?.humidity ?? '--'}%</Text>
                <Text style={styles.label}>Humidity</Text>
              </View>
              <View style={styles.tempBlock}>
                <View style={styles.tempRow}>
                  <Text style={styles.tempMain}>{formatTemp(weather?.temp)}</Text>
                  <WeatherIcon code={weather?.weatherCode} />
                </View>
                <Text style={styles.tempSub}>Feels Like {formatTemp(weather?.feelsLike)}</Text>
                <Text style={styles.tempSub}>High {formatTemp(weather?.high)} • Low {formatTemp(weather?.low)}</Text>
              </View>
              <View style={styles.weatherSideBlock}>
                <Text style={styles.bigValue}>{weather?.uv ?? '--'}</Text>
                <Text style={styles.label}>UV</Text>
              </View>
            </View>
            <View style={styles.hourlyStrip}>
              {hourly.length > 0
                ? hourly.map((h, i) => (
                    <View key={i} style={styles.hourlyItemFlex}>
                      <Text style={styles.hourlyTemp} numberOfLines={1}>{Math.round(h.temp)}°</Text>
                      <View style={styles.hourlyIconWrap}>
                        <WeatherIcon code={h.weatherCode ?? weather?.weatherCode} iconStyle={styles.hourlyIcon} />
                      </View>
                      <Text style={styles.hourlyTime} numberOfLines={1}>{formatHourLabel(h.time, i)}</Text>
                    </View>
                  ))
                : null}
            </View>
            </View>
          </GlassView>


          {/* Khuyến nghị sức khỏe — flex:1 chiếm phần còn lại, nội dung dài/chữ to vẫn đủ chỗ */}
          <GlassView style={StyleSheet.flatten([styles.healthPanel, { width: blockWidth, flex: 1, minHeight: healthPanelMinHeight, margin: blockMargin }])}>
            <View style={styles.healthContent}>
              <View style={styles.healthBlock}>
                <Text style={styles.healthIntro} numberOfLines={1}>
                  Nhiệt độ {formatTemp(weather?.temp)}, độ ẩm {weather?.humidity ?? '--'}%:
                </Text>
                <Text style={styles.healthRecommend} numberOfLines={2}>
                  Uống đủ nước để tránh mất nước và mệt mỏi.
                </Text>
              </View>
              <View style={styles.healthBlock}>
                <Text style={styles.healthIntro} numberOfLines={1}>
                  Tia UV mức {weather?.uv ?? '--'}:
                </Text>
                <Text style={styles.healthRecommend} numberOfLines={2}>
                  Hạn chế ra nắng lâu, nếu ra ngoài hãy mang mũ, kính râm và bôi kem chống nắng.
                </Text>
              </View>
              <View style={styles.healthBlock}>
                <Text style={styles.healthIntro} numberOfLines={1}>
                  Khuyến nghị:
                </Text>
                <Text style={styles.healthRecommend} numberOfLines={2}>
                  Không hoạt động mạnh ngoài trời lâu, hãy nghỉ ngơi ở nơi râm mát để bảo vệ sức khỏe.
                </Text>
              </View>
            </View>
          </GlassView>

          {/* Hàng: Trái (Chất lượng không khí + Tốc độ mạng) | Phải (poster) */}
          <View style={[styles.mainRow, { width: blockWidth, height: mainRowHeight, margin: blockMargin }]}>
            <View style={[styles.leftColumn, { width: blockWidth * MAIN_ROW_LEFT_RATIO, height: mainRowHeight, gap: GAP }]}>
              {/* Ô Chất lượng không khí — row1: icon + mô tả + US AQI/Cập nhật; row2: số AQI; row3: gauge; row4: chi tiết. */}
              <GlassView style={StyleSheet.flatten([styles.boxPanel, styles.aqiPanel, styles.panelClip, { flex: 1, minHeight: 0 }])}>
                <View style={styles.aqiHeaderRow}>
                  <AqiIconView aqi={airQuality?.us_aqi ?? airQuality?.aqi ?? airQuality?.pm2_5} size={62} />
                  <View style={styles.aqiDescWrap}>
                    <Text style={styles.aqiDesc} numberOfLines={2}>{getAqiDescription(airQuality?.us_aqi ?? airQuality?.aqi ?? airQuality?.pm2_5)}</Text>
                  </View>
                  <View style={styles.aqiHeaderRight}>
                    <Text style={styles.aqiUnit}>US AQI</Text>
                    <Text style={styles.aqiUpdatedLabel}>Cập nhật</Text>
                    <Text style={styles.aqiUpdatedTime}>{speedUpdatedTime}</Text>
                  </View>
                </View>
                <View style={styles.aqiBigValueRow}>
                  <Text style={styles.aqiBigValue} numberOfLines={1}>{formatAqi(airQuality?.us_aqi ?? airQuality?.aqi ?? airQuality?.pm2_5)}</Text>
                </View>
                <View style={styles.aqiGaugeWrap}>
                  <AqiGauge
                    value={(airQuality?.us_aqi ?? airQuality?.aqi ?? airQuality?.pm2_5 ?? 0) as number}
                    width={Math.max(80, leftColWidth - 32)}
                    max={200}
                  />
                </View>
                <View style={styles.aqiDetailRow}>
                  <View style={styles.aqiDetailCol}>
                    <Text style={styles.aqiDetailLabel}>PM2.5</Text>
                    <Text style={styles.aqiDetailValue} numberOfLines={1}>{airQuality?.pm2_5 ?? airQuality?.pm25 ?? '--'}</Text>
                  </View>
                  <View style={styles.aqiDetailCol}>
                    <Text style={styles.aqiDetailLabel}>PM10</Text>
                    <Text style={styles.aqiDetailValue} numberOfLines={1}>{airQuality?.pm10 ?? '--'}</Text>
                  </View>
                  <View style={styles.aqiDetailCol}>
                    <Text style={styles.aqiDetailLabel}>O₃</Text>
                    <Text style={styles.aqiDetailValue} numberOfLines={1}>{airQuality?.ozone ?? '--'}</Text>
                  </View>
                  <View style={styles.aqiDetailCol}>
                    <Text style={styles.aqiDetailLabel}>CO</Text>
                    <Text style={styles.aqiDetailValue} numberOfLines={1}>{airQuality?.carbon_monoxide ?? '--'}</Text>
                  </View>
                </View>
              </GlassView>
              {/* Ô Tốc độ mạng — header, gauge + số Mbps, 3 cột Ping/Download/Upload; mọi thứ nằm trong ô, không tràn. */}
              <GlassView style={StyleSheet.flatten([styles.boxPanel, styles.speedPanel, styles.panelClip, { flex: 1, minHeight: 0 }])}>
                <View style={styles.speedPanelHeader}>
                  <View style={styles.speedTitleWrap}>
                    <Text style={styles.speedPanelTitle} numberOfLines={2}>Tốc độ mạng</Text>
                  </View>
                  <View style={styles.updatedWrap}>
                    <Text style={styles.speedUpdatedLabel}>Cập nhật</Text>
                    <Text style={styles.speedUpdatedTime}>{speedUpdatedTime}</Text>
                  </View>
                </View>
                <View style={styles.speedCenterBlock}>
                  <View style={[styles.speedGaugeWrap, { width: speedGaugeSize, height: speedGaugeSize }]}>
                    <SpeedGauge
                      value={getSpeedMbps(speedTest?.download ?? speedTest?.downloadSpeed)}
                      max={100}
                      size={speedGaugeSize}
                      showValueLabel={false}
                    />
                    <View style={styles.speedValueOverlay} pointerEvents="none">
                      <Text style={[styles.speedValueText, { fontSize: Math.min(66, Math.max(14, Math.round(speedGaugeSize * 0.3))) }]} numberOfLines={1}>
                        {formatSpeedValueOnly(speedTest?.download ?? speedTest?.downloadSpeed)}
                      </Text>
                      <Text style={[styles.speedUnitOverlay, { fontSize: Math.min(16, Math.max(10, Math.round(speedGaugeSize * 0.13))) }]}>Mbps</Text>
                    </View>
                  </View>
                </View>
                <View style={styles.speedDetailRow}>
                  <View style={styles.speedDetailCol}>
                    <Text style={styles.speedDetailLabel}>Ping</Text>
                    <Text style={styles.speedDetailValue} numberOfLines={1}>{formatPing(speedTest?.ping)}</Text>
                  </View>
                  <View style={styles.speedDetailCol}>
                    <Text style={styles.speedDetailLabel}>Download</Text>
                    <Text style={styles.speedDetailValue} numberOfLines={1}>{formatSpeed(speedTest?.download ?? speedTest?.downloadSpeed)}</Text>
                  </View>
                  <View style={styles.speedDetailCol}>
                    <Text style={styles.speedDetailLabel}>Upload</Text>
                    <Text style={styles.speedDetailValue} numberOfLines={1}>{formatSpeed(speedTest?.upload ?? speedTest?.uploadSpeed)}</Text>
                  </View>
                </View>
              </GlassView>
            </View>
            <GlassView style={StyleSheet.flatten([styles.posterPanel, { flex: 1, height: mainRowHeight }])}>
              <PosterSlideshow posters={posters} panelHeight={mainRowHeight} />
            </GlassView>
          </View>

          
        </View>

        {loading ? <Text style={styles.loadingText}>Đang tải dữ liệu...</Text> : null}
      </View>
    </ImageBackground>
  );
}

const styles = StyleSheet.create({
  bg: { flex: 1 },
  sdpContent: { flex: 1 },
  body: { flexDirection: 'column' },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 16,
  },
  headerLogoWrap: { justifyContent: 'center', alignItems: 'center' },
  headerGroup: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    minWidth: 0,
    gap: 12,
  },
  headerLogoPlaceholder: {
    fontFamily: FONT_SEMI_BOLD,
    color: 'rgba(255,255,255,0.9)',
    fontSize: 11,
    fontWeight: '600',
    textAlign: 'center',
  },
  headerTitle: {
    fontFamily: FONT_BOLD,
    flex: 1,
    minWidth: 0,
    color: '#fff',
    fontSize: 26,
    fontWeight: '700',
    textAlign: 'center',
  },
  weatherPanel: {
    padding: 22,
    flexDirection: 'column',
  },
  weatherEffectWrap: {
    ...StyleSheet.absoluteFillObject,
  },
  weatherStormOverlay: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: 'rgba(0,0,0,0.38)',
  },
  weatherContentWrap: {
    flex: 1,
    minHeight: 0,
  },
  weatherHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    marginBottom: 16,
  },
  weatherLocation: {
    fontFamily: FONT_BOLD,
    color: '#fff',
    fontSize: 37,
    fontWeight: '700',
    textTransform: 'uppercase',
    letterSpacing: 0.6,
  },
  weatherDate: {
    fontFamily: FONT_REGULAR,
    color: 'rgba(255,255,255,0.9)',
    fontSize: 32,
    marginTop: 6,
  },
  weatherUpdatedWrap: { alignItems: 'flex-end',padding: 23 },
  weatherUpdatedIcon: {
    width: 16,
    height: 12,
    marginBottom: 4,
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.6)',
    borderRadius: 2,
  },
  weatherUpdated: { fontFamily: FONT_REGULAR, color: 'rgba(255,255,255,0.85)', fontSize: 22 },
  weatherUpdatedTime: { fontFamily: FONT_REGULAR, color: 'rgba(255,255,255,0.75)', fontSize: 28, marginTop: 6 },
  weatherTop: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginBottom: 4,
  },
  weatherSideBlock: { alignItems: 'center', minWidth: 48 },
  bigValue: { fontFamily: FONT_BOLD, color: '#fff', fontSize: 48, fontWeight: '700' },
  label: { fontFamily: FONT_REGULAR, color: 'rgba(255,255,255,0.85)', fontSize: 28, marginTop: 6 },
  tempBlock: { alignItems: 'center', flex: 2 },
  tempRow: { flexDirection: 'row', alignItems: 'center', gap: 8 },
  tempMain: { fontFamily: FONT_BOLD, color: '#fff', fontSize: 120, fontWeight: '700' },
  weatherIcon: { fontSize: 72 },
  tempSub: { fontFamily: FONT_REGULAR, color: 'rgba(255,255,255,0.95)', fontSize: 26, marginTop: 4 },
  hourlyStrip: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-evenly',
    width: '100%',
    minHeight: 72,
    marginTop: 12,
  },
  hourlyItemFlex: { flex: 1, alignItems: 'center', justifyContent: 'center', minWidth: 40, marginTop: 34 },
  hourlyTemp: { fontFamily: FONT_BOLD, color: '#fff', fontSize: 26, fontWeight: '700', textAlign: 'center', width: '100%' },
  hourlyIconWrap: { alignItems: 'center', justifyContent: 'center', marginVertical: 4 },
  hourlyIcon: { fontSize: 24 },
  hourlyTime: { fontFamily: FONT_SEMI_BOLD, color: 'rgba(255,255,255,0.9)', fontSize: 20, marginTop: 2, fontWeight: '600', textAlign: 'center', width: '100%' },
  mainRow: {
    flexDirection: 'row',
    gap: 16,
  },
  leftColumn: {
    flexDirection: 'column',
  },
  boxPanel: {
    padding: 16,
    flex: 1,
    minHeight: 0,
    flexDirection: 'column',
  },
  /** Cắt nội dung tràn ra ngoài ô GlassView. */
  panelClip: { overflow: 'hidden' as const },
  boxPanelTitle: {
    fontFamily: FONT_SEMI_BOLD,
    color: 'rgba(255,255,255,0.95)',
    fontSize: 18,
    fontWeight: '600',
    marginBottom: 6,
  },
  aqiPanel: {
    justifyContent: 'flex-start',
    gap: 8,
  },
  aqiHeaderRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    minHeight: 0,
    flexShrink: 0,
  },
  aqiDescWrap: { flex: 1, minWidth: 0, justifyContent: 'center' },
  aqiDesc: {
    fontFamily: FONT_REGULAR,
    color: 'rgba(255,255,255,0.95)',
    fontSize: 25,
    minWidth: 0,
  },
  aqiBigValueRow: { alignItems: 'center', justifyContent: 'center', flexShrink: 0, marginVertical: 2 },
  aqiBigValue: {
    fontFamily: FONT_BOLD,
    color: '#fff',
    fontSize: 68,
    fontWeight: '700',
  },
  aqiHeaderRight: { alignItems: 'flex-end', flexShrink: 0 },
  aqiUnit: { fontFamily: FONT_SEMI_BOLD, color: 'rgba(255,255,255,0.9)', fontSize: 24, fontWeight: '600' },
  aqiUpdatedLabel: { fontFamily: FONT_REGULAR, color: 'rgba(255,255,255,0.7)', fontSize: 24, marginTop: 2 },
  aqiUpdatedTime: { fontFamily: FONT_SEMI_BOLD, color: 'rgba(255,255,255,0.9)', fontSize: 28, fontWeight: '600', marginTop: 0 },
  aqiGaugeWrap: { marginVertical: 4, flexShrink: 0, width: '100%', alignItems: 'center' },
  aqiDetailRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    flexWrap: 'wrap',
    gap: 4,
    flexShrink: 0,
  },
  aqiDetailCol: { flex: 1, minWidth: 0, alignItems: 'center' },
  aqiDetailLabel: { fontFamily: FONT_SEMI_BOLD, color: 'rgba(255,255,255,0.9)', fontSize: 24, fontWeight: '600' },
  aqiDetailValue: { fontFamily: FONT_REGULAR, color: 'rgba(255,255,255,0.8)', fontSize: 30, marginTop: 2 },
  speedPanel: {
    alignItems: 'stretch',
    justifyContent: 'space-between',
  },
  speedPanelHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 6,
    flexShrink: 0,
  },
  speedTitleWrap: { flex: 1, minWidth: 0, justifyContent: 'center' },
  speedPanelTitle: {
    fontFamily: FONT_SEMI_BOLD,
    color: 'rgba(255,255,255,0.95)',
    fontSize: 26,
    fontWeight: '600',
  },
  updatedWrap: { alignItems: 'flex-end', flexShrink: 0 },
  speedUpdatedLabel: { fontFamily: FONT_REGULAR, color: 'rgba(255,255,255,0.75)', fontSize: 22 },
  speedUpdatedTime: { fontFamily: FONT_SEMI_BOLD, color: 'rgba(255,255,255,0.9)', fontSize: 28, fontWeight: '600', marginTop: 2 },
  speedCenterBlock: {
    flex: 1,
    minHeight: 0,
    width: '100%',
    justifyContent: 'center',
    alignItems: 'center',
  },
  speedGaugeWrap: { position: 'relative' as const },
  /** Chữ đè lên biểu đồ — chỉnh top/left/paddingTop để đưa số tới bất kỳ vị trí nào. */
  speedValueOverlay: {
    ...StyleSheet.absoluteFillObject,
    justifyContent: 'center',
    alignItems: 'center',
    paddingTop: '8%',
  },
  speedValueText: {
    fontFamily: FONT_BOLD,
    color: '#fff',
    fontWeight: '700',
    textAlign: 'center',
  },
  speedUnitOverlay: {
    fontFamily: FONT_REGULAR,
    color: 'rgba(255,255,255,0.9)',
    marginTop: 2,
    textAlign: 'center',
  },
  speedDetailRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    flexShrink: 0,
    marginTop: 8,
    paddingHorizontal: 4,
  },
  speedDetailCol: { flex: 1, minWidth: 0, alignItems: 'center' },
  speedDetailLabel: { fontFamily: FONT_SEMI_BOLD, color: 'rgba(255,255,255,0.95)', fontSize: 24, fontWeight: '600' },
  speedDetailValue: { fontFamily: FONT_REGULAR, color: 'rgba(255,255,255,0.8)', fontSize: 30, marginTop: 2 },
  posterPanel: {
    justifyContent: 'center',
    alignItems: 'center',
  },
  posterPlaceholder: {
    fontFamily: FONT_REGULAR,
    color: 'rgba(255,255,255,0.5)',
    fontSize: 14,
  },
  backgroundAudio: {
    position: 'absolute',
    width: 0,
    height: 0,
    opacity: 0,
  },
  panelSub: { fontFamily: FONT_REGULAR, color: 'rgba(255,255,255,0.8)', fontSize: 14, marginTop: 6 },
  healthPanel: {
    padding: 24,
    justifyContent: 'center',
    alignItems: 'center',
  },
  healthContent: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    paddingVertical: 20,
    paddingHorizontal: 16,
  },
  healthBlock: {
    alignItems: 'center',
    marginBottom: 28,
    width: '100%',
  },
  healthIntro: {
    fontFamily: FONT_ITALIC,
    color: 'rgba(255,255,255,0.95)',
    fontSize: 29,
    fontStyle: 'italic',
    fontWeight: '400',
    textAlign: 'center',
    marginBottom: 6,
  },
  healthRecommend: {
    fontFamily: FONT_BOLD,
    color: '#fff',
    fontSize: 42,
    fontWeight: '700',
    textAlign: 'center',
    lineHeight: 68,
  },
  loadingText: { fontFamily: FONT_REGULAR, color: 'rgba(255,255,255,0.7)', fontSize: 14, textAlign: 'center', marginTop: 12 },
});
