import 'package:flutter/material.dart';
import 'package:guldly/core/constants/app_constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/common/back_header.dart';
import '../../widgets/common/gold_card.dart';
import '../../widgets/common/gold_button.dart';
import '../../../core/providers/providers.dart';
import '../../widgets/common/menu_row.dart';
import '../../widgets/common/gold_text_field.dart';

class SecurityScreen extends ConsumerWidget {
  const SecurityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tips = [
      'Use a strong, unique password for your account',
      'Never share your login credentials with anyone',
      'Keep your account information up to date',
      'Log out from shared or public devices',
      'Enable multi-factor authentication for extra security',
    ];

    return Scaffold(
      backgroundColor: AppConstants.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const BackHeader(title: 'Security'),
              const SizedBox(height: 24),
              GoldCard(
                child: Column(
                  children: [
                    MenuRow(
                        icon: Icons.lock_outline,
                        title: 'Password',
                        subtitle: 'Change your account password',
                        onTap: () => _showChangePassword(context, ref)),
                    const Divider(
                        height: 1,
                        color: AppConstants.divider,
                        indent: 16,
                        endIndent: 16),
                    MenuRow(
                        icon: Icons.security_outlined,
                        title: 'Multi-Factor Authentication',
                        subtitle: 'Add an extra layer of security',
                        onTap: () => _showMfaDialog(context)),
                    const Divider(
                        height: 1,
                        color: AppConstants.divider,
                        indent: 16,
                        endIndent: 16),
                    MenuRow(
                        icon: Icons.devices_outlined,
                        title: 'Login Sessions',
                        subtitle: 'View and manage active sessions',
                        onTap: () => _showSessionsSheet(context, ref)),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              const Text('Security Tips',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppConstants.black)),
              const SizedBox(height: 14),
              ...tips.map((tip) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle_outline,
                            color: AppConstants.green, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                            child: Text(tip,
                                style: const TextStyle(
                                    fontSize: 13, color: AppConstants.black))),
                      ],
                    ),
                  )),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  void _showMfaDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Multi-Factor Authentication'),
        content: const Text(
          'MFA via authenticator app is coming soon. '
          'You\'ll be able to add an extra layer of security to your account.',
          style: TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it',
                style: TextStyle(color: AppConstants.gold)),
          ),
        ],
      ),
    );
  }

  void _showSessionsSheet(BuildContext context, WidgetRef ref) {
    final user = ref.read(currentUserProvider);
    final email = user?.email ?? '—';
    final lastSignIn = user?.lastSignInAt != null
        ? _formatDate(DateTime.parse(user!.lastSignInAt!))
        : '—';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppConstants.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Active Sessions',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppConstants.black)),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppConstants.card,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppConstants.gold.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.phone_android_rounded,
                        color: AppConstants.gold, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('This device',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppConstants.black)),
                        const SizedBox(height: 2),
                        Text(email,
                            style: const TextStyle(
                                fontSize: 12, color: AppConstants.subtitle)),
                        const SizedBox(height: 2),
                        Text('Last active: $lastSignIn',
                            style: const TextStyle(
                                fontSize: 12, color: AppConstants.subtitle)),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppConstants.green.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('Active',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppConstants.green)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  void _showChangePassword(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('New Password',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            GoldTextField(
                label: '',
                hint: 'Enter new password',
                controller: ctrl,
                obscure: true),
            const SizedBox(height: 16),
            GoldButton(
                label: 'Update password',
                onPressed: () async {
                  if (ctrl.text.length < 8) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Password must be at least 8 characters'),
                        backgroundColor: AppConstants.error,
                      ),
                    );
                    return;
                  }
                  try {
                    await ref
                        .read(authNotifierProvider)
                        .updatePassword(ctrl.text);
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Password updated successfully'),
                          backgroundColor: AppConstants.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              e.toString().replaceFirst('Exception: ', '')),
                          backgroundColor: AppConstants.error,
                        ),
                      );
                    }
                  }
                }),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
