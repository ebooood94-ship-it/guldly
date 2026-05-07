import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import 'package:go_router/go_router.dart';

class BackHeader extends StatelessWidget {
  final String title;
  const BackHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () => context.pop(),
              child: const Icon(Icons.arrow_back,
                  color: AppConstants.black, size: 22),
            ),
          ),
          Text(title,
              style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppConstants.black)),
        ],
      ),
    );
  }
}
