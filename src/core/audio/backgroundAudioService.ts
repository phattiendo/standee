/**
 * Background audio (nhạc nền) — tương đương just_audio Flutter.
 * Dùng react-native-track-player: init, fadeOut/fadeIn khi chuyển slide video.
 * Placeholder: chỉ export enabled flag và stubs.
 */
let enabled = true;

export const backgroundAudioService = {
  get enabled() {
    return enabled;
  },
  set enabled(value: boolean) {
    enabled = value;
  },
  async init(_options: { assetPath?: string; filePath?: string | null }): Promise<void> {
    // TODO: TrackPlayer.setupPlayer(), add track from filePath
  },
  fadeOutAndPause(): void {
    // TODO: pause / volume down
  },
  resumeAndFadeIn(): void {
    // TODO: play / volume up
  },
};
