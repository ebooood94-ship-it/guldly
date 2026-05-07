import 'package:flutter/material.dart';

class PortfolioCard extends StatelessWidget {
  final Color backgroundColor;
  final String label;
  final String value;
  final Color textColor;

  const PortfolioCard({
    super.key,
    required this.backgroundColor,
    required this.label,
    required this.value,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
                color: textColor.withValues(alpha: 0.85), fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}
