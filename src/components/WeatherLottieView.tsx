/**
 * Hiệu ứng thời tiết bằng SVG: mưa rơi, mây bay, hoa rơi.
 * Vùng hiển thị = hết weatherContentWrap (full GlassView). Mây: bay từ trái tới cuối GlassView. Mưa/hoa: phủ hết GlassView.
 */
import React, { useEffect, useMemo, useRef } from 'react';
import { Animated, Easing, StyleSheet, View } from 'react-native';
import Svg, { Circle, Ellipse, Line, Path } from 'react-native-svg';
import { apiConstants } from '../core/constants/apiConstants';

const DEFAULT_AREA_HEIGHT = 100;
const DEFAULT_AREA_WIDTH = 400;

/** WMO weather code → loại hiệu ứng. 95+ = bão (mưa to + sét). */
export function getWeatherEffect(code: number | undefined): 'rain' | 'storm' | 'cloudy' | 'flowers' {
  const c = code ?? 0;
  if (c >= 95) return 'storm';
  if (c >= 61) return 'rain';
  if (c >= 1) return 'cloudy';
  return 'flowers';
}

// --- Mưa nhẹ liên tục (drizzle): thưa hơn bão nhưng đủ thấy ---
const RAIN_COUNT = 32;
const RAIN_BASE_DURATION = 1400;
const RAIN_PHASE_STAGGER_MS = 42;

/** Tạo config từng hạt: thưa, mảnh, opacity thấp, rơi chậm. */
function buildRainDrops(areaWidth: number) {
  const drops: { x: number; length: number; opacity: number; duration: number; slant: number }[] = [];
  for (let i = 0; i < RAIN_COUNT; i++) {
    const t = i / (RAIN_COUNT - 1 || 1);
    const jitter = ((i * 17 + 13) % 31) / 31 - 0.5;
    drops.push({
      x: t * (areaWidth - 24) + 12 + jitter * 20,
      length: 12 + (i % 4) * 3,
      opacity: 0.28 + (i % 6) / 12,
      duration: RAIN_BASE_DURATION + (i % 4) * 200,
      slant: 3 + (i % 2) * 2,
    });
  }
  return drops;
}

function RainEffect({ areaWidth, areaHeight }: { areaWidth: number; areaHeight: number }) {
  const anims = useRef(
    Array.from({ length: RAIN_COUNT }, () => new Animated.Value(0))
  ).current;

  const drops = useMemo(() => buildRainDrops(areaWidth), [areaWidth]);
  const maxLen = useMemo(() => Math.max(...drops.map((d) => d.length)), [drops]);

  useEffect(() => {
    let cancelled = false;
    const loops = anims.map((anim, i) =>
      Animated.loop(
        Animated.sequence([
          Animated.timing(anim, {
            toValue: 1,
            duration: drops[i].duration,
            easing: Easing.linear,
            useNativeDriver: true,
          }),
          Animated.timing(anim, { toValue: 0, duration: 0, useNativeDriver: true }),
        ])
      )
    );
    loops.forEach((loop, i) => {
      Animated.delay(i * RAIN_PHASE_STAGGER_MS).start(() => {
        if (!cancelled) loop.start();
      });
    });
    return () => {
      cancelled = true;
      loops.forEach((l) => l.stop());
    };
  }, [anims, drops]);

  return (
    <>
      {anims.map((anim, i) => {
        const d = drops[i];
        const y = anim.interpolate({
          inputRange: [0, 1],
          outputRange: [-maxLen, areaHeight + maxLen],
        });
        const slant = d.slant;
        const len = d.length;
        return (
          <Animated.View
            key={i}
            style={[
              styles.particle,
              { left: d.x, transform: [{ translateY: y }] },
            ]}
            pointerEvents="none"
          >
            <Svg width={slant + 6} height={len + 2}>
              <Line
                x1={2}
                y1={0}
                x2={2 + slant}
                y2={len}
                stroke={`rgba(255,255,255,${d.opacity})`}
                strokeWidth={1}
                strokeLinecap="round"
              />
            </Svg>
          </Animated.View>
        );
      })}
    </>
  );
}

// --- Bão: mưa rơi từ đầu tới cuối liên tục, không ngắt — phase trải đều 1 chu kỳ ---
const STORM_RAIN_COUNT = 110;
const STORM_RAIN_BASE_DURATION = 500;
const STORM_AVG_DURATION_MS = 716;
const STORM_PHASE_STAGGER_MS = Math.max(5, Math.floor(STORM_AVG_DURATION_MS / STORM_RAIN_COUNT));

