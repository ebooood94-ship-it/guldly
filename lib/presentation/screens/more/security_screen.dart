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
                        onTap: () {}),
                    const Divider(
                        height: 1,
                        color: AppConstants.divider,
                        indent: 16,
                        endIndent: 16),
                    MenuRow(
                        icon: Icons.devices_outlined,
                        title: 'Login Sessions',
                        subtitle: 'View and manage active sessions',
                        onTap: () {}),
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
                  await ref
                      .read(authNotifierProvider)
                      .updatePassword(ctrl.text);
                  if (context.mounted) Navigator.pop(context);
                }),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
