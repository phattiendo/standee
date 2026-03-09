import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:media_kit/media_kit.dart';

import 'bloc/app/app_bloc.dart';
import 'presentation/screens/app_flow_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo MediaKit cho video playback (bắt buộc trước khi dùng Player/Video trên standee)
  try {
    MediaKit.ensureInitialized();
  } catch (e, st) {
    debugPrint('MediaKit.ensureInitialized error: $e');
    debugPrint('$st');
  }

  // Khởi tạo Hive cho local storage
  await Hive.initFlutter();

  // Fullscreen mode cho signage
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // Giữ màn hình luôn sáng
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Giới hạn image cache cho standee (poster ~3–5MB decode, 6 đủ)
  PaintingBinding.instance.imageCache.maximumSize = 6;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 30 * 1024 * 1024; // 30MB

  runApp(
    BlocProvider(
      create: (context) => AppBloc()..add(const AppStarted()),
      child: const StandeeApp(),
    ),
  );
}

class StandeeApp extends StatelessWidget {
  const StandeeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const AppFlowScreen(),
    );
  }
}
