import React, { Component, ErrorInfo, ReactNode } from 'react';
import { Text, View } from 'react-native';
import { restartApp } from '../core/watchdog/restartService';

const RESTART_DELAY_MS = 3000;

interface Props {
  children: ReactNode;
}

interface State {
  hasError: boolean;
  error: Error | null;
}

/**
 * Bắt crash → hiển thị thông báo ngắn → restart app (24/7 standee).
 */
export class StandeeErrorBoundary extends Component<Props, State> {
  state: State = { hasError: false, error: null };
  private restartTimeout: ReturnType<typeof setTimeout> | null = null;

  static getDerivedStateFromError(error: Error): Partial<State> {
    return { hasError: true, error };
  }

  componentDidCatch(error: Error, errorInfo: ErrorInfo): void {
    console.error('[StandeeErrorBoundary]', error, errorInfo);
    this.restartTimeout = setTimeout(() => {
      restartApp();
    }, RESTART_DELAY_MS);
  }

  componentWillUnmount(): void {
    if (this.restartTimeout) clearTimeout(this.restartTimeout);
  }

  render(): ReactNode {
    if (this.state.hasError) {
      return (
        <View style={{ flex: 1, justifyContent: 'center', alignItems: 'center', backgroundColor: '#111', padding: 24 }}>
          <Text style={{ color: '#f88', textAlign: 'center' }}>
            Đã xảy ra lỗi. Đang khởi động lại...
          </Text>
        </View>
      );
    }
    return this.props.children;
  }
}
