/**
 * Restart app: dùng khi memory leak, video crash, hoặc sau update playlist.
 */
import RNRestart from 'react-native-restart';

export function restartApp(): void {
  try {
    RNRestart.restart();
  } catch {
    // Fallback không có trên một số môi trường
  }
}
