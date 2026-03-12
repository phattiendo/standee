import React from 'react';
import { StyleSheet, Text, View } from 'react-native';

interface UpdateProgressScreenProps {
  progress: number;
  message: string;
}

export function UpdateProgressScreen({ progress, message }: UpdateProgressScreenProps) {
  return (
    <View style={styles.container}>
      <Text style={styles.text}>{message}</Text>
      <View style={styles.barBg}>
        <View style={[styles.barFill, { width: `${progress * 100}%` }]} />
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#000',
    justifyContent: 'center',
    alignItems: 'center',
    padding: 24,
  },
  text: {
    color: 'rgba(255,255,255,0.9)',
    fontSize: 16,
    marginBottom: 16,
  },
  barBg: {
    width: '80%',
    height: 8,
    backgroundColor: '#333',
    borderRadius: 4,
    overflow: 'hidden',
  },
  barFill: {
    height: '100%',
    backgroundColor: '#0a0',
  },
});
