import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Palette
  static const Color background = Color(0xFF0A1628);
  static const Color surface = Color(0xFF112240);
  static const Color surfaceLight = Color(0xFF1A3155);
  static const Color card = Color(0xFF0D1F3C);

  // Accent
  static const Color gold = Color(0xFFC9A84C);
  static const Color goldLight = Color(0xFFE5C76B);
  static const Color green = Color(0xFF1E6B4A);
  static const Color greenLight = Color(0xFF2A9A6A);

  // Text
  static const Color textPrimary = Color(0xFFE8EAF0);
  static const Color textSecondary = Color(0xFF8A9BC0);
  static const Color textMuted = Color(0xFF4A5F7A);

  // Prayer Time Colors
  static const Color fajrColor = Color(0xFF4A6FA5);
  static const Color sunriseColor = Color(0xFFE8A020);
  static const Color dhuhrColor = Color(0xFF2E8B57);
  static const Color asrColor = Color(0xFF8B6914);
  static const Color maghribColor = Color(0xFFB85C38);
  static const Color ishaColor = Color(0xFF4A3F6B);

  // Gradients
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0A1628), Color(0xFF06101E)],
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFC9A84C), Color(0xFFE5C76B), Color(0xFFC9A84C)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF112240), Color(0xFF0D1F3C)],
  );

  static const LinearGradient nextPrayerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A3A5C), Color(0xFF0D2540)],
  );
}
