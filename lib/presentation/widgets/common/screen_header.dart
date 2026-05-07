import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';

class ScreenHeader extends StatelessWidget {
  final String title;
  final List<Widget>? actions;
  const ScreenHeader({super.key, required this.title, this.actions});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: Text(title,
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppConstants.black)),
          ),
          if (actions != null) ...actions!,
        ],
      ),
    );
  }
}
