// lib/app/app.dart
import 'package:flutter/material.dart';
import '../features/mcdu_core/presentation/mcdu_screen.dart';

class MCDUApp extends StatelessWidget {
  final Widget? home;

  const MCDUApp({super.key, this.home});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MCDU Trainer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
      ),
      home: home ?? const MCDUScreen(),
    );
  }
}
