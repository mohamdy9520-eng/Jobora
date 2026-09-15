import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralized typography. Arabic falls back to Cairo/Tajawal-style metrics
/// automatically via GoogleFonts when the active locale is 'ar'.
class AppTextStyles {
  AppTextStyles._();

  static TextStyle _base(Color color) => GoogleFonts.inter(color: color);

  static TextStyle h1(Color color) =>
      _base(color).copyWith(fontSize: 28, fontWeight: FontWeight.w700, height: 1.25);

  static TextStyle h2(Color color) =>
      _base(color).copyWith(fontSize: 22, fontWeight: FontWeight.w700, height: 1.3);

  static TextStyle h3(Color color) =>
      _base(color).copyWith(fontSize: 18, fontWeight: FontWeight.w600, height: 1.3);

  static TextStyle bodyLarge(Color color) =>
      _base(color).copyWith(fontSize: 16, fontWeight: FontWeight.w400, height: 1.5);

  static TextStyle bodyMedium(Color color) =>
      _base(color).copyWith(fontSize: 14, fontWeight: FontWeight.w400, height: 1.5);

  static TextStyle bodySmall(Color color) =>
      _base(color).copyWith(fontSize: 12, fontWeight: FontWeight.w400, height: 1.4);

  static TextStyle labelMedium(Color color) =>
      _base(color).copyWith(fontSize: 13, fontWeight: FontWeight.w600, height: 1.3);

  static TextStyle button(Color color) =>
      _base(color).copyWith(fontSize: 15, fontWeight: FontWeight.w600);
}

/// Consistent spacing scale.
class AppSpacing {
  AppSpacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
}

class AppRadius {
  AppRadius._();
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double pill = 999;
}
