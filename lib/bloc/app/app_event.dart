import 'package:equatable/equatable.dart';

/// Event cho AppBloc
sealed class AppEvent extends Equatable {
  const AppEvent();
  @override
  List<Object?> get props => [];
}

/// App khởi động (màn hình đầu tiên)
class AppStarted extends AppEvent {
  const AppStarted();
}

/// User bấm Thử lại (sau Offline / Error)
class AppRetryRequested extends AppEvent {
  const AppRetryRequested();
}

/// Bắt đầu kiểm tra / tải cập nhật (ví dụ timer 15 phút)
class AppCheckUpdateRequested extends AppEvent {
  const AppCheckUpdateRequested();
}

/// Cập nhật tiến độ (gọi từ Update Manager sau này)
class AppUpdateProgressChanged extends AppEvent {
  final double progress;
  final String? message;
  const AppUpdateProgressChanged({required this.progress, this.message});
  @override
  List<Object?> get props => [progress, message];
}

/// Cập nhật xong
class AppUpdateCompleted extends AppEvent {
  const AppUpdateCompleted();
}
