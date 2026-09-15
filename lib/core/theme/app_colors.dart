import 'package:flutter/material.dart';

/// Centralized color palette for JobMate.
/// Never hardcode colors in feature widgets — always reference this file.
class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFF2F6FED); // professional blue
  static const Color primaryDark = Color(0xFF1E4FBF);
  static const Color secondary = Color(0xFF12B76A); // success / growth green

  // Neutrals - Light
  static const Color lightBackground = Color(0xFFF7F8FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE6E8EC);
  static const Color lightTextPrimary = Color(0xFF14181F);
  static const Color lightTextSecondary = Color(0xFF6B7280);

  // Neutrals - Dark
  static const Color darkBackground = Color(0xFF0F1115);
  static const Color darkSurface = Color(0xFF1A1D23);
  static const Color darkBorder = Color(0xFF2A2E37);
  static const Color darkTextPrimary = Color(0xFFF5F6F8);
  static const Color darkTextSecondary = Color(0xFF9CA3AF);

  // Application status colors (used consistently everywhere)
  static const Color statusSaved = Color(0xFF9CA3AF); // neutral gray
  static const Color statusApplied = Color(0xFF2F6FED); // blue
  static const Color statusScreening = Color(0xFF8B5CF6); // purple
  static const Color statusInterview = Color(0xFFF59E0B); // orange
  static const Color statusOffer = Color(0xFF12B76A); // green
  static const Color statusRejected = Color(0xFFEF4444); // red
  static const Color statusWithdrawn = Color(0xFF6B7280); // gray

  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color success = Color(0xFF12B76A);
}
