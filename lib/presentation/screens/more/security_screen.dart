import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/providers.dart';
import '../../widgets/common/app_snackbar.dart';
import '../../widgets/common/back_header.dart';
import '../../widgets/common/gold_button.dart';
import '../../widgets/common/gold_text_field.dart';
import '../../widgets/common/section_label.dart';

class SecurityScreen extends ConsumerWidget {
  const SecurityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const tips = [
      'Använd ett starkt, unikt lösenord för ditt konto.',
      'Dela aldrig dina inloggningsuppgifter med någon.',
      'Håll dina kontouppgifter uppdaterade.',
      'Logga ut från delade eller offentliga enheter.',
      'Aktivera tvåstegsverifiering för extra säkerhet.',
    ];

    return Scaffold(
      backgroundColor: AppConstants.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const BackHeader(title: 'Säkerhet'),
              const SizedBox(height: 16),
              const SectionLabel('KONTOSÄKERHET'),
              Container(
                decoration: BoxDecoration(
                  color: AppConstants.card,
                  borderRadius:
                      BorderRadius.circular(AppConstants.cardRadius),
                  border: Border.all(color: AppConstants.divider, width: 1),
                ),
                child: Column(
                  children: [
                    _SecurityRow(
                      icon: Icons.lock_outline,
                      title: 'Lösenord',
                      subtitle: 'Ändra ditt kontolösenord',
                      onTap: () => _showChangePassword(context, ref),
                    ),
                    const Divider(
                        height: 1,
                        thickness: 1,
                        color: AppConstants.divider,
                        indent: 16,
                        endIndent: 16),
                    _SecurityRow(
                      icon: Icons.security_outlined,
                      title: 'Tvåstegsverifiering',
                      subtitle: 'Lägg till ett extra skyddslager',
                      onTap: () => _showMfaDialog(context),
                    ),
                    const Divider(
                        height: 1,
                        thickness: 1,
                        color: AppConstants.divider,
                        indent: 16,
                        endIndent: 16),
                    _SecurityRow(
                      icon: Icons.devices_outlined,
                      title: 'Inloggningssessioner',
                      subtitle: 'Visa och hantera aktiva sessioner',
                      onTap: () => _showSessionsSheet(context, ref),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppConstants.sectionGap),
              const SectionLabel('SÄKERHETSTIPS'),
              ...tips.map((tip) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle_outline,
                            color: AppConstants.green, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(tip,
                              style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: AppConstants.black,
                                  height: 1.4)),
                        ),
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
        backgroundColor: AppConstants.card,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.cardRadius)),
        title: Text('Tvåstegsverifiering',
            style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppConstants.black)),
        content: Text(
          'Tvåstegsverifiering via autentiseringsapp kommer snart. '
          'Du kommer att kunna lägga till ett extra skyddslager för ditt konto.',
          style: GoogleFonts.inter(fontSize: 13, color: AppConstants.subtitle),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Förstår',
                style: GoogleFonts.inter(
                    color: AppConstants.gold, fontWeight: FontWeight.w600)),
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
      backgroundColor: AppConstants.card,
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
            Text('Aktiva sessioner',
                style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppConstants.black)),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppConstants.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppConstants.divider),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppConstants.goldLight,
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
                        Text('Den här enheten',
                            style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppConstants.black)),
                        Text(email,
                            style: GoogleFonts.inter(
                                fontSize: 12, color: AppConstants.subtitle)),
                        Text('Senast aktiv: $lastSignIn',
                            style: GoogleFonts.inter(
                                fontSize: 12, color: AppConstants.subtitle)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppConstants.green.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('Aktiv',
                        style: GoogleFonts.inter(
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
    const months = [
      'jan', 'feb', 'mar', 'apr', 'maj', 'jun',
      'jul', 'aug', 'sep', 'okt', 'nov', 'dec'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  void _showChangePassword(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppConstants.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          left: 20,
          right: 20,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nytt lösenord',
                style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppConstants.black)),
            const SizedBox(height: 16),
            GoldTextField(
              label: 'LÖSENORD',
              hint: 'Minst 8 tecken',
              controller: ctrl,
              obscure: true,
            ),
            const SizedBox(height: 16),
            GoldButton(
              label: 'UPPDATERA',
              onPressed: () async {
                if (ctrl.text.length < 8) {
                  AppSnackbar.warning(
                      context, 'Lösenordet måste vara minst 8 tecken.');
                  return;
                }
                try {
                  await ref
                      .read(authNotifierProvider)
                      .updatePassword(ctrl.text);
                  if (context.mounted) {
                    Navigator.pop(context);
                    AppSnackbar.success(
                        context, 'Lösenordet har uppdaterats.');
                  }
                } catch (e) {
                  if (context.mounted) AppSnackbar.error(context, e);
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _SecurityRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SecurityRow({
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppConstants.goldLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppConstants.gold, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppConstants.black)),
                  Text(subtitle,
                      style: GoogleFonts.inter(
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
