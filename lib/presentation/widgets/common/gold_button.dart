import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';

class GoldButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  const GoldButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: AppConstants.gold,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppConstants.gold.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: loading
            ? const CircularProgressIndicator(
                color: Colors.white, strokeWidth: 2)
            : Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
