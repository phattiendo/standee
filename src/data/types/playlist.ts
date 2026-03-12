import type { MediaItem } from '../models/MediaItem';
import { apiConstants } from '../../core/constants/apiConstants';

/** Một slide trong slideshow full màn hình: SDP | Poster (ảnh) | Video */
export type SlideItem = MediaItem;

/** Thời gian mặc định mỗi slide (giây) */
export const DEFAULT_SLIDE_DURATION_SECONDS = 95;

/** URL ảo cho video asset local — FullScreenVideoView dùng để load require(assets/catoon.mp4). */
export const ASSET_VIDEO_CATOON_URL = 'asset://catoon.mp4';

/** Slide video asset catoon.mp4 trình chiếu full màn. */
export const ASSET_VIDEO_DURATION_SECONDS = 30;

/** Build playlist: SDP → Poster [→ Video nếu slideshowShowVideo]. */
export function buildStandeePlaylist(posters: MediaItem[], sdpDurationSeconds = DEFAULT_SLIDE_DURATION_SECONDS): SlideItem[] {
  const sdpSlide: SlideItem = {
    id: 'sdp',
    url: '',
    type: 'sdp',
    durationSeconds: sdpDurationSeconds,
  };
  const assetVideoSlide: SlideItem = {
    id: 'asset-catoon',
    url: ASSET_VIDEO_CATOON_URL,
    type: 'video',
    durationSeconds: ASSET_VIDEO_DURATION_SECONDS,
  };
  const posterSlides: SlideItem[] = posters.map((p) => ({
    ...p,
    durationSeconds: p.durationSeconds > 0 ? p.durationSeconds : sdpDurationSeconds,
  }));
  const withVideo = apiConstants.slideshowShowVideo;
  return withVideo ? [sdpSlide, ...posterSlides, assetVideoSlide] : [sdpSlide, ...posterSlides];
}
