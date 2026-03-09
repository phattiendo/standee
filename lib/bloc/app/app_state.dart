import 'package:equatable/equatable.dart';

/// Trạng thái tổng thể của app (theo Standee System Architecture).
sealed class AppState extends Equatable {
  const AppState();

  @override
  List<Object?> get props => [];
}

/// Chưa khởi động
class AppInitial extends AppState {
  const AppInitial();
}

/// Đang load lần đầu (init, fetch playlist)
class AppLoading extends AppState {
  const AppLoading();
}

/// Sẵn sàng phát (có data, có thể offline hoặc online)
class AppReady extends AppState {
  const AppReady();
}

/// Mất mạng / chưa có data (first launch no internet)
class AppOffline extends AppState {
  final String? message;
  const AppOffline({this.message});
  @override
  List<Object?> get props => [message];
}

/// Đang cập nhật tài nguyên (download, replace)
class AppUpdating extends AppState {
  /// 0.0 .. 1.0
  final double progress;
  final String? message;
  const AppUpdating({this.progress = 0.0, this.message});
  @override
  List<Object?> get props => [progress, message];
}

/// Lỗi (API fail, init fail)
class AppError extends AppState {
  final String message;
  const AppError(this.message);
  @override
  List<Object?> get props => [message];
}
