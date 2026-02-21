import 'package:flutter/material.dart';
import 'screens/start_screen.dart';

class MagicalVibeApp extends StatelessWidget {
  const MagicalVibeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Magical Vibe',
      theme: ThemeData(
        fontFamily: 'Roboto', // Default font
        brightness: Brightness.dark, // Ensure dark theme base
      ),
      home: const StartScreen(),
    );
  }
}





