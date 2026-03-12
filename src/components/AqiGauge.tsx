/**
 * Gauge chất lượng không khí: thanh ngang gradient (xanh → vàng → cam → đỏ) + kim tam giác.
 * Scale US AQI 0–200 (có thể chỉnh max).
 */
import React from 'react';
import { View } from 'react-native';
import Svg, { Defs, LinearGradient, Stop, Rect, Polygon } from 'react-native-svg';

const BAR_HEIGHT = 12;
const POINTER_SIZE = 10;
const AQI_MAX = 200;

export interface AqiGaugeProps {
  value: number;
  width: number;
  /** 0 = good, 200 = unhealthy. Mặc định 200. */
  max?: number;
}

export function AqiGauge({ value, width, max = AQI_MAX }: AqiGaugeProps) {
  const clamped = Math.max(0, Math.min(max, value));
  const pct = max > 0 ? clamped / max : 0;
  const x = pct * width;
  const pointerX = Math.max(POINTER_SIZE, Math.min(width - POINTER_SIZE, x));

  return (
    <View style={{ width, height: BAR_HEIGHT + POINTER_SIZE + 4 }}>
      <Svg width={width} height={BAR_HEIGHT + POINTER_SIZE + 4}>
        <Defs>
          <LinearGradient id="aqiGradient" x1="0" y1="0" x2="1" y2="0">
            <Stop offset="0" stopColor="#22c55e" />
            <Stop offset="0.35" stopColor="#eab308" />
            <Stop offset="0.6" stopColor="#f97316" />
            <Stop offset="1" stopColor="#ef4444" />
          </LinearGradient>
        </Defs>
        {/* Thanh nền gradient */}
        <Rect
          x={0}
          y={POINTER_SIZE + 2}
          width={width}
          height={BAR_HEIGHT}
          rx={BAR_HEIGHT / 2}
          ry={BAR_HEIGHT / 2}
          fill="url(#aqiGradient)"
        />
        {/* Kim tam giác trỏ xuống (đỉnh dưới, đáy trên) */}
        <Polygon
          points={`${pointerX},${POINTER_SIZE + 2} ${pointerX - POINTER_SIZE},2 ${pointerX + POINTER_SIZE},2`}
          fill="#fff"
        />
      </Svg>
    </View>
  );
}