function buildStormRainDrops(areaWidth: number) {
  const drops: { x: number; length: number; opacity: number; duration: number; slant: number }[] = [];
  for (let i = 0; i < STORM_RAIN_COUNT; i++) {
    const t = i / (STORM_RAIN_COUNT - 1 || 1);
    const jitter = ((i * 13 + 11) % 29) / 29 - 0.5;
    drops.push({
      x: t * (areaWidth - 12) + 6 + jitter * 8,
      length: 20 + (i % 4) * 3,
      opacity: 0.65 + (i % 6) / 10,
      duration: STORM_RAIN_BASE_DURATION + (i % 11) * 42,
      slant: 6 + (i % 3) * 2,
    });
  }
  return drops;
}

function StormEffect({ areaWidth, areaHeight }: { areaWidth: number; areaHeight: number }) {
  const anims = useRef(
    Array.from({ length: STORM_RAIN_COUNT }, () => new Animated.Value(0))
  ).current;
  const flash = useRef(new Animated.Value(0)).current;

  const drops = useMemo(() => buildStormRainDrops(areaWidth), [areaWidth]);
  const maxLen = useMemo(() => Math.max(...drops.map((d) => d.length)), [drops]);

  useEffect(() => {
    let cancelled = false;
    const loops = anims.map((anim, i) =>
      Animated.loop(
        Animated.sequence([
          Animated.timing(anim, {
            toValue: 1,
            duration: drops[i].duration,
            easing: Easing.linear,
            useNativeDriver: true,
          }),
          Animated.timing(anim, { toValue: 0, duration: 0, useNativeDriver: true }),
        ])
      )
    );
    loops.forEach((loop, i) => {
      Animated.delay(i * STORM_PHASE_STAGGER_MS).start(() => {
        if (!cancelled) loop.start();
      });
    });
    return () => {
      cancelled = true;
      loops.forEach((l) => l.stop());
    };
  }, [anims, drops]);

  useEffect(() => {
    const flashLoop = Animated.loop(
      Animated.sequence([
        Animated.delay(2600 + (Math.random() * 1800) | 0),
        Animated.timing(flash, {
          toValue: 1,
          duration: 50,
          useNativeDriver: true,
        }),
        Animated.timing(flash, {
          toValue: 0,
          duration: 160,
          easing: Easing.out(Easing.ease),
          useNativeDriver: true,
        }),
      ])
    );
    flashLoop.start();
    return () => flashLoop.stop();
  }, [flash]);

  const h = areaHeight;
  const w = 22;
  const lightningPath = `M ${w/2} 0 L ${w*0.2} ${h*0.28} L ${w*0.65} ${h*0.28} L ${w*0.15} ${h*0.55} L ${w*0.7} ${h*0.55} L ${w*0.25} ${h*0.82} L ${w*0.6} ${h*0.82} L ${w/2} ${h}`;
  const boltPositions = [areaWidth * 0.28, areaWidth * 0.72];

  return (
    <>
      {anims.map((anim, i) => {
        const d = drops[i];
        const y = anim.interpolate({
          inputRange: [0, 1],
          outputRange: [-maxLen, areaHeight + maxLen],
        });
        const len = d.length;
        return (
          <Animated.View
            key={i}
            style={[styles.particle, { left: d.x, transform: [{ translateY: y }] }]}
            pointerEvents="none"
          >
            <Svg width={d.slant + 8} height={len + 2}>
              <Line
                x1={2}
                y1={0}
                x2={2 + d.slant}
                y2={len}
                stroke={`rgba(255,255,255,${d.opacity})`}
                strokeWidth={2.2}
                strokeLinecap="round"
              />
            </Svg>
          </Animated.View>
        );
      })}
      {boltPositions.map((left, i) => (
        <Animated.View
          key={`bolt-${i}`}
          style={[styles.particle, { left: left - w/2, top: 0, opacity: flash }]}
          pointerEvents="none"
        >
          <Svg width={w} height={h}>
            <Path
              d={lightningPath}
              fill="none"
              stroke="rgba(255,255,255,0.95)"
              strokeWidth={2.2}
              strokeLinecap="round"
              strokeLinejoin="round"
            />
          </Svg>
        </Animated.View>
      ))}
    </>
  );
}

// --- Mây: bay từ trái tới cuối GlassView, phủ hết khung, hình dạng cumulus (nhiều vòng tròn chồng) ---
const CLOUD_COUNT = 9;
const CLOUD_DURATION = 5500;
const CLOUD_WIDTH = 140;
const CLOUD_HEIGHT = 52;
/** Một đám mây = nhiều Circle chồng nhau (dạng cumulus). [cx, cy, r] trong khung CLOUD_WIDTH x CLOUD_HEIGHT. */
const CLOUD_SHAPE: Array<[number, number, number]> = [
  [35, 28, 22],
  [70, 32, 26],
  [52, 18, 20],
  [22, 38, 18],
  [88, 24, 16],
];

