/// Neo-Brutalist color palette for Academic Scheduler.
///
/// Visual principles from AGENTS.md §15:
/// - thick black borders
/// - hard offset shadows
/// - high contrast
/// - flat surfaces
/// - strong accent colours
import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Core palette ──
  static const Color background = Color(0xFFF5F1E8);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF1A1A1A);

  // ── Accent colours ──
  static const Color primary = Color(0xFFFFDE59);        // Yellow
  static const Color secondary = Color(0xFFFF6B6B);      // Coral red
  static const Color tertiary = Color(0xFF7EB7FF);       // Sky blue
  static const Color success = Color(0xFF77DD77);         // Mint green
  static const Color warning = Color(0xFFFFB347);         // Orange

  // ── Text ──
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF4A4A4A);
  static const Color textMuted = Color(0xFF8A8A8A);

  // ── Border ──
  static const Color border = Color(0xFF1A1A1A);

  // ── Error ──
  static const Color error = Color(0xFFFF4444);
}
