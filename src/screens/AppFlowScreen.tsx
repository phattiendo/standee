import React, { useEffect } from 'react';
import { useAppStore } from '../state/appStore';
import {
  runBootstrap,
  runFirstTimeSetup,
} from '../core/bootstrap/appBootstrap';
import { LoadingScreen } from './LoadingScreen';
import { SlideshowScreen } from './SlideshowScreen';
import { ErrorScreen } from './ErrorScreen';
import { OfflineScreen } from './OfflineScreen';
import { UpdateProgressScreen } from './UpdateProgressScreen';

export default function AppFlowScreen() {
  const { status, errorMessage, updateProgress, updateMessage, setLoading, setReady, setOffline, setError, setUpdating, retry } =
    useAppStore();

  useEffect(() => {
    if (status !== 'initial') return;
    setLoading();

    const timeoutMs = 15000;
    const bootstrapPromise = Promise.race([
      runBootstrap(),
      new Promise<never>((_, reject) =>
        setTimeout(() => reject(new Error('Bootstrap timeout')), timeoutMs)
      ),
    ]);

    bootstrapPromise
      .then((result) => {
        if (result.hasData) {
          setReady();
          return;
        }
        if (result.needsSetup) {
          setUpdating(0, 'Đang tải tài nguyên và setup (1–5 phút)...');
          runFirstTimeSetup((progress, message) => {
            try {
              setUpdating(progress, message);
            } catch (_) {}
          })
            .then(() => setReady())
            .catch(() => setReady());
          return;
        }
        if (result.isOffline) {
          setOffline(result.errorMessage ?? undefined);
          return;
        }
        setError(result.errorMessage ?? 'Lỗi khởi tạo');
      })
      .catch((e) => {
        const msg = e instanceof Error ? e.message : String(e);
        setError(msg.includes('timeout') ? 'Khởi động quá lâu. Thử lại.' : `Lỗi: ${msg}`);
      });
  }, [status, setLoading, setReady, setOffline, setError, setUpdating]);

  if (status === 'loading' || status === 'initial') {
    return <LoadingScreen />;
  }
  if (status === 'ready') {
    return <SlideshowScreen />;
  }
  if (status === 'offline') {
    return <OfflineScreen message={errorMessage ?? undefined} onRetry={retry} />;
  }
  if (status === 'updating') {
    return (
      <UpdateProgressScreen
        progress={updateProgress ?? 0}
        message={updateMessage ?? 'Đang tải...'}
      />
    );
  }
  return <ErrorScreen message={errorMessage ?? 'Lỗi'} onRetry={retry} />;
}
