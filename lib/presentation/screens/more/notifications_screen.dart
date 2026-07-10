import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/models.dart';
import '../../../core/providers/providers.dart';
import '../../widgets/common/back_header.dart';
import '../../widgets/common/info_banner.dart';
import '../../widgets/common/section_label.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefsAsync = ref.watch(notificationPrefsProvider);

    return Scaffold(
      backgroundColor: AppConstants.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const BackHeader(title: 'Aviseringar'),
              const SizedBox(height: 16),
              prefsAsync.when(
                data: (prefs) => prefs == null
                    ? Center(
                        child: Text('Inga inställningar hittades.',
                            style: GoogleFonts.inter(
                                color: AppConstants.subtitle, fontSize: 14)),
                      )
                    : _NotifBody(prefs: prefs),
                loading: () => const Center(
                    child: CircularProgressIndicator(color: AppConstants.gold)),
                error: (e, _) => Text('$e',
                    style: GoogleFonts.inter(
                        color: AppConstants.error, fontSize: 13)),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotifBody extends ConsumerWidget {
  final NotificationPreferences prefs;
  const _NotifBody({required this.prefs});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void update(NotificationPreferences updated) {
      ref.read(notificationPrefsProvider.notifier).update(updated);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Honest state: none of these channels deliver yet — there is no
        // push (FCM/APNs), email, or SMS integration. The toggles only
        // persist a preference to notification_preferences, which will be
        // honoured once delivery is built. See NotificationService.
        const InfoBanner(
          'Aviseringar levereras inte ännu – varken push, e-post eller SMS. '
          'Dina val sparas och börjar gälla så snart vi aktiverar leverans.',
          variant: BannerVariant.warning,
        ),
        const SizedBox(height: AppConstants.sectionGap),
        const SectionLabel('PUSH-NOTISER (KOMMER SNART)'),
        _NotifCard(items: [
          _NotifItem(
            'Prisaviseringar',
            'Prisförändringar och tröskelvärden',
            prefs.pushPriceAlerts,
            (v) => update(prefs.copyWith(pushPriceAlerts: v)),
          ),
          _NotifItem(
            'Transaktionsuppdateringar',
            'Status för köp, försäljningar och gåvor',
            prefs.pushTransactionUpdates,
            (v) => update(prefs.copyWith(pushTransactionUpdates: v)),
          ),
          _NotifItem(
            'Erbjudanden',
            'Kampanjer och erbjudanden',
            prefs.pushPromotions,
            (v) => update(prefs.copyWith(pushPromotions: v)),
          ),
        ]),
        const SizedBox(height: AppConstants.sectionGap),
        const SectionLabel('E-POSTAVISERINGAR (KOMMER SNART)'),
        _NotifCard(items: [
          _NotifItem(
            'Veckorapporter',
            'Sammanfattning av din veckoaktivitet',
            prefs.emailWeeklyReports,
            (v) => update(prefs.copyWith(emailWeeklyReports: v)),
          ),
          _NotifItem(
            'Månadsutdrag',
            'Sammanfattning av din månadsaktivitet',
            prefs.emailMonthlyStatements,
            (v) => update(prefs.copyWith(emailMonthlyStatements: v)),
          ),
          _NotifItem(
            'Säkerhetsaviseringar',
            'Varningar vid säkerhetsproblem',
            prefs.emailSecurityAlerts,
            (v) => update(prefs.copyWith(emailSecurityAlerts: v)),
          ),
          _NotifItem(
            'Produktuppdateringar',
            'Håll dig informerad om nya funktioner',
            prefs.emailProductUpdates,
            (v) => update(prefs.copyWith(emailProductUpdates: v)),
          ),
        ]),
        const SizedBox(height: AppConstants.sectionGap),
        const SectionLabel('SMS-AVISERINGAR (KOMMER SNART)'),
        _NotifCard(items: [
          _NotifItem(
            'Aktivera SMS',
            'Ta emot uppdateringar via SMS',
            prefs.smsEnabled,
            (v) => update(prefs.copyWith(smsEnabled: v)),
          ),
          _NotifItem(
            'Transaktioner via SMS',
            'SMS-aviseringar för transaktioner',
            prefs.smsTransactionUpdates,
            (v) => update(prefs.copyWith(smsTransactionUpdates: v)),
          ),
        ]),
      ],
    );
  }
}

class _NotifCard extends StatelessWidget {
  final List<_NotifItem> items;
  const _NotifCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppConstants.card,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        border: Border.all(color: AppConstants.divider, width: 1),
      ),
      child: Column(
        children: items.asMap().entries.map((e) {
          final item = e.value;
          final isLast = e.key == items.length - 1;
          return Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.title,
                              style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppConstants.black)),
                          Text(item.subtitle,
                              style: GoogleFonts.inter(
                                  fontSize: 12, color: AppConstants.subtitle)),
                        ],
                      ),
                    ),
                    Switch(
                      value: item.value,
                      onChanged: item.onChanged,
                      activeThumbColor: AppConstants.gold,
                    ),
                  ],
                ),
              ),
              if (!isLast)
                const Divider(
                    height: 1,
                    thickness: 1,
                    color: AppConstants.divider,
                    indent: 16,
                    endIndent: 16),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _NotifItem {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _NotifItem(this.title, this.subtitle, this.value, this.onChanged);
}
