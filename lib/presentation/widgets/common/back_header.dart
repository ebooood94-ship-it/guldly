import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_constants.dart';

class BackHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool useSerifTitle;
  final Widget? trailing;

  const BackHeader({
    super.key,
    required this.title,
    this.useSerifTitle = false,
    this.trailing,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final titleStyle = useSerifTitle
        ? GoogleFonts.playfairDisplay(
            fontSize: 22,
            fontStyle: FontStyle.italic,
            color: AppConstants.gold,
            fontWeight: FontWeight.w600,
          )
        : GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppConstants.black,
          );

    return SizedBox(
      height: 56,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.screenPadding),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: () => context.pop(),
                behavior: HitTestBehavior.opaque,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(
                    Icons.arrow_back,
                    color: AppConstants.gold,
                    size: 22,
                  ),
                ),
              ),
            ),
            Text(title, style: titleStyle),
            if (trailing != null)
              Align(
                alignment: Alignment.centerRight,
                child: trailing!,
              ),
          ],
        ),
      ),
    );
  }
}
