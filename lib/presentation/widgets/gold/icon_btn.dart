import 'package:flutter/material.dart';
import 'package:guldly/core/constants/app_constants.dart';

class IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const IconBtn({super.key, required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
            ),
          ],
        ),
        child: Icon(icon, size: 20, color: AppConstants.black),
      ),
    );
  }
}
