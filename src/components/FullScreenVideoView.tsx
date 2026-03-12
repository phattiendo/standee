import React from 'react';
import { StyleSheet, View } from 'react-native';
import Video from 'react-native-video';
import { ASSET_VIDEO_CATOON_URL } from '../data/types/playlist';

function toFileUri(path: string): string {
  if (!path) return path;
  if (path.startsWith('file://')) return path;
  if (path.startsWith('http://') || path.startsWith('https://')) return path;
  return `file://${path}`;
}

interface FullScreenVideoViewProps {
  url: string;
  onVideoEnded?: () => void;
}

/** Full-screen video — một player, khi hết hoặc lỗi gọi onVideoEnded để chuyển slide. Hỗ trợ asset local (catoon.mp4). */
export function FullScreenVideoView({ url, onVideoEnded }: FullScreenVideoViewProps) {
  const trimmed = (url && String(url).trim()) || '';
  const isAssetVideo = trimmed === ASSET_VIDEO_CATOON_URL;
  const source: number | { uri: string } | null = isAssetVideo
    ? require('../../assets/catoon.mp4')
    : trimmed
      ? { uri: toFileUri(trimmed) }
      : null;

  if (source == null) {
    return <View style={StyleSheet.absoluteFill} />;
  }

  return (
    <View style={styles.container}>
      <Video
        source={source}
        style={StyleSheet.absoluteFill}
        resizeMode="cover"
        repeat={false}
        onEnd={() => onVideoEnded?.()}
        onError={() => onVideoEnded?.()}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: StyleSheet.absoluteFillObject,
});
