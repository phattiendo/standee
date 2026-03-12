/**
 * Standee Player — slideshow full màn hình: SDP ↔ Poster ↔ Video (lật album).
 * Một slide = cả màn hình (SDP | ảnh poster | video).
 */
import React, { useCallback, useEffect, useRef, useState } from 'react';
import { ActivityIndicator, StyleSheet, Text, View } from 'react-native';
import FastImage from 'react-native-fast-image';
import { FullScreenVideoView } from '../components/FullScreenVideoView';
import { PosterView } from '../components/PosterView';
import { useStandeePlaylist } from '../controllers/useStandeePlaylist';
import { SDPScreen } from './SDPScreen';
import type { SlideItem } from '../data/types/playlist';
import { getPlaybackUrl } from '../data/models/MediaItem';
import { fullPath } from '../core/storage/romMediaStorage';

const DEFAULT_DURATION_MS = 15 * 1000;

function resolveUrl(item: SlideItem): string {
  return getPlaybackUrl(item, (rel) => fullPath(rel) ?? null);
}

export function StandeePlayerScreen() {
  const { playlist, loading, error } = useStandeePlaylist(true);
  const [currentIndex, setCurrentIndex] = useState(0);
  const timerRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  const total = playlist.length;
  const current = total > 0 ? playlist[currentIndex % total] : null;
  const next = total > 1 ? playlist[(currentIndex + 1) % total] : null;

  const goNext = useCallback(() => {
    if (total <= 0) return;
    setCurrentIndex((i) => (i + 1) % total);
  }, [total]);

  // Preload next slide (image)
  useEffect(() => {
    if (!next || next.type !== 'image') return;
    const url = resolveUrl(next)?.trim();
    if (url && (url.startsWith('http://') || url.startsWith('https://'))) {
      FastImage.preload([{ uri: url }]);
    }
  }, [currentIndex, next]);

  // Timer: với SDP và poster (image) dùng duration; với video không set timer (chờ onVideoEnded)
  useEffect(() => {
    if (total <= 0 || !current) return;
    if (current.type === 'video') {
      if (timerRef.current) {
        clearTimeout(timerRef.current);
        timerRef.current = null;
      }
      return;
    }
    const durationMs = (current.durationSeconds ?? 95) * 1000 || DEFAULT_DURATION_MS;
    timerRef.current = setTimeout(goNext, durationMs);
    return () => {
      if (timerRef.current) clearTimeout(timerRef.current);
    };
  }, [currentIndex, current, total, goNext]);

  if (loading && playlist.length === 0) {
    return (
      <View style={styles.centered}>
        <ActivityIndicator size="large" color="#fff" />
        <Text style={styles.loadingText}>Đang tải playlist...</Text>
      </View>
    );
  }

  if (total === 0) {
    return <SDPScreen />;
  }

  if (current!.type === 'sdp') {
    return <SDPScreen />;
  }

  if (current!.type === 'video') {
    return (
      <FullScreenVideoView
        url={resolveUrl(current!)}
        onVideoEnded={goNext}
      />
    );
  }

  return (
    <PosterView url={resolveUrl(current!)} />
  );
}

const styles = StyleSheet.create({
  centered: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#111',
  },
  loadingText: {
    color: 'rgba(255,255,255,0.8)',
    marginTop: 12,
    fontSize: 14,
  },
  errorText: {
    color: '#f88',
    fontSize: 14,
    textAlign: 'center',
    paddingHorizontal: 24,
  },
});
