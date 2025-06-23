import 'package:flutter/material.dart';

import 'app/features/pattern_lock/presentation/screens/pattern_lock_screen.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: PatternLockScreen(
        correctPattern: [0, 4, 8, 5, 2],
      ),
    );
  }
}
