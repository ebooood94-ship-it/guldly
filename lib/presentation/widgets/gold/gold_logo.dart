import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_constants.dart';

enum LogoSize { small, medium, large }

class GoldLogo extends StatelessWidget {
  final LogoSize size;
  const GoldLogo({super.key, this.size = LogoSize.medium});

  @override
  Widget build(BuildContext context) {
    final double ingotW;
    final double ingotH;
    final double fontSize;

    switch (size) {
      case LogoSize.small:
        ingotW = 32;
        ingotH = 11;
        fontSize = 16;
      case LogoSize.medium:
        ingotW = 44;
        ingotH = 15;
        fontSize = 20;
      case LogoSize.large:
        ingotW = 80;
        ingotH = 27;
        fontSize = 28;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: ingotW,
          height: ingotH,
          decoration: BoxDecoration(
            color: AppConstants.gold,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Guldly',
          style: GoogleFonts.inter(
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            color: AppConstants.gold,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }
}
