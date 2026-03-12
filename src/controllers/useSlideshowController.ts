import { useCallback, useEffect, useRef, useState } from 'react';
import { MediaItem, getPlaybackUrl } from '../data/models/MediaItem';
import { loadInitial, checkVersionAndUpdateIfNeeded } from '../data/repositories/mediaRepository';
import { defaultSlideshowConfig } from '../core/config/slideshowConfig';
import { apiConstants } from '../core/constants/apiConstants';
import { fullPath } from '../core/storage/romMediaStorage';
import { backgroundAudioService } from '../core/audio/backgroundAudioService';

const REFRESH_INTERVAL_MS = 15 * 60 * 1000;

export interface UseSlideshowControllerOptions {
  onMediaChanged?: (current: MediaItem | null, index: number, all: MediaItem[]) => void;
  onPreloadImage?: (url: string) => void;
  onPreloadVideo?: (url: string) => void;
  onReleaseImage?: (url: string) => void;
}

function getDisplayUrl(item: MediaItem): string {
  return getPlaybackUrl(item, (relative) => fullPath(relative) ?? null);
}

function buildMediaList(apiItems: MediaItem[]): MediaItem[] {
  const config = defaultSlideshowConfig;
  const media: MediaItem[] = [];

  if (config.enableSdp) {
    const firstPoster = apiItems.find((i) => i.type === 'image' && i.url)?.url;
    media.push({
      id: 'sdp',
      url: firstPoster ?? '',
      type: 'sdp',
      durationSeconds: apiConstants.sdpDurationSeconds,
      sdpBackgroundAsset: apiConstants.sdpDefaultBackground,
    });
  }

  if (config.enablePoster) {
    media.push(...apiItems.filter((i) => i.type === 'image'));
  }

  if (config.enableVideo) {
    media.push(...apiItems.filter((i) => i.type === 'video'));
  }

  if (media.length === 0) {
    media.push({
      id: 'sdp',
      url: '',
      type: 'sdp',
      durationSeconds: apiConstants.sdpDurationSeconds,
      sdpBackgroundAsset: apiConstants.sdpDefaultBackground,
    });
  }

  return media;
}

