import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/providers.dart';
import '../../../core/router/router.dart';
import '../../widgets/gold/gold_chart.dart';
import '../../widgets/gold/gold_logo.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _selectedPeriod = '1M';

  String _fmt(double v) =>
      NumberFormat('#,##0', 'sv_SE').format(v).replaceAll(',', ' ');

  @override
  Widget build(BuildContext context) {
    final walletAsync = ref.watch(walletProvider);
    final goldAsync = ref.watch(goldPriceProvider);

    return Scaffold(
      backgroundColor: AppConstants.background,
      body: RefreshIndicator(
        color: AppConstants.gold,
        onRefresh: () async {
          ref.invalidate(walletProvider);
          ref.invalidate(goldPriceProvider);
        },
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.screenPadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                _buildTopBar(),
                const SizedBox(height: 28),
                _buildPortfolioHero(walletAsync, goldAsync),
                const SizedBox(height: 20),
                _buildChartCard(),
                const SizedBox(height: AppConstants.sectionGap),
                _buildHoldingsBar(walletAsync, goldAsync),
                const SizedBox(height: AppConstants.sectionGap),
                _buildQuickActions(),
                const SizedBox(height: AppConstants.sectionGap),
                _buildMarketBanner(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const GoldLogo(size: LogoSize.medium),
        _iconCircle(Icons.notifications_outlined,
            () => context.push(Routes.notifications)),
      ],
    );
  }

  Widget _iconCircle(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppConstants.card,
          shape: BoxShape.circle,
          border: Border.all(color: AppConstants.divider, width: 1),
        ),
        child: Icon(icon, size: 18, color: AppConstants.black),
      ),
    );
  }

  Widget _buildPortfolioHero(walletAsync, goldAsync) {
    final wallet = walletAsync.value;
    final gold = goldAsync.value;
    final goldValue = (wallet?.goldGrams ?? 0) * (gold?.pricePerGramSek ?? 0);
    final cashBalance = wallet?.balanceSek ?? 0;
    final totalValue = goldValue + cashBalance;
    final grams = wallet?.goldGrams ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MITT GULD',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppConstants.subtitle,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 6),
        walletAsync.isLoading || goldAsync.isLoading
            ? Container(
                height: 48,
                width: 200,
                decoration: BoxDecoration(
                  color: AppConstants.divider,
                  borderRadius: BorderRadius.circular(8),
                ),
              )
            : Text(
                '${_fmt(totalValue)} kr',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 40,
                  fontStyle: FontStyle.italic,
                  color: AppConstants.black,
                  height: 1.1,
                ),
              ),
        const SizedBox(height: 4),
        Text(
          '${grams.toStringAsFixed(3).replaceAll('.', ',')} g guld',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppConstants.gold,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            const Icon(Icons.trending_up_rounded,
                color: AppConstants.green, size: 16),
            const SizedBox(width: 4),
            Text(
              '+2,47% senaste månaden',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppConstants.green,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChartCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppConstants.card,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        border: Border.all(color: AppConstants.divider, width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'GULD (SPOT)',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppConstants.subtitle,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppConstants.green.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppConstants.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Live',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppConstants.green,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GoldChart(
            selectedPeriod: _selectedPeriod,
            onPeriodChanged: (p) => setState(() => _selectedPeriod = p),
          ),
        ],
      ),
    );
  }

  Widget _buildHoldingsBar(walletAsync, goldAsync) {
    final wallet = walletAsync.value;
    final gold = goldAsync.value;
    final grams = wallet?.goldGrams ?? 0;
    final goldValue = grams * (gold?.pricePerGramSek ?? 0);

    return Container(
      decoration: BoxDecoration(
        color: AppConstants.card,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        border: Border.all(color: AppConstants.divider, width: 1),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'GULD',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppConstants.subtitle,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${grams.toStringAsFixed(3).replaceAll('.', ',')} g',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 22,
                        fontStyle: FontStyle.italic,
                        color: AppConstants.gold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const VerticalDivider(
              width: 1,
              thickness: 1,
              color: AppConstants.divider,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'VÄRDE',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppConstants.subtitle,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_fmt(goldValue)} kr',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 22,
                        fontStyle: FontStyle.italic,
                        color: AppConstants.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SNABBVAL',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppConstants.subtitle,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.7,
          children: [
            _QuickTile(
              icon: Icons.shopping_bag_outlined,
              label: 'KÖP',
              iconBg: AppConstants.buyIconBg,
              iconColor: AppConstants.gold,
              onTap: () => context.push(Routes.buy),
            ),
            _QuickTile(
              icon: Icons.replay_rounded,
              label: 'SÄLJ',
              iconBg: AppConstants.sellIconBg,
              iconColor: AppConstants.error,
              onTap: () => context.push(Routes.sell),
            ),
            _QuickTile(
              icon: Icons.card_giftcard_outlined,
              label: 'GE BORT',
              iconBg: AppConstants.giftIconBg,
              iconColor: AppConstants.violet,
              onTap: () => context.push(Routes.gift),
            ),
            _QuickTile(
              icon: Icons.local_shipping_outlined,
              label: 'LEVERANS',
              iconBg: AppConstants.deliveryIconBg,
              iconColor: AppConstants.navy,
              onTap: () => context.push(Routes.delivery),
              highlighted: true,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMarketBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppConstants.black,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MARKNADSANALYS',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppConstants.gold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Guldet stärks mot dollarn',
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontStyle: FontStyle.italic,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {},
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white54, width: 1),
                borderRadius: BorderRadius.circular(AppConstants.buttonRadius),
              ),
              child: Text(
                'LÄS MER',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconBg;
  final Color iconColor;
  final VoidCallback onTap;
  final bool highlighted;

  const _QuickTile({
    required this.icon,
    required this.label,
    required this.iconBg,
    required this.iconColor,
    required this.onTap,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppConstants.card,
          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
          border: Border.all(
            color: highlighted ? AppConstants.gold : AppConstants.divider,
            width: highlighted ? 1.5 : 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppConstants.black,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
