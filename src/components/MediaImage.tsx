import React from 'react';
import { Image, StyleSheet, View } from 'react-native';
import FastImage from 'react-native-fast-image';

const isRemote = (url: string) =>
  url.startsWith('http://') || url.startsWith('https://');

/** Local file path cần prefix file:// để Image load được trên Android/iOS. */
function toFileUri(path: string): string {
  if (!path) return path;
  if (path.startsWith('file://')) return path;
  if (path.startsWith('http://') || path.startsWith('https://')) return path;
  return `file://${path}`;
}

interface MediaImageProps {
  url: string;
}

export function MediaImage({ url }: MediaImageProps) {
  const trimmed = (url ?? '').trim();
  if (!trimmed) {
    return <View style={StyleSheet.absoluteFill} />;
  }
  if (isRemote(trimmed)) {
    return (
      <FastImage
        source={{ uri: trimmed, priority: FastImage.priority.high }}
        style={StyleSheet.absoluteFill}
        resizeMode={FastImage.resizeMode.cover}
      />
    );
  }
  return (
    <Image
      source={{ uri: toFileUri(trimmed) }}
      style={StyleSheet.absoluteFill}
      resizeMode="cover"
    />
  );
}
