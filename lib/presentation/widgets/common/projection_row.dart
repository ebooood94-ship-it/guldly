import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';

class ProjectionRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const ProjectionRow(this.label, this.value, this.valueColor, {super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 14, color: AppConstants.subtitle)),
        Text(value,
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600, color: valueColor)),
      ],
    );
  }
}
