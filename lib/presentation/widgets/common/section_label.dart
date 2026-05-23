import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_constants.dart';

class SectionLabel extends StatelessWidget {
  final String text;
  final double bottomPadding;

  const SectionLabel(this.text, {super.key, this.bottomPadding = 12});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppConstants.subtitle,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}