export function useSlideshowController(options: UseSlideshowControllerOptions = {}) {
  const [media, setMedia] = useState<MediaItem[]>([]);
  const [currentIndex, setCurrentIndex] = useState(0);
  const timerRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const lastRefreshRef = useRef<number>(0);
  const initializedRef = useRef(false);
  const nextSlideRef = useRef<() => void>(() => {});

  const current = media.length === 0 ? null : media[currentIndex % media.length];
  const next = media.length < 2 ? null : media[(currentIndex + 1) % media.length];

  const notify = useCallback(() => {
    const cur = media.length === 0 ? null : media[currentIndex % media.length];
    options.onMediaChanged?.(cur, currentIndex, media);
  }, [media, currentIndex, options.onMediaChanged]);

  const releasePrevious = useCallback(
    (prevItem: MediaItem | null) => {
      if (!prevItem || prevItem.type !== 'image') return;
      const url = getDisplayUrl(prevItem);
      if (url) options.onReleaseImage?.(url);
    },
    [options.onReleaseImage]
  );

  const preloadCurrent = useCallback(() => {
    if (!current || current.type !== 'image' || current.url.startsWith('asset:')) return;
    const url = getDisplayUrl(current)?.trim();
    if (url) options.onPreloadImage?.(url);
  }, [current, options.onPreloadImage]);

  const preloadNext = useCallback(() => {
    if (!next) return;
    const url = getDisplayUrl(next)?.trim();
    if (!url) return;
    if (next.type === 'image' && !next.url.startsWith('asset:')) {
      options.onPreloadImage?.(url);
    } else if (next.type === 'video') {
      options.onPreloadVideo?.(url);
    }
  }, [next, options.onPreloadImage, options.onPreloadVideo]);

  const nextSlide = useCallback(() => {
    if (timerRef.current) {
      clearTimeout(timerRef.current);
      timerRef.current = null;
    }
    if (media.length === 0) return;

    const prevItem = media[currentIndex % media.length];
    const newIndex = (currentIndex + 1) % media.length;
    const nextItem = media[newIndex];
    const afterNext = media.length > 1 ? media[(newIndex + 1) % media.length] : null;

    releasePrevious(prevItem);

    if (defaultSlideshowConfig.enableAudio) {
      const wasVideo = prevItem?.type === 'video';
      const isVideo = nextItem?.type === 'video';
      if (!wasVideo && isVideo) backgroundAudioService.fadeOutAndPause();
      else if (wasVideo && !isVideo) backgroundAudioService.resumeAndFadeIn();
    }

    setCurrentIndex(newIndex);
    options.onMediaChanged?.(nextItem, newIndex, media);

    if (afterNext) {
      const url = getDisplayUrl(afterNext)?.trim();
      if (url) {
        if (afterNext.type === 'image' && !afterNext.url.startsWith('asset:')) {
          options.onPreloadImage?.(url);
        } else if (afterNext.type === 'video') {
          options.onPreloadVideo?.(url);
        }
      }
    }
    // Timer will be restarted by useEffect when currentIndex updates
  }, [media, currentIndex, releasePrevious, options.onMediaChanged, options.onPreloadImage, options.onPreloadVideo]);

  nextSlideRef.current = nextSlide;

  // Start/restart slide timer when media or currentIndex changes
  useEffect(() => {
    if (media.length === 0) return;
    const cur = media[currentIndex % media.length];
    if (!cur) return;
    if (timerRef.current) clearTimeout(timerRef.current);
    timerRef.current = setTimeout(() => nextSlideRef.current(), cur.durationSeconds * 1000);
    return () => {
      if (timerRef.current) clearTimeout(timerRef.current);
    };
  }, [media, currentIndex]);

  useEffect(() => {
    if (media.length > 0) {
      notify();
    }
  }, [currentIndex, media, notify]);

  const refresh = useCallback(async () => {
    const now = Date.now();
    if (lastRefreshRef.current && now - lastRefreshRef.current < REFRESH_INTERVAL_MS) return;
    lastRefreshRef.current = now;
    try {
      const newList = await checkVersionAndUpdateIfNeeded();
      if (!newList || newList.length === 0) return;
      const built = buildMediaList(newList);
      setMedia(built);
      if (currentIndex >= built.length) setCurrentIndex(0);
      notify();
      preloadNext();
    } catch (_) {}
  }, [currentIndex, notify, preloadNext]);

  useEffect(() => {
    if (initializedRef.current) return;
    initializedRef.current = true;

    const cached = loadInitial();
    if (cached.length > 0) {
      const built = buildMediaList(cached);
      setMedia(built);
      setCurrentIndex(0);
      options.onMediaChanged?.(built[0] ?? null, 0, built);
      const first = built[0];
      if (first?.type === 'image' && !first.url.startsWith('asset:')) {
        const u = getDisplayUrl(first);
        if (u?.trim()) options.onPreloadImage?.(u.trim());
      }
      const second = built[1];
      if (second) {
        const url = getDisplayUrl(second);
        if (url?.trim()) {
          if (second.type === 'image' && !second.url.startsWith('asset:')) options.onPreloadImage?.(url.trim());
          else if (second.type === 'video') options.onPreloadVideo?.(url.trim());
        }
      }
      void refresh();
    } else {
      void refresh().then(() => {
        const again = loadInitial();
        if (again.length > 0) {
          const built = buildMediaList(again);
          setMedia(built);
          setCurrentIndex(0);
          options.onMediaChanged?.(built[0] ?? null, 0, built);
          const first = built[0];
          if (first?.type === 'image' && !first.url.startsWith('asset:')) {
            const u = getDisplayUrl(first);
            if (u?.trim()) options.onPreloadImage?.(u.trim());
          }
          const second = built[1];
          if (second) {
            const url = getDisplayUrl(second);
            if (url?.trim()) {
              if (second.type === 'image' && !second.url.startsWith('asset:')) options.onPreloadImage?.(url.trim());
              else if (second.type === 'video') options.onPreloadVideo?.(url.trim());
            }
          }
        }
      });
    }

    return () => {
      if (timerRef.current) clearTimeout(timerRef.current);
    };
  }, []);

  const notifyVideoStarted = useCallback(() => {
    if (defaultSlideshowConfig.enableAudio) {
      backgroundAudioService.fadeOutAndPause();
    }
  }, []);

  const notifyVideoEnded = useCallback(() => {
    if (defaultSlideshowConfig.enableAudio) {
      backgroundAudioService.resumeAndFadeIn();
    }
    nextSlide();
  }, [nextSlide]);

  return {
    media,
    currentIndex,
    current,
    next,
    nextSlide,
    preloadNext,
    preloadCurrent,
    releasePrevious,
    getDisplayUrl,
    notifyVideoStarted,
    notifyVideoEnded,
  };
}
