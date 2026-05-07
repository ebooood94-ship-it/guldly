import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';

class MenuRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const MenuRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 22, color: AppConstants.black),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: AppConstants.black)),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: AppConstants.subtitle)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: AppConstants.subtitle, size: 20),
          ],
        ),
      ),
    );
  }
}
