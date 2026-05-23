import 'package:flutter/material.dart';

class AppConstants {
  // ── Brand colors ────────────────────────────────────────────────────────────
  /// Primary gold — antique, rich. Used for CTAs, accents, active states.
  static const Color gold = Color(0xFF8B6914);

  /// Light gold tint — icon backgrounds, suggestion pill selected bg.
  static const Color goldLight = Color(0xFFF5EDD6);

  /// Dark gold — pressed states, logo on dark bg.
  static const Color goldDark = Color(0xFF6B4F0F);

  // ── Backgrounds ─────────────────────────────────────────────────────────────
  /// Warm parchment — app background.
  static const Color background = Color(0xFFF2EFE9);

  /// Pure white — card surfaces.
  static const Color card = Color(0xFFFFFFFF);

  // ── Text ────────────────────────────────────────────────────────────────────
  /// Near-black warm — primary text, headings.
  static const Color black = Color(0xFF1C1813);

  /// Mid grey — subtitles, captions, placeholders.
  static const Color subtitle = Color(0xFF8A8278);

  // ── Borders & dividers ──────────────────────────────────────────────────────
  static const Color divider = Color(0xFFE8E2D9);

  // ── Semantic colors ─────────────────────────────────────────────────────────
  /// Forest green — positive values, success states.
  static const Color green = Color(0xFF2D6A4F);

  /// Terracotta red — sell context, destructive actions, errors.
  static const Color error = Color(0xFFB5341A);

  /// Muted violet — gift context.
  static const Color violet = Color(0xFF5C3D8F);

  /// Deep navy — delivery context.
  static const Color navy = Color(0xFF1A4A6B);

  // ── Toggle colors ───────────────────────────────────────────────────────────
  static const Color toggleOff = Color(0xFFD4CFC8);

  // ── Warning ─────────────────────────────────────────────────────────────────
  /// Amber — warning snackbars and info banners.
  static const Color warning = Color(0xFFB07D00);

  // ── Quick action icon bg colors ─────────────────────────────────────────────
  static const Color buyIconBg = Color(0xFFE8D99A);
  static const Color sellIconBg = Color(0xFFE8C4BB);
  static const Color giftIconBg = Color(0xFFCFC2E8);
  static const Color deliveryIconBg = Color(0xFFBDD4E5);

  // ── Font families ───────────────────────────────────────────────────────────
  /// Playfair Display Italic — hero numbers, screen titles (serif display).
  static const String serifFont = 'PlayfairDisplay';

  /// Inter — all UI chrome, labels, body text.
  static const String sansFont = 'Inter';

  // ── Spacing ─────────────────────────────────────────────────────────────────
  static const double screenPadding = 16.0;
  static const double sectionGap = 20.0;
  static const double cardRadius = 16.0;
  static const double buttonRadius = 10.0;
  static const double buttonHeight = 52.0;
}
