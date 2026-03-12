/**
 * Icon AQI có animation: không khí tốt = mặt cười, không khí xấu = mặt buồn đeo khẩu trang.
 * Dùng SVG + Animated (pulse nhẹ) giống hiệu ứng weather.
 */
import React, { useEffect, useRef } from 'react';
import { Animated, Easing, StyleSheet, View } from 'react-native';
import Svg, { Circle, Path } from 'react-native-svg';

const SIZE = 36;
const CX = SIZE / 2;
const CY = SIZE / 2;
const FACE_R = 14;
const EYE_R = 2.5;
const EYE_OFFSET_Y = -3;
const EYE_OFFSET_X = 5;

/** Màu: mặt cười (tốt) — cam vàng ấm. */
const GOOD_FACE_FILL = '#fef3c7';
const GOOD_FACE_STROKE = '#f59e0b';
const GOOD_EYE = '#b45309';
const GOOD_SMILE = '#d97706';

/** Mặt buồn + khẩu trang — mặt cam, khẩu trang xanh. */
const BAD_FACE_STROKE = '#ea580c';
const BAD_FACE_FILL = '#ffedd5';
const BAD_EYE = '#c2410c';
const BAD_MOUTH = '#9a3412';
const MASK_FILL = '#a7f3d0';
const MASK_STROKE = '#059669';
const MASK_STRAP = '#047857';

/** US AQI: 0–50 good, 51+ xấu dần. Trả về true nếu "tốt" (mặt cười). */
export function isAqiGood(aqi: number | undefined): boolean {
  if (aqi == null) return true;
  return Math.round(aqi) <= 50;
}

export interface AqiIconViewProps {
  /** Giá trị AQI (us_aqi, aqi, pm2_5). Dùng để chọn mặt cười vs mặt buồn khẩu trang. */
  aqi?: number;
  /** Kích thước icon (mặc định 36). */
  size?: number;
}

/** Mặt cười: vòng tròn + 2 mắt + miệng cười (arc). Màu cam vàng ấm. */
function SmileyFace({ size }: { size: number }) {
  const r = FACE_R;
  const cx = CX;
  const cy = CY;
  const smilePath = `M ${cx - r * 0.65} ${cy + r * 0.2} Q ${cx} ${cy + r * 0.85} ${cx + r * 0.65} ${cy + r * 0.2}`;
  return (
    <Svg width={size} height={size} viewBox={`0 0 ${SIZE} ${SIZE}`}>
      <Circle cx={cx} cy={cy} r={r} fill={GOOD_FACE_FILL} stroke={GOOD_FACE_STROKE} strokeWidth={2} />
      <Circle cx={cx - EYE_OFFSET_X} cy={cy + EYE_OFFSET_Y} r={EYE_R} fill={GOOD_EYE} />
      <Circle cx={cx + EYE_OFFSET_X} cy={cy + EYE_OFFSET_Y} r={EYE_R} fill={GOOD_EYE} />
      <Path d={smilePath} fill="none" stroke={GOOD_SMILE} strokeWidth={2} strokeLinecap="round" />
    </Svg>
  );
}

/** Mặt buồn đeo khẩu trang: mặt cam, khẩu trang xanh (fill + viền + dây). */
function SadMaskFace({ size }: { size: number }) {
  const r = FACE_R;
  const cx = CX;
  const cy = CY;
  const mouthPath = `M ${cx - r * 0.5} ${cy + r * 0.5} Q ${cx} ${cy + r * 0.25} ${cx + r * 0.5} ${cy + r * 0.5}`;
  const maskW = r * 1.4;
  const maskH = r * 0.55;
  const maskX = cx - maskW / 2;
  const maskY = cy + r * 0.15;
  const strapY = cy + r * 0.5;
  return (
    <Svg width={size} height={size} viewBox={`0 0 ${SIZE} ${SIZE}`}>
      <Circle cx={cx} cy={cy} r={r} fill={BAD_FACE_FILL} stroke={BAD_FACE_STROKE} strokeWidth={2} />
      <Circle cx={cx - EYE_OFFSET_X} cy={cy + EYE_OFFSET_Y} r={EYE_R} fill={BAD_EYE} />
      <Circle cx={cx + EYE_OFFSET_X} cy={cy + EYE_OFFSET_Y} r={EYE_R} fill={BAD_EYE} />
      <Path d={mouthPath} fill="none" stroke={BAD_MOUTH} strokeWidth={1.8} strokeLinecap="round" />
      <Path
        d={`M ${maskX} ${maskY} h ${maskW} v ${maskH} h -${maskW} Z`}
        fill={MASK_FILL}
        stroke={MASK_STROKE}
        strokeWidth={1.5}
      />
      <Path
        d={`M ${maskX} ${maskY + maskH} L ${maskX} ${strapY} M ${maskX + maskW} ${maskY + maskH} L ${maskX + maskW} ${strapY}`}
        fill="none"
        stroke={MASK_STRAP}
        strokeWidth={2}
        strokeLinecap="round"
      />
    </Svg>
  );
}

export function AqiIconView({ aqi, size = SIZE }: AqiIconViewProps) {
  const scale = useRef(new Animated.Value(1)).current;
  const good = isAqiGood(aqi);

  useEffect(() => {
    const loop = Animated.loop(
      Animated.sequence([
        Animated.timing(scale, {
          toValue: 1.08,
          duration: 1200,
          easing: Easing.inOut(Easing.ease),
          useNativeDriver: true,
        }),
        Animated.timing(scale, {
          toValue: 1,
          duration: 1200,
          easing: Easing.inOut(Easing.ease),
          useNativeDriver: true,
        }),
      ])
    );
    loop.start();
    return () => loop.stop();
  }, [scale]);

  return (
    <Animated.View style={[styles.wrap, { width: size, height: size, transform: [{ scale }] }]}>
      {good ? <SmileyFace size={size} /> : <SadMaskFace size={size} />}
    </Animated.View>
  );
}

const styles = StyleSheet.create({
  wrap: { alignItems: 'center', justifyContent: 'center' },
});
