import 'package:flutter/material.dart';

class AppColor {
  // Primary Colors - Modern Purple/Blue
  static const Color primary = Color(0xFF6C63FF);
  static const Color primaryDark = Color(0xFF5B52E8);
  static const Color primaryLight = Color(0xFF8B85FF);

  // Accent Colors - Vibrant Orange/Coral
  static const Color accent = Color(0xFFFF6B6B);
  static const Color accentLight = Color(0xFFFF8E8E);

  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  // Neutral Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color grey = Color(0xFF9E9E9E);
  static const Color greyLight = Color(0xFFE0E0E0);
  static const Color greyDark = Color(0xFF424242);

  // Background Colors
  static const Color background = Color(0xFFF8F9FA);
  static const Color cardBackground = Color(0xFFFFFFFF);

  // Gradients
  static const List<Color> primaryGradient = [
    Color(0xFF6C63FF),
    Color(0xFF8B85FF),
  ];
  static const List<Color> accentGradient = [
    Color(0xFFFF6B6B),
    Color(0xFFFF8E8E),
  ];

  // Legacy support
  static const Color redColor = error;
  static const Color secondary = white;
}
