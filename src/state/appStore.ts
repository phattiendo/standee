import { create } from 'zustand';

export type AppStatus =
  | 'initial'
  | 'loading'
  | 'ready'
  | 'offline'
  | 'updating'
  | 'error';

export interface AppState {
  status: AppStatus;
  errorMessage: string | null;
  updateProgress: number;
  updateMessage: string | null;
}

interface AppActions {
  setLoading: () => void;
  setReady: () => void;
  setOffline: (message?: string) => void;
  setUpdating: (progress: number, message: string) => void;
  setError: (message: string) => void;
  retry: () => void;
}

const initialState: AppState = {
  status: 'initial',
  errorMessage: null,
  updateProgress: 0,
  updateMessage: null,
};

export const useAppStore = create<AppState & AppActions>((set) => ({
  ...initialState,

  setLoading: () => set({ status: 'loading', errorMessage: null }),

  setReady: () =>
    set({
      status: 'ready',
      errorMessage: null,
      updateProgress: 1,
      updateMessage: null,
    }),

  setOffline: (message) =>
    set({ status: 'offline', errorMessage: message ?? null }),

  setUpdating: (progress, message) =>
    set({
      status: 'updating',
      updateProgress: progress,
      updateMessage: message,
    }),

  setError: (message) =>
    set({ status: 'error', errorMessage: message }),

  retry: () => set({ status: 'initial', errorMessage: null }),
}));
