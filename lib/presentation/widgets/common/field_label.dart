import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';

class FieldLabel extends StatelessWidget {
  final String text;
  const FieldLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppConstants.black,
      ),
    );
  }
}
