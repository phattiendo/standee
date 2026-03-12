export interface SlideshowConfigState {
  enablePoster: boolean;
  enableSdp: boolean;
  enableVideo: boolean;
  enableAudio: boolean;
  enableLocalAssets: boolean;
  backgroundMusicPath: string;
  localVideoPath: string;
  videoDurationSeconds: number;
}

export const defaultSlideshowConfig: SlideshowConfigState = {
  enablePoster: true,
  enableSdp: true,
  enableVideo: true,
  enableAudio: true,
  enableLocalAssets: true,
  backgroundMusicPath: 'assets/elkt.mp3',
  localVideoPath: 'assets/catoon.mp4',
  videoDurationSeconds: 30,
};
