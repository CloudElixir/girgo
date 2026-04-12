import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF0B510E); // Dark green instead of blue
  static const Color secondary = Color(0xFF83C56B);
  static const Color background = Color(0xFFFFFFFF);
  static const Color text = Color(0xFF333333);
  static const Color textLight = Color(0xFF666666);
  static const Color border = Color(0xFFE0E0E0);
  static const Color error = Color(0xFFFF6B6B);
  static const Color success = Color(0xFF83C56B);
  static const Color warning = Color(0xFFFFA726);
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color gray = Color(0xFFF5F5F5);
  static const Color darkGray = Color(0xFF9E9E9E);
}

class AppTextStyles {
  static const TextStyle heading1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.text,
  );
  
  static const TextStyle heading2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.text,
  );
  
  static const TextStyle heading3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.text,
  );
  
  static const TextStyle body = TextStyle(
    fontSize: 16,
    color: AppColors.text,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontSize: 14,
    color: AppColors.textLight,
  );
  
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    color: AppColors.textLight,
  );
}

class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
}

class AppBorderRadius {
  static const double small = 8.0;
  static const double medium = 12.0;
  static const double large = 16.0;
  static const double xlarge = 24.0;
}

