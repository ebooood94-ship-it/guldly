import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/providers.dart';
import '../../../core/router/router.dart';
import '../../widgets/gold/gold_chart.dart';
import '../../widgets/gold/gold_logo.dart';
import '../../widgets/gold/icon_btn.dart';
import '../../widgets/gold/portfolio_card.dart';
import '../../widgets/gold/quick_action_btn.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _selectedPeriod = '1M';

  @override
  Widget build(BuildContext context) {
    final walletAsync = ref.watch(walletProvider);
    final goldAsync = ref.watch(goldPriceProvider);

    return Scaffold(
      backgroundColor: AppConstants.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              _buildTopBar(),
              const SizedBox(height: 28),
              _buildPortfolioHeader(walletAsync, goldAsync),
              const SizedBox(height: 24),
              GoldChart(
                selectedPeriod: _selectedPeriod,
                onPeriodChanged: (p) => setState(() => _selectedPeriod = p),
              ),
              const SizedBox(height: 16),
              _buildPortfolioCards(walletAsync, goldAsync),
              const SizedBox(height: 28),
              _buildQuickActions(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Row(
          children: [
            GoldLogo(),
            SizedBox(width: 8),
            Text(
              'Guldly',
              style: TextStyle(
                color: AppConstants.gold,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        Row(
          children: [
            IconBtn(
              icon: isDark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
              onTap: () => ref.read(themeModeProvider.notifier).state =
                  isDark ? ThemeMode.light : ThemeMode.dark,
            ),
            const SizedBox(width: 8),
            IconBtn(
              icon: Icons.notifications_outlined,
              onTap: () => context.push(Routes.notifications),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPortfolioHeader(walletAsync, goldAsync) {
    final wallet = walletAsync.value;
    final gold = goldAsync.value;
    final value = (wallet?.goldGrams ?? 0) * (gold?.pricePerGramSek ?? 0);
    final grams = wallet?.goldGrams ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'My Portfolio',
          style: TextStyle(
            color: AppConstants.subtitle,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 4),
        walletAsync.isLoading || goldAsync.isLoading
            ? Container(
                height: 46,
                width: 180,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
              )
            : Text(
                'kr.${NumberFormat('#,###').format(value)}',
                style: const TextStyle(
                  color: AppConstants.black,
                  fontSize: 38,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1,
                ),
              ),
        const SizedBox(height: 4),
        Text(
          '${grams.toStringAsFixed(1)}g of Gold',
          style: const TextStyle(
            color: AppConstants.gold,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            const Icon(Icons.trending_up_rounded,
                color: AppConstants.green, size: 18),
            const SizedBox(width: 4),
            const Text(
              'Live pricing',
              style: TextStyle(color: AppConstants.subtitle, fontSize: 13),
            ),
            if (gold != null) ...[
              const SizedBox(width: 6),
              Text(
                'kr.${NumberFormat('#,###.##').format(gold.pricePerGramSek)}/g',
                style: const TextStyle(
                  color: AppConstants.green,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildPortfolioCards(walletAsync, goldAsync) {
    final wallet = walletAsync.value;
    final gold = goldAsync.value;
    final grams = wallet?.goldGrams ?? 0;
    final value = grams * (gold?.pricePerGramSek ?? 0);

    return Row(
      children: [
        Expanded(
          child: PortfolioCard(
            backgroundColor: AppConstants.gold,
            label: 'Gold',
            value: '${grams.toStringAsFixed(1)} g',
            textColor: Colors.white,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: PortfolioCard(
            backgroundColor: AppConstants.black,
            label: 'Value',
            value: 'kr.${NumberFormat('#,###').format(value)}',
            textColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppConstants.black,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            QuickActionBtn(
              icon: Icons.shopping_bag_outlined,
              label: 'Buy',
              color: AppConstants.gold,
              onTap: () => context.push('/buy'),
            ),
            QuickActionBtn(
              icon: Icons.replay_rounded,
              label: 'Sell',
              color: const Color(0xFFE74C3C),
              onTap: () => context.push('/sell'),
            ),
            QuickActionBtn(
              icon: Icons.card_giftcard_outlined,
              label: 'Gift',
              color: const Color(0xFF9B59B6),
              onTap: () => context.push('/gift'),
            ),
            QuickActionBtn(
              icon: Icons.local_shipping_outlined,
              label: 'Delivery',
              color: const Color(0xFF3498DB),
              onTap: () => context.push('/delivery'),
            ),
          ],
        ),
      ],
    );
  }
}
