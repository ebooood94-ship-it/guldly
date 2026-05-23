import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/providers.dart';
import '../../../core/router/router.dart';
import '../../widgets/gold/gold_logo.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final profile = profileAsync.value;
    final name = profile?.fullName ?? '';
    final email = ref.read(currentUserProvider)?.email ?? '';
    final initials = name.trim().isEmpty
        ? '?'
        : name.trim().split(' ').map((w) => w[0]).take(2).join().toUpperCase();

    return Scaffold(
      backgroundColor: AppConstants.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const GoldLogo(size: LogoSize.small),
                  GestureDetector(
                    onTap: () => context.push(Routes.notifications),
                    child: const Icon(Icons.notifications_outlined,
                        size: 22, color: AppConstants.black),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildProfileHeader(initials, name, email),
              const SizedBox(height: AppConstants.sectionGap),
              _buildQuickActions(context),
              const SizedBox(height: AppConstants.sectionGap),
              _buildSectionLabel('KONTO'),
              _buildMenuCard(context, ref),
              const SizedBox(height: AppConstants.sectionGap),
              _buildSectionLabel('SUPPORT'),
              _buildSupportCard(context, ref),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(String initials, String name, String email) {
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppConstants.goldLight,
            shape: BoxShape.circle,
            border: Border.all(color: AppConstants.gold, width: 1.5),
          ),
          child: Center(
            child: Text(
              initials,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppConstants.gold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (name.isNotEmpty)
                Text(
                  name,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.black,
                  ),
                ),
              if (email.isNotEmpty)
                Text(
                  email,
                  style: GoogleFonts.inter(
                      fontSize: 13, color: AppConstants.subtitle),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppConstants.subtitle,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _QuickAction(
          icon: Icons.card_giftcard_outlined,
          label: 'Gåva',
          bg: AppConstants.giftIconBg,
          color: AppConstants.violet,
          onTap: () => context.push(Routes.gift),
        ),
        _QuickAction(
          icon: Icons.trending_down_rounded,
          label: 'Sälj',
          bg: AppConstants.sellIconBg,
          color: AppConstants.error,
          onTap: () => context.push(Routes.sell),
        ),
        _QuickAction(
          icon: Icons.local_shipping_outlined,
          label: 'Leverans',
          bg: AppConstants.deliveryIconBg,
          color: AppConstants.navy,
          onTap: () => context.push(Routes.delivery),
        ),
        _QuickAction(
          icon: Icons.calculate_outlined,
          label: 'Kalkylator',
          bg: AppConstants.buyIconBg,
          color: AppConstants.goldDark,
          onTap: () => context.push(Routes.calculator),
        ),
      ],
    );
  }

  Widget _buildMenuCard(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: AppConstants.card,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        border: Border.all(color: AppConstants.divider, width: 1),
      ),
      child: Column(
        children: [
          _MenuRow(
            icon: Icons.person_outline,
            title: 'Profil',
            subtitle: 'Hantera dina personuppgifter',
            onTap: () => context.push(Routes.profile),
          ),
          const Divider(
              height: 1,
              thickness: 1,
              color: AppConstants.divider,
              indent: 16,
              endIndent: 16),
          _MenuRow(
            icon: Icons.shield_outlined,
            title: 'Säkerhet',
            subtitle: 'Skydda ditt konto',
            onTap: () => context.push(Routes.security),
          ),
          const Divider(
              height: 1,
              thickness: 1,
              color: AppConstants.divider,
              indent: 16,
              endIndent: 16),
          _MenuRow(
            icon: Icons.notifications_outlined,
            title: 'Aviseringar',
            subtitle: 'Hantera dina notiser',
            onTap: () => context.push(Routes.notifications),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportCard(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: AppConstants.card,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        border: Border.all(color: AppConstants.divider, width: 1),
      ),
      child: Column(
        children: [
          _MenuRow(
            icon: Icons.help_outline,
            title: 'Hjälp & support',
            subtitle: 'Kontakta oss eller läs vår FAQ',
            onTap: () => _showSupportSheet(context),
          ),
          const Divider(
              height: 1,
              thickness: 1,
              color: AppConstants.divider,
              indent: 16,
              endIndent: 16),
          _MenuRow(
            icon: Icons.logout_rounded,
            title: 'Logga ut',
            subtitle: 'Avsluta din session',
            iconColor: AppConstants.error,
            onTap: () async {
              await ref.read(authNotifierProvider).signOut();
            },
          ),
        ],
      ),
    );
  }

  void _showSupportSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: AppConstants.card,
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
            Text(
              'Hjälp & support',
              style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppConstants.black),
            ),
            const SizedBox(height: 16),
            const _SupportItem(
                icon: Icons.email_outlined,
                title: 'E-post',
                subtitle: 'support@guldly.se'),
            const SizedBox(height: 10),
            const _SupportItem(
                icon: Icons.chat_bubble_outline,
                title: 'FAQ',
                subtitle: 'Svar på vanliga frågor'),
            const SizedBox(height: 10),
            const _SupportItem(
                icon: Icons.policy_outlined,
                title: 'Villkor & integritet',
                subtitle: 'guldly.se/legal'),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bg;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.bg,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppConstants.subtitle,
            ),
          ),
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
  final Color? iconColor;

  const _MenuRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor,
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
            Icon(icon,
                size: 22, color: iconColor ?? AppConstants.black),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: iconColor ?? AppConstants.black)),
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

class _SupportItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SupportItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppConstants.background,
        borderRadius: BorderRadius.circular(12),
      ),
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
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppConstants.black)),
              Text(subtitle,
                  style: GoogleFonts.inter(
                      fontSize: 12, color: AppConstants.subtitle)),
            ],
          ),
        ],
      ),
    );
  }
}
