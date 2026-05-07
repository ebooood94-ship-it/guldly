import 'package:flutter/material.dart';
import 'package:guldly/core/constants/app_constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/common/back_header.dart';
import '../../../core/models/models.dart';
import '../../../core/providers/providers.dart';
import '../../widgets/common/gold_card.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefsAsync = ref.watch(notificationPrefsProvider);

    return Scaffold(
      backgroundColor: AppConstants.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const BackHeader(title: 'Notification'),
              const SizedBox(height: 24),
              prefsAsync.when(
                data: (prefs) => prefs == null
                    ? const Center(child: Text('No preferences found'))
                    : _NotifBody(prefs: prefs),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('$e'),
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
        _NotifSection(title: 'Push Notifications', items: [
          _NotifItem(
              'Price Alerts',
              'Get price change updates',
              prefs.pushPriceAlerts,
              (v) => update(prefs.copyWith(pushPriceAlerts: v))),
          _NotifItem(
              'Transaction Updates',
              'Stay updated on transactions',
              prefs.pushTransactionUpdates,
              (v) => update(prefs.copyWith(pushTransactionUpdates: v))),
          _NotifItem(
              'Promotions and Offers',
              'Receive the latest promos',
              prefs.pushPromotions,
              (v) => update(prefs.copyWith(pushPromotions: v))),
        ]),
        const SizedBox(height: 20),
        _NotifSection(title: 'Email Notifications', items: [
          _NotifItem(
              'Weekly Reports',
              'Summary of your weekly activity',
              prefs.emailWeeklyReports,
              (v) => update(prefs.copyWith(emailWeeklyReports: v))),
          _NotifItem(
              'Monthly Statements',
              'Summary of your monthly activity',
              prefs.emailMonthlyStatements,
              (v) => update(prefs.copyWith(emailMonthlyStatements: v))),
          _NotifItem(
              'Security Alerts',
              'Alerts for security issues',
              prefs.emailSecurityAlerts,
              (v) => update(prefs.copyWith(emailSecurityAlerts: v))),
          _NotifItem(
              'Product Updates',
              'Stay informed about new features',
              prefs.emailProductUpdates,
              (v) => update(prefs.copyWith(emailProductUpdates: v))),
        ]),
        const SizedBox(height: 20),
        _NotifSection(title: 'SMS Notifications', items: [
          _NotifItem('Enable SMS Notifications', 'Receive updates via text',
              prefs.smsEnabled, (v) => update(prefs.copyWith(smsEnabled: v))),
          _NotifItem(
              'Transaction Updates',
              'SMS alerts for transactions',
              prefs.smsTransactionUpdates,
              (v) => update(prefs.copyWith(smsTransactionUpdates: v))),
        ]),
      ],
    );
  }
}

class _NotifSection extends StatelessWidget {
  final String title;
  final List<_NotifItem> items;
  const _NotifSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppConstants.black)),
        const SizedBox(height: 12),
        GoldCard(
          child: Column(
            children: items.asMap().entries.map((e) {
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(e.value.title,
                                  style: const TextStyle(
                                      fontSize: 14, color: AppConstants.black)),
                              Text(e.value.subtitle,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppConstants.subtitle)),
                            ],
                          ),
                        ),
                        Switch(
                          value: e.value.value,
                          onChanged: e.value.onChanged,
                          activeThumbColor: AppConstants.gold,
                        ),
                      ],
                    ),
                  ),
                  if (e.key < items.length - 1)
                    const Divider(
                        height: 1,
                        color: AppConstants.divider,
                        indent: 16,
                        endIndent: 16),
                ],
              );
            }).toList(),
          ),
        ),
      ],
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
