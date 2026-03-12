/**
 * Gauge tốc độ mạng: cung nửa vòng (180°), track trắng/xám, phần fill theo value.
 * Chỉ cần truyền value (số) — biểu đồ và text dưới cùng dùng chung value nên luôn khớp.
 */
import React from 'react';
import { StyleSheet, Text, View } from 'react-native';
import Svg, { Path, Defs, LinearGradient, Stop } from 'react-native-svg';
import { FONT_BOLD } from '../core/theme/typography';

const SIZE = 120;
const STROKE = 10;
const R = (SIZE - STROKE) / 2;
const CX = SIZE / 2;
const CY = SIZE / 2;

/** Format value hiển thị dưới gauge — cùng số với gauge, 1 số lẻ (vd. 92.3 Mbps). */
function formatValue(value: number, unit = 'Mbps'): string {
  const n = Number.isFinite(value) ? value : 0;
  const rounded = Math.round(n * 10) / 10;
  return `${rounded} ${unit}`;
}

/** SVG: 0° = 3h, 90° = 6h, 180° = 9h, 270° = 12h. Cung nửa dưới từ 180° đến 360°. */
function describeArc(cx: number, cy: number, r: number, startDeg: number, endDeg: number) {
  const start = (startDeg * Math.PI) / 180;
  const end = (endDeg * Math.PI) / 180;
  const x1 = cx + r * Math.cos(start);
  const y1 = cy + r * Math.sin(start);
  const x2 = cx + r * Math.cos(end);
  const y2 = cy + r * Math.sin(end);
  const largeArc = Math.abs(endDeg - startDeg) > 180 ? 1 : 0;
  return `M ${x1} ${y1} A ${r} ${r} 0 ${largeArc} 1 ${x2} ${y2}`;
}

export interface SpeedGaugeProps {
  /** Giá trị tốc độ (Mbps) — dùng cho cả biểu đồ và text dưới. */
  value: number;
  /** Thang tối đa (Mbps). Mặc định 200. */
  max?: number;
  size?: number;
  /** Có hiển thị text value dưới biểu đồ không. Mặc định true. */
  showValueLabel?: boolean;
  /** Đơn vị hiển thị (mặc định "Mbps"). */
  unit?: string;
}

export function SpeedGauge({
  value,
  max = 200,
  size = SIZE,
  showValueLabel = true,
  unit = 'Mbps',
}: SpeedGaugeProps) {
  const clamped = Math.max(0, Math.min(max, value));
  const pct = max > 0 ? clamped / max : 0;
  const angleDeg = 180 * pct;
  const endAngle = 180 + angleDeg;

  const pathTrack = describeArc(CX, CY, R, 180, 360);
  const pathFill = angleDeg > 0 ? describeArc(CX, CY, R, 180, endAngle) : '';

  const labelText = formatValue(value, unit);
  const labelZone = showValueLabel ? getLabelZone(size) : 0;
  const valueFontSize = Math.min(48, Math.max(14, Math.round(size * 0.38)));
  const containerHeight = size + labelZone;

  return (
    <View style={styles.wrapper}>
      <View style={[styles.gaugeContainer, { width: size, height: containerHeight }]}>
        <View style={[styles.svgWrap, { width: size, height: size }]}>
          <Svg width={size} height={size} viewBox={`0 0 ${SIZE} ${SIZE}`}>
            <Defs>
              <LinearGradient id="speedGaugeFill" x1="0" y1="0" x2="1" y2="0">
                <Stop offset="0" stopColor="#38bdf8" />
                <Stop offset="1" stopColor="#0ea5e9" />
              </LinearGradient>
            </Defs>
            <Path
              d={pathTrack}
              stroke="rgba(255,255,255,0.4)"
              strokeWidth={STROKE}
              fill="none"
              strokeLinecap="round"
            />
            {pathFill ? (
              <Path
                d={pathFill}
                stroke="url(#speedGaugeFill)"
                strokeWidth={STROKE}
                fill="none"
                strokeLinecap="round"
              />
            ) : null}
          </Svg>
        </View>
        {showValueLabel ? (
          <View style={[styles.labelWrap, { top: size, height: labelZone }]}>
            <Text style={[styles.valueLabel, { fontSize: valueFontSize }]} numberOfLines={1}>
              {labelText}
            </Text>
          </View>
        ) : null}
      </View>
    </View>
  );
}

/** Chiều cao vùng chữ dưới gauge — scale theo size để luôn nằm trong ô. */
function getLabelZone(size: number): number {
  return Math.min(58, Math.max(28, Math.round(size * 0.45)));
}

const styles = StyleSheet.create({
  wrapper: {
    alignItems: 'center',
    justifyContent: 'center',
  },
  gaugeContainer: {
    position: 'relative',
  },
  svgWrap: {
    position: 'absolute',
    top: 0,
    left: 0,
  },
  labelWrap: {
    position: 'absolute',
    left: 0,
    right: 0,
    justifyContent: 'center',
    alignItems: 'center',
  },
  valueLabel: {
    fontWeight: '700',
    fontFamily: FONT_BOLD,
    color: '#fff',
    textAlign: 'center',
  },
});
