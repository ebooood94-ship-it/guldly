import 'package:flutter/material.dart';
import 'package:guldly/core/constants/app_constants.dart';

class GoldLogo extends StatelessWidget {
  final double size;
  const GoldLogo({super.key, this.size = 32});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppConstants.gold,
      ),
      child: Icon(
        Icons.star_rounded,
        color: Colors.white,
        size: size * 0.56,
      ),
    );
  }
}
