/**
 * Background fetch: ~30 phút sync playlist / download media.
 * Chạy nền khi app đang mở hoặc (tùy OS) khi app ở background.
 */
import BackgroundFetch from 'react-native-background-fetch';

const FETCH_INTERVAL_MINUTES = 30;

export type OnBackgroundFetchCallback = () => Promise<void>;

let onFetch: OnBackgroundFetchCallback | null = null;

export function setBackgroundFetchCallback(callback: OnBackgroundFetchCallback): void {
  onFetch = callback;
}

export async function initBackgroundFetch(): Promise<boolean> {
  try {
    const status = await BackgroundFetch.configure(
      {
        minimumFetchInterval: FETCH_INTERVAL_MINUTES,
        stopOnTerminate: false,
        startOnBoot: true,
      },
      async () => {
        if (onFetch) {
          try {
            await onFetch();
          } catch (_) {}
        }
        BackgroundFetch.finish();
      },
      () => {
        BackgroundFetch.finish();
      }
    );
    return status === BackgroundFetch.STATUS_AVAILABLE;
  } catch {
    return false;
  }
}
