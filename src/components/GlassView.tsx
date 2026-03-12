/**
 * Ô glass kiểu GitHub: frosted, trong suốt, không tương tác (standee chỉ hiển thị).
 * - iOS: react-native-glass-effect-view (native liquid glass nếu iOS 26+).
 * - Android: @react-native-community/blur (BlurView) để có blur thật giống ảnh.
 * Nếu Android bị crash khi mở, chạy: cd android && ./gradlew clean && cd .. && npx react-native run-android
 */
import React from 'react';
import { Platform, StyleSheet, View, ViewStyle } from 'react-native';
import { BlurView } from '@react-native-community/blur';
import { GlassEffectView } from 'react-native-glass-effect-view';

export interface GlassViewProps {
  children: React.ReactNode;
  style?: ViewStyle;
  /** 'white' = glass sáng, 'dark' = glass tối. */
  variant?: 'white' | 'dark';
}

const BORDER = 'rgba(255, 255, 255, 0.5)';
const GLOW_BORDER = 'rgba(255, 255, 255, 0.75)';
const GLOW_SHADOW = 'rgba(255, 255, 255, 0.9)';
const OVERLAY_LIGHT = 'rgba(255, 255, 255, 0.08)';
const OVERLAY_DARK = 'rgba(0, 0, 0, 0.15)';
const FALLBACK_BG_LIGHT = 'rgba(255, 255, 255, 0.4)';
const FALLBACK_BG_DARK = 'rgba(0, 0, 0, 0.35)';

/** Bật false nếu BlurView trên Android bị crash (dùng nền trong suốt thay vì blur). */
const ANDROID_USE_BLUR = true;

export function GlassView({ children, style, variant = 'white' }: GlassViewProps) {
  if (Platform.OS === 'android') {
    if (ANDROID_USE_BLUR) {
      const blurType = variant === 'dark' ? 'dark' : 'light';
      const overlayColor = variant === 'dark' ? OVERLAY_DARK : OVERLAY_LIGHT;
      return (
        <View style={[styles.glass, styles.border, styles.glow, style]}>
          <BlurView
            style={StyleSheet.absoluteFill}
            blurType={blurType}
            blurAmount={24}
            overlayColor={overlayColor}
          />
          <View style={styles.content}>{children}</View>
        </View>
      );
    }
    const bg = variant === 'dark' ? FALLBACK_BG_DARK : FALLBACK_BG_LIGHT;
    return (
      <View style={[styles.glass, styles.border, styles.glow, { backgroundColor: bg }, style]}>
        {children}
      </View>
    );
  }
  const appearance = variant === 'dark' ? 'dark' : 'light';
  return (
    <GlassEffectView style={[styles.glass, styles.glow, style]} appearance={appearance}>
      {children}
    </GlassEffectView>
  );
}

const styles = StyleSheet.create({
  glass: {
    borderRadius: 50,
    overflow: 'hidden',
  },
  border: {
    borderWidth: StyleSheet.hairlineWidth,
    borderColor: BORDER,
  },
  glow: {
    borderWidth: 2,
    borderColor: GLOW_BORDER,
    shadowColor: GLOW_SHADOW,
    shadowOffset: { width: 0, height: 0 },
    shadowOpacity: 0.8,
    shadowRadius: 12,
    elevation: 10,
  },
  content: {
    flex: 1,
    backgroundColor: 'transparent',
  },
});
