import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_constants.dart';

enum GoldButtonVariant { primary, destructive, gift, ghost }

class GoldButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final GoldButtonVariant variant;
  final IconData? icon;

  const GoldButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.variant = GoldButtonVariant.primary,
    this.icon,
  });

  Color get _bgColor {
    switch (variant) {
      case GoldButtonVariant.primary:
        return AppConstants.gold;
      case GoldButtonVariant.destructive:
        return AppConstants.error;
      case GoldButtonVariant.gift:
        return AppConstants.violet;
      case GoldButtonVariant.ghost:
        return Colors.transparent;
    }
  }

  Color get _fgColor {
    if (variant == GoldButtonVariant.ghost) return AppConstants.gold;
    return Colors.white;
  }

  Border? get _border {
    if (variant == GoldButtonVariant.ghost) {
      return Border.all(color: AppConstants.gold, width: 1.5);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null && !loading;
    return GestureDetector(
      onTap: isEnabled ? onPressed : null,
      child: AnimatedOpacity(
        opacity: isEnabled ? 1.0 : 0.45,
        duration: const Duration(milliseconds: 150),
        child: Container(
          height: AppConstants.buttonHeight,
          decoration: BoxDecoration(
            color: _bgColor,
            borderRadius: BorderRadius.circular(AppConstants.buttonRadius),
            border: _border,
          ),
          alignment: Alignment.center,
          child: loading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: _fgColor,
                    strokeWidth: 2,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, color: _fgColor, size: 18),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      label.toUpperCase(),
                      style: GoogleFonts.inter(
                        color: _fgColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
