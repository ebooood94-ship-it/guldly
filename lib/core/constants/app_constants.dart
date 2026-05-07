import 'package:flutter/material.dart';

class AppConstants {
  // App Info
  static const String appName = 'Guldly';
  static const String appVersion = '1.0.0';

  // Currency
  static const String defaultCurrency = 'SEK';
  static const String currencySymbol = 'kr';

  // Gold
  static const double goldSpread = 0.02; // 2% spread
  static const List<double> quickBuyAmounts = [100, 250, 500, 1000, 2500];
  static const List<double> quickSellAmounts = [10, 25, 50, 100];

  // Payment methods
  static const List<String> paymentMethods = [
    'Wallet Balance',
    'Credit/Debit Card',
    'Bank Transfer'
  ];

  // Recurring purchase options
  static const List<String> recurringFrequencies = [
    'Daily',
    'Weekly',
    'Monthly'
  ];

  // ========== COLOR DEFINITIONS ==========

  // Brand Colors
  static const Color gold = Color(0xFFD4A017);
  static const Color goldLight = Color(0xFFF5C842);
  static const Color goldDark = Color(0xFFB8860B);

  // Neutral Colors
  static const Color black = Color(0xFF111111);
  static const Color subtitle = Color(0xFF888888);
  static const Color background = Color(0xFFF5F5F5);
  static const Color card = Colors.white;
  static const Color divider = Color(0xFFEEEEEE);

  // Status Colors
  static const Color green = Color(0xFF2ECC71);
  static const Color error = Color(0xFFF44336);
  static const Color warning = Color(0xFFFF9800);

  // Legacy Colors (keep for backward compatibility)
  static const Color primaryColor = Color(0xFFFFB74D);
  static const Color secondaryColor = Color(0xFFFFA726);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color errorColor = Color(0xFFF44336);

  // Splash Screen
  static const Color splashBg = Color(0xFFF7F7F5);
}
