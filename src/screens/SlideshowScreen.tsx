import React from 'react';
import { StyleSheet, View } from 'react-native';
import { Slideshow } from '../components/Slideshow';

export function SlideshowScreen() {
  return (
    <View style={styles.container}>
      <Slideshow />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#000',
  },
});
