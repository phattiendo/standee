import React, { useRef } from 'react';
import { StyleSheet, View } from 'react-native';
import Video from 'react-native-video';

/** Local file path cần prefix file:// để Video load được. */
function toFileUri(path: string): string {
  if (!path) return path;
  if (path.startsWith('file://')) return path;
  if (path.startsWith('http://') || path.startsWith('https://')) return path;
  return `file://${path}`;
}

interface MediaVideoProps {
  url: string;
  onVideoStarted?: () => void;
  onVideoEnded?: () => void;
}

export function MediaVideo({ url, onVideoStarted, onVideoEnded }: MediaVideoProps) {
  const ref = useRef<Video>(null);
  const sourceUri = (url && String(url).trim()) ? toFileUri(String(url).trim()) : '';

  if (!sourceUri) {
    return <View style={StyleSheet.absoluteFill} />;
  }

  return (
    <View style={StyleSheet.absoluteFill}>
      <Video
        ref={ref}
        source={{ uri: sourceUri }}
        style={StyleSheet.absoluteFill}
        resizeMode="cover"
        repeat
        onLoad={() => onVideoStarted?.()}
        onEnd={() => onVideoEnded?.()}
        onError={() => onVideoEnded?.()}
      />
    </View>
  );
}
