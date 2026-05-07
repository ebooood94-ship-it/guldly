import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';

class TabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const TabButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: selected
              ? [const BoxShadow(color: Colors.black12, blurRadius: 4)]
              : [],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? AppConstants.black : AppConstants.subtitle,
          ),
        ),
      ),
    );
  }
}
