import React from 'react';
import { Image, StyleSheet, View } from 'react-native';
import FastImage from 'react-native-fast-image';

const isRemote = (url: string) =>
  url.startsWith('http://') || url.startsWith('https://');

function toFileUri(path: string): string {
  if (!path) return path;
  if (path.startsWith('file://')) return path;
  if (path.startsWith('http://') || path.startsWith('https://')) return path;
  return `file://${path}`;
}

interface PosterViewProps {
  url: string;
}

/** Full-screen poster (ảnh) — dùng trong slideshow full màn hình. */
export function PosterView({ url }: PosterViewProps) {
  const trimmed = (url ?? '').trim();
  if (!trimmed) {
    return <View style={styles.container} />;
  }
  if (isRemote(trimmed)) {
    return (
      <FastImage
        source={{ uri: trimmed, priority: FastImage.priority.high }}
        style={styles.container}
        resizeMode={FastImage.resizeMode.cover}
      />
    );
  }
  return (
    <Image
      source={{ uri: toFileUri(trimmed) }}
      style={styles.container}
      resizeMode="cover"
    />
  );
}

const styles = StyleSheet.create({
  container: {
    ...StyleSheet.absoluteFillObject,
  },
});