function CloudEffect({ areaWidth, areaHeight }: { areaWidth: number; areaHeight: number }) {
  const anims = useRef(
    Array.from({ length: CLOUD_COUNT }, () => new Animated.Value(0))
  ).current;

  useEffect(() => {
    const loops = anims.map((anim, i) =>
      Animated.loop(
        Animated.sequence([
          Animated.delay((i * CLOUD_DURATION) / CLOUD_COUNT),
          Animated.timing(anim, {
            toValue: 1,
            duration: CLOUD_DURATION,
            easing: Easing.inOut(Easing.ease),
            useNativeDriver: true,
          }),
          Animated.timing(anim, { toValue: 0, duration: 0, useNativeDriver: true }),
        ])
      )
    );
    Animated.parallel(loops).start();
    return () => loops.forEach((l) => l.stop());
  }, [anims]);

  const clouds = useMemo(() => {
    const list: { top: number }[] = [];
    const step = Math.max(8, (areaHeight - CLOUD_HEIGHT) / (CLOUD_COUNT - 1 || 1));
    for (let i = 0; i < CLOUD_COUNT; i++) list.push({ top: i * step });
    return list;
  }, [areaHeight]);

  const startX = -CLOUD_WIDTH;
  const endX = areaWidth;

  return (
    <>
      {anims.map((anim, i) => {
        const x = anim.interpolate({
          inputRange: [0, 1],
          outputRange: [startX, endX],
        });
        const { top: cloudTop } = clouds[i];
        return (
          <Animated.View
            key={i}
            style={[
              styles.particle,
              { left: 0, top: cloudTop, transform: [{ translateX: x }] },
            ]}
            pointerEvents="none"
          >
            <Svg width={CLOUD_WIDTH} height={CLOUD_HEIGHT}>
              {CLOUD_SHAPE.map(([cx, cy, r], j) => (
                <Circle key={j} cx={cx} cy={cy} r={r} fill="rgba(255,255,255,0.5)" />
              ))}
            </Svg>
          </Animated.View>
        );
      })}
    </>
  );
}

// --- Hoa + lá rơi: hoa (tròn), lá (ellipse), rơi liên tục, xoay nhẹ ---
const PETAL_COUNT = 36;
const PETAL_BASE_DURATION = 3800;
const PETAL_PHASE_STAGGER_MS = 95;

const FLOWER_COLORS = [
  'rgba(255,182,193,0.92)',
  'rgba(255,218,185,0.92)',
  'rgba(255,255,224,0.9)',
  'rgba(255,192,203,0.88)',
  'rgba(255,228,196,0.92)',
];
const LEAF_COLORS = [
  'rgba(154,205,50,0.85)',
  'rgba(210,180,140,0.82)',
  'rgba(218,165,32,0.85)',
  'rgba(184,134,11,0.8)',
  'rgba(144,238,144,0.82)',
];

type PetalType = 'flower' | 'leaf';

function buildPetals(areaWidth: number) {
  const items: { type: PetalType; x: number; r: number; rx?: number; ry?: number; color: string; duration: number }[] = [];
  for (let i = 0; i < PETAL_COUNT; i++) {
    const t = i / (PETAL_COUNT - 1 || 1);
    const jitter = ((i * 19 + 7) % 23) / 23 - 0.5;
    const isLeaf = i % 3 === 1;
    if (isLeaf) {
      items.push({
        type: 'leaf',
        x: t * (areaWidth - 40) + 20 + jitter * 24,
        r: 0,
        rx: 4 + (i % 3),
        ry: 14 + (i % 4) * 2,
        color: LEAF_COLORS[i % LEAF_COLORS.length],
        duration: PETAL_BASE_DURATION + (i % 7) * 320,
      });
    } else {
      items.push({
        type: 'flower',
        x: t * (areaWidth - 48) + 24 + jitter * 20,
        r: 8 + (i % 4),
        color: FLOWER_COLORS[i % FLOWER_COLORS.length],
        duration: PETAL_BASE_DURATION + (i % 5) * 280,
      });
    }
  }
  return items;
}

