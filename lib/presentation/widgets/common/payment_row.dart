import 'package:flutter/material.dart';
import 'package:guldly/core/constants/app_constants.dart';

class PaymentRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool showCardLogos;
  final String value;
  final String groupValue;
  final ValueChanged<String> onChanged;
  final bool showDivider;
  const PaymentRow(
      {super.key, required this.icon,
      required this.title,
      this.subtitle,
      this.showCardLogos = false,
      required this.value,
      required this.groupValue,
      required this.onChanged,
      required this.showDivider});

  @override
  Widget build(BuildContext context) {
    final sel = value == groupValue;
    return GestureDetector(
      onTap: () => onChanged(value),
      behavior: HitTestBehavior.opaque,
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(children: [
            Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                    color: const Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: AppConstants.subtitle, size: 22)),
            const SizedBox(width: 14),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppConstants.black)),
                  if (subtitle != null)
                    Text(subtitle!,
                        style: const TextStyle(
                            fontSize: 12, color: AppConstants.subtitle)),
                  if (showCardLogos)
                    Row(
                        children: ['VISA', 'MC', 'AMEX']
                            .map((l) => Container(
                                  margin:
                                      const EdgeInsets.only(right: 4, top: 4),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 5, vertical: 2),
                                  decoration: BoxDecoration(
                                      border: Border.all(
                                          color: const Color(0xFFDDDDDD)),
                                      borderRadius: BorderRadius.circular(4)),
                                  child: Text(l,
                                      style: const TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800)),
                                ))
                            .toList()),
                ])),
            AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: sel ? AppConstants.gold : const Color(0xFFCCCCCC),
                      width: sel ? 6 : 2),
                )),
          ]),
        ),
        if (showDivider)
          const Divider(
              height: 1,
              color: AppConstants.divider,
              indent: 16,
              endIndent: 16),
      ]),
    );
  }
}
