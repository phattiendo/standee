import { init as repoInit, loadInitial, refreshFromRemote } from '../../data/repositories/mediaRepository';
import { ensureDir } from '../storage/romMediaStorage';
import { appConfig } from '../config/appConfig';

export interface BootstrapResult {
  hasData: boolean;
  isOffline: boolean;
  needsSetup: boolean;
  errorMessage: string | null;
}

export async function runBootstrap(): Promise<BootstrapResult> {
  try {
    await repoInit();
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    return { hasData: false, isOffline: false, needsSetup: false, errorMessage: `Init: ${msg}` };
  }

  try {
    await ensureDir();
  } catch {
    // Thư mục lỗi vẫn cho vào slideshow (chỉ không lưu file local)
  }

  const cached = loadInitial();

  if (cached.length > 0) {
    void refreshFromRemote().catch(() => {});
    return { hasData: true, isOffline: false, needsSetup: false, errorMessage: null };
  }

  return {
    hasData: false,
    isOffline: false,
    needsSetup: true,
    errorMessage: null,
  };
}

export async function runFirstTimeSetup(
  onProgress: (progress: number, message: string) => void
): Promise<void> {
  onProgress(0, 'Đang tải tài nguyên...');
  try {
    await refreshFromRemote();
    onProgress(1, 'Đã lưu tất cả vào ROM');
  } catch {
    // API/mạng lỗi hoặc download lỗi: không throw, để AppFlowScreen vẫn setReady()
  }
}

export const firstTimeSetupMaxMinutes = appConfig.firstTimeSetupDurationMaxMinutes;