function FlowersEffect({ areaWidth, areaHeight }: { areaWidth: number; areaHeight: number }) {
  const animsY = useRef(
    Array.from({ length: PETAL_COUNT }, () => new Animated.Value(0))
  ).current;
  const animsX = useRef(
    Array.from({ length: PETAL_COUNT }, () => new Animated.Value(0))
  ).current;
  const animsRotate = useRef(
    Array.from({ length: PETAL_COUNT }, () => new Animated.Value(0))
  ).current;

  const petals = useMemo(() => buildPetals(areaWidth), [areaWidth]);

  useEffect(() => {
    let cancelled = false;
    const run = (anim: Animated.Value, toValue: number, duration: number, easing: typeof Easing.linear) =>
      Animated.timing(anim, { toValue, duration, easing, useNativeDriver: true });

    const loops = petals.flatMap((_, i) => [
      Animated.loop(Animated.sequence([
        run(animsY[i], 1, petals[i].duration, Easing.linear),
        Animated.timing(animsY[i], { toValue: 0, duration: 0, useNativeDriver: true }),
      ])),
      Animated.loop(Animated.sequence([
        run(animsX[i], 1, petals[i].duration, Easing.inOut(Easing.ease)),
        Animated.timing(animsX[i], { toValue: 0, duration: 0, useNativeDriver: true }),
      ])),
      Animated.loop(Animated.sequence([
        run(animsRotate[i], 1, petals[i].duration, Easing.linear),
        Animated.timing(animsRotate[i], { toValue: 0, duration: 0, useNativeDriver: true }),
      ])),
    ]);
    petals.forEach((_, i) => {
      Animated.delay(i * PETAL_PHASE_STAGGER_MS).start(() => {
        if (!cancelled) {
          loops[i * 3].start();
          loops[i * 3 + 1].start();
          loops[i * 3 + 2].start();
        }
      });
    });
    return () => {
      cancelled = true;
      loops.forEach((l) => l.stop());
    };
  }, [petals, animsY, animsX, animsRotate]);

  return (
    <>
      {petals.map((p, i) => {
        const translateY = animsY[i].interpolate({
          inputRange: [0, 1],
          outputRange: [-50, areaHeight + 50],
        });
        const translateX = animsX[i].interpolate({
          inputRange: [0, 1],
          outputRange: [0, 28],
        });
        const rotate = animsRotate[i].interpolate({
          inputRange: [0, 1],
          outputRange: ['0deg', '360deg'],
        });
        if (p.type === 'leaf' && p.rx != null && p.ry != null) {
          const w = (p.rx ?? 6) * 2 + 4;
          const h = (p.ry ?? 18) * 2 + 4;
          return (
            <Animated.View
              key={i}
              style={[
                styles.particle,
                {
                  left: p.x,
                  transform: [{ translateX }, { translateY }, { rotate }],
                },
              ]}
              pointerEvents="none"
            >
              <Svg width={w} height={h}>
                <Ellipse cx={w / 2} cy={h / 2} rx={p.rx} ry={p.ry} fill={p.color} />
              </Svg>
            </Animated.View>
          );
        }
        const size = (p.r || 10) * 2 + 8;
        return (
          <Animated.View
            key={i}
            style={[
              styles.particle,
              {
                left: p.x,
                transform: [{ translateX }, { translateY }, { rotate }],
              },
            ]}
            pointerEvents="none"
          >
            <Svg width={size} height={size}>
              <Circle cx={size / 2} cy={size / 2} r={p.r} fill={p.color} />
            </Svg>
          </Animated.View>
        );
      })}
    </>
  );
}

export interface WeatherLottieViewProps {
  weatherCode?: number;
  style?: object;
  /** Kích thước vùng hiệu ứng (full GlassView khi dùng trong ô thời tiết). */
  width?: number;
  height?: number;
}

export function WeatherLottieView({ weatherCode, style, width, height }: WeatherLottieViewProps) {
  const override = apiConstants.weatherEffectOverride;
  const effect = override ?? getWeatherEffect(weatherCode);
  const areaWidth = width ?? DEFAULT_AREA_WIDTH;
  const areaHeight = height ?? DEFAULT_AREA_HEIGHT;

  return (
    <View style={[styles.wrapper, style, { width: areaWidth, height: areaHeight }]} pointerEvents="none">
      <View style={[styles.area, { width: areaWidth, height: areaHeight }]}>
        {effect === 'rain' && <RainEffect areaWidth={areaWidth} areaHeight={areaHeight} />}
        {effect === 'storm' && <StormEffect areaWidth={areaWidth} areaHeight={areaHeight} />}
        {effect === 'cloudy' && <CloudEffect areaWidth={areaWidth} areaHeight={areaHeight} />}
        {effect === 'flowers' && <FlowersEffect areaWidth={areaWidth} areaHeight={areaHeight} />}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  wrapper: {
    overflow: 'hidden',
  },
  area: {
    position: 'relative',
  },
  particle: {
    position: 'absolute',
    top: 0,
  },
});
