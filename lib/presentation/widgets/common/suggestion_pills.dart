import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_constants.dart';

enum PillContext { gold, sell, gift, neutral }

class SuggestionPills extends StatelessWidget {
  final List<String> labels;
  final String? selected;
  final ValueChanged<String> onTap;
  final PillContext pillContext;

  const SuggestionPills({
    super.key,
    required this.labels,
    required this.selected,
    required this.onTap,
    this.pillContext = PillContext.gold,
  });

  Color get _selectedBg {
    switch (pillContext) {
      case PillContext.gold:
        return AppConstants.gold;
      case PillContext.sell:
        return AppConstants.error;
      case PillContext.gift:
        return AppConstants.violet;
      case PillContext.neutral:
        return AppConstants.black;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: labels.map((label) {
        final isSelected = label == selected;
        return GestureDetector(
          onTap: () => onTap(label),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? _selectedBg : AppConstants.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? _selectedBg : AppConstants.divider,
                width: 1,
              ),
            ),
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? Colors.white : AppConstants.black,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
