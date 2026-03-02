import 'package:flutter/material.dart';

import '../widgets/slideshow_widget.dart';

class SlideshowScreen extends StatelessWidget {
  const SlideshowScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: const SafeArea(
        child: SlideshowWidget(),
      ),
    );
  }
}

