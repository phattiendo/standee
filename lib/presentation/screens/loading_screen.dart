import 'package:flutter/material.dart';

import '../widgets/waiting_video_widget.dart';

/// Màn hình đang load (First Install / init) — hiệu ứng Cat playing thay vì spinner.
class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const WaitingVideoWidget(),
          Center(
            child: Text(
              'Đang tải...',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
