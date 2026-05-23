import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_constants.dart';

enum BannerVariant { info, warning, error }

class InfoBanner extends StatelessWidget {
  final String text;
  final BannerVariant variant;

  const InfoBanner(this.text, {super.key, this.variant = BannerVariant.info});

  Color get _bg {
    switch (variant) {
      case BannerVariant.info:
        return AppConstants.goldLight;
      case BannerVariant.warning:
        return const Color(0xFFFFF3CD);
      case BannerVariant.error:
        return const Color(0xFFFFEBE8);
    }
  }

  Color get _border {
    switch (variant) {
      case BannerVariant.info:
        return AppConstants.gold.withValues(alpha: 0.3);
      case BannerVariant.warning:
        return const Color(0xFFFFD966).withValues(alpha: 0.5);
      case BannerVariant.error:
        return AppConstants.error.withValues(alpha: 0.3);
    }
  }

  Color get _iconColor {
    switch (variant) {
      case BannerVariant.info:
        return AppConstants.gold;
      case BannerVariant.warning:
        return const Color(0xFFB8860B);
      case BannerVariant.error:
        return AppConstants.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(AppConstants.buttonRadius),
        border: Border.all(color: _border, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: _iconColor, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppConstants.black,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
