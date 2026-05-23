import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/error_utils.dart';

/// Centralised, beautifully styled snackbar helper.
///
/// Usage:
///   AppSnackbar.error(context, e);       // from a catch block
///   AppSnackbar.warning(context, msg);   // user-facing warning
///   AppSnackbar.success(context, msg);   // confirmation
///   AppSnackbar.info(context, msg);      // neutral info
class AppSnackbar {
  AppSnackbar._();

  // ── Public entry points ──────────────────────────────────────────────────

  /// Show an error derived from a caught exception. The message is
  /// automatically cleaned and mapped to a friendly string.
  static void error(BuildContext context, Object exception,
      {Duration duration = const Duration(seconds: 5)}) {
    _show(
      context,
      message: friendlyError(exception),
      icon: Icons.warning_amber_rounded,
      iconColor: AppConstants.warning,
      iconBg: AppConstants.warning.withValues(alpha: 0.15),
      duration: duration,
    );
  }

  /// Show a plain warning with a custom message string.
  static void warning(BuildContext context, String message,
      {Duration duration = const Duration(seconds: 4)}) {
    _show(
      context,
      message: message,
      icon: Icons.warning_amber_rounded,
      iconColor: AppConstants.warning,
      iconBg: AppConstants.warning.withValues(alpha: 0.15),
      duration: duration,
    );
  }

  /// Show a success confirmation.
  static void success(BuildContext context, String message,
      {Duration duration = const Duration(seconds: 3)}) {
    _show(
      context,
      message: message,
      icon: Icons.check_circle_rounded,
      iconColor: AppConstants.green,
      iconBg: AppConstants.green.withValues(alpha: 0.15),
      duration: duration,
    );
  }

  /// Show a neutral info message.
  static void info(BuildContext context, String message,
      {Duration duration = const Duration(seconds: 3)}) {
    _show(
      context,
      message: message,
      icon: Icons.info_outline_rounded,
      iconColor: const Color(0xFF5B9BD5),
      iconBg: const Color(0xFF5B9BD5).withValues(alpha: 0.15),
      duration: duration,
    );
  }

  // ── Internal builder ─────────────────────────────────────────────────────

  static void _show(
    BuildContext context, {
    required String message,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required Duration duration,
  }) {
    // Dismiss any current snackbar first so messages don't stack
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1C1C1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        duration: duration,
        // Disable the default action padding so our close button sits flush
        dismissDirection: DismissDirection.horizontal,
        content: Row(
          children: [
            // ── Icon badge ─────────────────────────────────────────────
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),

            // ── Message ────────────────────────────────────────────────
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ),

            // ── Dismiss button ─────────────────────────────────────────
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () =>
                  ScaffoldMessenger.of(context).hideCurrentSnackBar(),
              child: Container(
                padding: const EdgeInsets.all(4),
                child: const Icon(
                  Icons.close_rounded,
                  color: Color(0xFF999999),
                  size: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
