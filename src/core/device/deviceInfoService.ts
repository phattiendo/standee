/**
 * Device info cho Standee: deviceId, model, RAM, storage.
 * Dùng cho API (deviceId) và hiển thị / watchdog.
 */
import DeviceInfo from 'react-native-device-info';

export interface DeviceInfoData {
  deviceId: string;
  model: string;
  totalMemoryMb: number;
  freeStorageMb: number;
}

let cached: DeviceInfoData | null = null;

export async function getDeviceInfo(): Promise<DeviceInfoData> {
  if (cached) return cached;
  const [deviceId, model, totalMemory, freeDisk] = await Promise.all([
    Promise.resolve(DeviceInfo.getDeviceId?.() ?? '').catch(() => 'unknown'),
    Promise.resolve(DeviceInfo.getModel?.() ?? '').catch(() => ''),
    (DeviceInfo.getTotalMemory?.() ?? Promise.resolve(0)).catch(() => 0),
    (DeviceInfo.getFreeDiskStorage?.() ?? Promise.resolve(0)).catch(() => 0),
  ]);
  cached = {
    deviceId,
    model,
    totalMemoryMb: Math.round(totalMemory / (1024 * 1024)),
    freeStorageMb: Math.round(freeDisk / (1024 * 1024)),
  };
  return cached;
}

/** Sync device id (getDeviceId() trong react-native-device-info trả về string). */
export function getDeviceIdSync(): string {
  try {
    return DeviceInfo.getDeviceId?.() ?? 'unknown';
  } catch {
    return 'unknown';
  }
}
