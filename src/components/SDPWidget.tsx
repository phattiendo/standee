import React from 'react';
import { ImageBackground, StyleSheet, Text, View } from 'react-native';
import { useSdpApi } from '../controllers/useSdpApi';

/** Ảnh nền mặc định cho SDP (Tết Về) — bundle từ assets */
const SDP_DEFAULT_BG = require('../../assets/tetve.jpg');

/**
 * SDP (Special Dynamic Poster).
 * Background: tetve.jpg. Overlay: dữ liệu API (AQI, speedtest, standee).
 */
interface SDPWidgetProps {
  posterUrl?: string | null;
  backgroundAsset?: string | null;
}

function formatAqi(aqi: number | undefined): string {
  if (aqi == null) return '—';
  return String(Math.round(aqi));
}

/** Backend có thể trả download/upload (Mbps) hoặc downloadSpeed/uploadSpeed (bytes/s). */
function formatSpeed(value: number | undefined): string {
  if (value == null) return '—';
  const mbps = value > 10_000 ? value / 1_000_000 : value;
  return `${Math.round(mbps * 10) / 10} Mbps`;
}

export function SDPWidget({ posterUrl }: SDPWidgetProps) {
  const { airQuality, speedTest, standeeInfo, loading, error } = useSdpApi(true);

  return (
    <ImageBackground
      source={SDP_DEFAULT_BG}
      style={styles.container}
      resizeMode="cover"
    >
      <View style={styles.overlay}>
        {/* Góc dưới-trái: AQI */}
        <View style={styles.block}>
          <Text style={styles.label}>Chất lượng không khí</Text>
          <Text style={styles.value}>
            US AQI: {formatAqi(airQuality?.us_aqi ?? airQuality?.aqi)}
          </Text>
          {airQuality?.pm2_5 != null || airQuality?.pm10 != null ? (
            <Text style={styles.sub}>PM2.5 {airQuality?.pm2_5 ?? '--'} · PM10 {airQuality?.pm10 ?? '--'}</Text>
          ) : null}
        </View>

        {/* Góc dưới-phải: Speedtest */}
        <View style={styles.blockRight}>
          <Text style={styles.label}>Tốc độ mạng</Text>
          <Text style={styles.value}>
            ↓ {formatSpeed(speedTest?.download ?? speedTest?.downloadSpeed)}
          </Text>
          <Text style={styles.sub}>
            ↑ {formatSpeed(speedTest?.upload ?? speedTest?.uploadSpeed)}
          </Text>
        </View>

        {/* Standee info (nếu có) */}
        {standeeInfo?.name ? (
          <View style={styles.standeeBlock}>
            <Text style={styles.standeeName}>{String(standeeInfo.name)}</Text>
          </View>
        ) : null}

        {loading ? (
          <Text style={styles.loading}>Đang tải dữ liệu API...</Text>
        ) : error ? (
          <Text style={styles.errorHint}>API: {error.slice(0, 40)}…</Text>
        ) : !airQuality && !speedTest && !standeeInfo?.name ? (
          <Text style={styles.loading}>Chưa kết nối API (AQI, speedtest, standee)</Text>
        ) : null}
      </View>
    </ImageBackground>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    width: '100%',
    height: '100%',
  },
  overlay: {
    ...StyleSheet.absoluteFillObject,
    padding: 24,
    justifyContent: 'flex-end',
  },
  block: {
    position: 'absolute',
    bottom: 24,
    left: 24,
    backgroundColor: 'rgba(0,0,0,0.5)',
    paddingHorizontal: 12,
    paddingVertical: 8,
    borderRadius: 8,
    maxWidth: '45%',
  },
  blockRight: {
    position: 'absolute',
    bottom: 24,
    right: 24,
    backgroundColor: 'rgba(0,0,0,0.5)',
    paddingHorizontal: 12,
    paddingVertical: 8,
    borderRadius: 8,
    maxWidth: '45%',
  },
  label: {
    color: 'rgba(255,255,255,0.8)',
    fontSize: 11,
    marginBottom: 2,
  },
  value: {
    color: '#fff',
    fontSize: 16,
    fontWeight: '600',
  },
  sub: {
    color: 'rgba(255,255,255,0.7)',
    fontSize: 12,
    marginTop: 2,
  },
  standeeBlock: {
    position: 'absolute',
    top: 24,
    alignSelf: 'center',
    backgroundColor: 'rgba(0,0,0,0.4)',
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 6,
  },
  standeeName: {
    color: '#fff',
    fontSize: 14,
  },
  loading: {
    position: 'absolute',
    bottom: 80,
    alignSelf: 'center',
    color: 'rgba(255,255,255,0.7)',
    fontSize: 12,
  },
  errorHint: {
    position: 'absolute',
    bottom: 80,
    alignSelf: 'center',
    color: 'rgba(255,200,200,0.9)',
    fontSize: 10,
  },
});
