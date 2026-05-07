import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_constants.dart';

class AppTheme {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppConstants.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppConstants.gold,
        brightness: Brightness.light,
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(),
      appBarTheme: AppBarTheme(
        backgroundColor: AppConstants.background,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: AppConstants.black,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: AppConstants.black),
      ),
    );
  }
}
