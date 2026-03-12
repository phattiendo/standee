import React, { useState } from 'react';
import { Animated, StyleSheet, Text, View } from 'react-native';
import FastImage from 'react-native-fast-image';
import { MediaItem } from '../data/models/MediaItem';
import { useSlideshowController } from '../controllers/useSlideshowController';
import { MediaImage } from './MediaImage';
import { MediaVideo } from './MediaVideo';
import { SDPWidget } from './SDPWidget';

const FADE_DURATION = 200;

export function Slideshow() {
  const [items, setItems] = useState<MediaItem[]>([]);
  const [currentIndex, setCurrentIndex] = useState(0);
  const [visibleLayer, setVisibleLayer] = useState(0);
  const opacity0 = React.useRef(new Animated.Value(1)).current;
  const opacity1 = React.useRef(new Animated.Value(0)).current;

  const { getDisplayUrl, notifyVideoStarted, notifyVideoEnded } = useSlideshowController({
    onMediaChanged: (current, index, all) => {
      setItems(all);
      if (all.length > 0) {
        const prevIdx = currentIndex;
        setCurrentIndex(index);
        if (all.length >= 2 && prevIdx !== index) {
          setVisibleLayer((l) => 1 - l);
          const out = visibleLayer === 0 ? opacity0 : opacity1;
          const inVal = visibleLayer === 0 ? opacity1 : opacity0;
          Animated.parallel([
            Animated.timing(out, { toValue: 0, duration: FADE_DURATION, useNativeDriver: true }),
            Animated.timing(inVal, { toValue: 1, duration: FADE_DURATION, useNativeDriver: true }),
          ]).start();
        }
      }
    },
    onPreloadImage: (url) => {
      const uri = url != null ? String(url).trim() : '';
      if (uri.length > 0) {
        try {
          FastImage.preload([{ uri }]);
        } catch (_) {}
      }
    },
    onReleaseImage: () => {},
  });

  const renderItem = (item: MediaItem) => {
    const url = getDisplayUrl(item);
    switch (item.type) {
      case 'image':
        return <MediaImage url={url} />;
      case 'video':
        return (
          <MediaVideo
            url={url}
            onVideoStarted={notifyVideoStarted}
            onVideoEnded={notifyVideoEnded}
          />
        );
      case 'sdp':
        return (
          <SDPWidget
            posterUrl={item.url || undefined}
            backgroundAsset={item.sdpBackgroundAsset}
          />
        );
      default:
        return null;
    }
  };

  if (items.length === 0) {
    return (
      <View style={styles.placeholder}>
        <Text style={styles.placeholderText}>Đang tải...</Text>
      </View>
    );
  }

  if (items.length < 2) {
    return <View style={StyleSheet.absoluteFill}>{renderItem(items[0])}</View>;
  }

  const n = items.length;
  const layer0Idx = visibleLayer === 0 ? currentIndex : (currentIndex - 1 + n) % n;
  const layer1Idx = visibleLayer === 1 ? currentIndex : (currentIndex + 1) % n;

  return (
    <View style={StyleSheet.absoluteFill}>
      <Animated.View style={[StyleSheet.absoluteFill, { opacity: opacity0 }]}>
        {renderItem(items[layer0Idx])}
      </Animated.View>
      <Animated.View style={[StyleSheet.absoluteFill, { opacity: opacity1 }]}>
        {renderItem(items[layer1Idx])}
      </Animated.View>
    </View>
  );
}

const styles = StyleSheet.create({
  placeholder: {
    flex: 1,
    backgroundColor: '#000',
    justifyContent: 'center',
    alignItems: 'center',
  },
  placeholderText: {
    color: '#fff',
    fontSize: 16,
  },
});
