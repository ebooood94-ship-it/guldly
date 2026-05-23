import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_constants.dart';

class GoldTextField extends StatelessWidget {
  final String label;
  final String hint;
  final String? suffix;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final bool readOnly;
  final int maxLines;
  final bool obscure;

  const GoldTextField({
    super.key,
    required this.label,
    required this.hint,
    this.suffix,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.onChanged,
    this.readOnly = false,
    this.maxLines = 1,
    this.obscure = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(
            label.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppConstants.subtitle,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
        ],
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          onChanged: onChanged,
          readOnly: readOnly,
          maxLines: maxLines,
          obscureText: obscure,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppConstants.black,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              color: AppConstants.subtitle,
              fontSize: 14,
            ),
            suffixText: suffix,
            suffixStyle: GoogleFonts.inter(
              color: AppConstants.subtitle,
              fontSize: 14,
            ),
            filled: true,
            fillColor: AppConstants.card,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.buttonRadius),
              borderSide: const BorderSide(color: AppConstants.divider, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.buttonRadius),
              borderSide: const BorderSide(color: AppConstants.gold, width: 1.5),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.buttonRadius),
              borderSide: const BorderSide(color: AppConstants.divider, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}
