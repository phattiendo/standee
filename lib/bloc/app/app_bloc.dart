import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/bootstrap/app_bootstrap.dart';
import 'app_event.dart';
import 'app_state.dart';

export 'app_event.dart';
export 'app_state.dart';

class AppBloc extends Bloc<AppEvent, AppState> {
  AppBloc({AppBootstrap? bootstrap})
      : _bootstrap = bootstrap ?? AppBootstrap(),
        super(const AppInitial()) {
    on<AppStarted>(_onAppStarted);
    on<AppRetryRequested>(_onRetryRequested);
    on<AppCheckUpdateRequested>(_onCheckUpdateRequested);
    on<AppUpdateProgressChanged>(_onUpdateProgressChanged);
    on<AppUpdateCompleted>(_onUpdateCompleted);
  }

  final AppBootstrap _bootstrap;

  Future<void> _onAppStarted(AppStarted event, Emitter<AppState> emit) async {
    emit(const AppLoading());
    final result = await _bootstrap.run();

    if (result.hasData) {
      emit(const AppReady());
    } else if (result.needsSetup) {
      emit(const AppUpdating(
        progress: 0.0,
        message: 'Đang tải tài nguyên vào ROM (1–5 phút)...',
      ));
      await _bootstrap.runFirstTimeSetup((progress, message) {
        add(AppUpdateProgressChanged(progress: progress, message: message));
      });
      add(AppUpdateCompleted());
    } else if (result.isOffline) {
      emit(AppOffline(message: result.errorMessage));
    } else {
      emit(AppError(result.errorMessage ?? 'Lỗi khởi tạo'));
    }
  }

  Future<void> _onRetryRequested(
      AppRetryRequested event, Emitter<AppState> emit) async {
    emit(const AppLoading());
    final result = await _bootstrap.run();

    if (result.hasData) {
      emit(const AppReady());
    } else if (result.needsSetup) {
      emit(const AppUpdating(
        progress: 0.0,
        message: 'Đang tải tài nguyên vào ROM (1–5 phút)...',
      ));
      await _bootstrap.runFirstTimeSetup((progress, message) {
        add(AppUpdateProgressChanged(progress: progress, message: message));
      });
      add(AppUpdateCompleted());
    } else if (result.isOffline) {
      emit(AppOffline(message: result.errorMessage));
    } else {
      emit(AppError(result.errorMessage ?? 'Thử lại thất bại'));
    }
  }

  void _onCheckUpdateRequested(
      AppCheckUpdateRequested event, Emitter<AppState> emit) {
    // Sau này: trigger Update Manager, emit AppUpdating khi bắt đầu tải
    debugPrint('AppBloc: CheckUpdateRequested (not implemented yet)');
    // emit(const AppUpdating(progress: 0.0));
  }

  void _onUpdateProgressChanged(
      AppUpdateProgressChanged event, Emitter<AppState> emit) {
    emit(AppUpdating(progress: event.progress, message: event.message));
  }

  void _onUpdateCompleted(AppUpdateCompleted event, Emitter<AppState> emit) {
    emit(const AppReady());
  }
}
