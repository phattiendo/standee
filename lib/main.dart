import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:media_kit/media_kit.dart';

import 'presentation/screens/slideshow_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo MediaKit cho video playback
  MediaKit.ensureInitialized();

  // Khởi tạo Hive cho local storage
  await Hive.initFlutter();

  // Fullscreen mode cho signage
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // Giữ màn hình luôn sáng
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  runApp(const SlideshowApp());
}

class SlideshowApp extends StatelessWidget {
  const SlideshowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SlideshowScreen(),
    );
  }
}
