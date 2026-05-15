import '../../../core/router/router.dart';
import 'package:flutter/material.dart';
import 'package:guldly/core/constants/app_constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/providers.dart';
import '../../../core/models/models.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/common/gold_card.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: AppConstants.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Text('Manage',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppConstants.black)),
              const SizedBox(height: 24),
              // Avatar + name
              Center(
                child: Column(
                  children: [
                    profileAsync.when(
                      data: (UserProfile? profile) => CircleAvatar(
                        backgroundImage: profile?.avatarUrl != null
                            ? NetworkImage(profile!.avatarUrl!)
                            : null,
                        child: profile?.avatarUrl == null
                            ? const Icon(Icons.person_outline,
                                size: 40, color: AppConstants.gold)
                            : null,
                      ),
                      loading: () => const CircleAvatar(radius: 44),
                      error: (_, __) => const CircleAvatar(radius: 44),
                    ),
                    const SizedBox(height: 10),
                    profileAsync.when(
                      data: (UserProfile? p) => Text(
                        p?.fullName ?? 'User',
                        style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppConstants.black),
                      ),
                      loading: () => const Text('Loading...'),
                      error: (_, __) => const Text('User'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              // Quick actions row
              const Text('Quick Actions',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppConstants.black)),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _QuickBtn(
                      icon: Icons.card_giftcard_outlined,
                      label: 'Gift',
                      color: const Color(0xFF9B59B6),
                      onTap: () => context.push(Routes.gift)),
                  _QuickBtn(
                      icon: Icons.replay_rounded,
                      label: 'Sell',
                      color: AppConstants.error,
                      onTap: () => context.push(Routes.sell)),
                  _QuickBtn(
                      icon: Icons.local_shipping_outlined,
                      label: 'Delivery',
                      color: const Color(0xFF3498DB),
                      onTap: () => context.push(Routes.delivery)),
                  _QuickBtn(
                      icon: Icons.calculate_outlined,
                      label: 'Calculate',
                      color: const Color(0xFF3498DB),
                      onTap: () => context.push(Routes.calculator)),
                ],
              ),
              const SizedBox(height: 28),
              // Account section
              const Text('Account',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppConstants.black)),
              const SizedBox(height: 12),
              GoldCard(
                child: Column(
                  children: [
                    _MenuRow(
                        icon: Icons.person_outline,
                        title: 'Profile',
                        subtitle: 'Manage your personal information',
                        onTap: () => context.push(Routes.profile)),
                    const Divider(
                        height: 1,
                        color: AppConstants.divider,
                        indent: 16,
                        endIndent: 16),
                    _MenuRow(
                        icon: Icons.shield_outlined,
                        title: 'Security',
                        subtitle: 'Secure your account access',
                        onTap: () => context.push(Routes.security)),
                    const Divider(
                        height: 1,
                        color: AppConstants.divider,
                        indent: 16,
                        endIndent: 16),
                    _MenuRow(
                        icon: Icons.notifications_outlined,
                        title: 'Notifications',
                        subtitle: 'Manage your notification preferences',
                        onTap: () => context.push(Routes.notifications)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text('Support',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppConstants.black)),
              const SizedBox(height: 12),
              GoldCard(
                child: Column(
                  children: [
                    _MenuRow(
                        icon: Icons.help_outline,
                        title: 'Help & Support',
                        subtitle: 'Get help with your account',
                        onTap: () => _showSupportSheet(context)),
                    const Divider(
                        height: 1,
                        color: AppConstants.divider,
                        indent: 16,
                        endIndent: 16),
                    _MenuRow(
                        icon: Icons.logout,
                        title: 'Sign out',
                        subtitle: 'Sign out of your account',
                        onTap: () async {
                          await ref.read(authNotifierProvider).signOut();
                        }),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

void _showSupportSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
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
          const Text(
            'Help & Support',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppConstants.black),
          ),
          const SizedBox(height: 16),
          const _SupportItem(
            icon: Icons.email_outlined,
            title: 'Email us',
            subtitle: 'support@guldly.se',
          ),
          const SizedBox(height: 12),
          const _SupportItem(
            icon: Icons.chat_bubble_outline,
            title: 'FAQ',
            subtitle: 'Answers to common questions',
          ),
          const SizedBox(height: 12),
          const _SupportItem(
            icon: Icons.policy_outlined,
            title: 'Terms & Privacy',
            subtitle: 'guldly.se/legal',
          ),
        ],
      ),
    ),
  );
}

class _SupportItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _SupportItem({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppConstants.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppConstants.gold.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppConstants.gold, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppConstants.black)),
              Text(subtitle,
                  style: const TextStyle(
                      fontSize: 12, color: AppConstants.subtitle)),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickBtn(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  color: AppConstants.subtitle,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _MenuRow(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 22, color: AppConstants.black),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: AppConstants.black)),
                  Text(subtitle,
                      style: const TextStyle(
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
