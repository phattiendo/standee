/**
 * Standee RN — Slideshow full màn: SDP ↔ Poster ↔ Video (lật album).
 * Có ErrorBoundary (restart khi crash), Background fetch 30 phút.
 * Font mặc định: Montserrat (xem assets/fonts/README.md).
 */
import React, { useEffect } from 'react';
import { StatusBar, Text, View } from 'react-native';
import { FONT_REGULAR } from './src/core/theme/typography';

Text.defaultProps = { ...Text.defaultProps, style: [{ fontFamily: FONT_REGULAR }] };
import { SafeAreaProvider } from 'react-native-safe-area-context';
import { StandeeErrorBoundary } from './src/components/StandeeErrorBoundary';
import { StandeePlayerScreen } from './src/screens/StandeePlayerScreen';
import { initBackgroundFetch, setBackgroundFetchCallback } from './src/core/background/backgroundFetchService';
import { getPlaylistRefresh } from './src/core/playlistRefreshRegistry';

function App() {
  useEffect(() => {
    setBackgroundFetchCallback(async () => {
      const refresh = getPlaylistRefresh();
      if (refresh) await refresh();
    });
    initBackgroundFetch().then((ok) => {
      if (ok) console.log('[App] Background fetch registered (30 min)');
    });
  }, []);

  return (
    <SafeAreaProvider>
      <StatusBar barStyle="light-content" backgroundColor="transparent" translucent />
      <StandeeErrorBoundary>
        <View style={{ flex: 1 }}>
          <StandeePlayerScreen />
        </View>
      </StandeeErrorBoundary>
    </SafeAreaProvider>
  );
}

export default App;
