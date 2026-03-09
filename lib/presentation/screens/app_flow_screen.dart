import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/app/app_bloc.dart';
import 'error_screen.dart';
import 'loading_screen.dart';
import 'offline_screen.dart';
import 'slideshow_screen.dart';
import 'update_progress_screen.dart';

/// Một màn hình gốc: đọc AppState và hiển thị màn tương ứng.
class AppFlowScreen extends StatelessWidget {
  const AppFlowScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppBloc, AppState>(
      buildWhen: (previous, current) => previous.runtimeType != current.runtimeType || _progressChanged(previous, current),
      builder: (context, state) {
        return switch (state) {
          AppInitial() => const LoadingScreen(),
          AppLoading() => const LoadingScreen(),
          AppReady() => const SlideshowScreen(),
          AppOffline(:final message) => OfflineScreen(message: message),
          AppUpdating(:final progress, :final message) => UpdateProgressScreen(
              progress: progress,
              message: message,
            ),
          AppError(:final message) => ErrorScreen(message: message),
        };
      },
    );
  }

  bool _progressChanged(AppState a, AppState b) {
    if (a is AppUpdating && b is AppUpdating) {
      return a.progress != b.progress || a.message != b.message;
    }
    return false;
  }
}
