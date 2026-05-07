import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
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
              _buildPortfolioHeader(),
              const SizedBox(height: 24),
              GoldChart(
                selectedPeriod: _selectedPeriod,
                onPeriodChanged: (p) => setState(() => _selectedPeriod = p),
              ),
              const SizedBox(height: 16),
              _buildPortfolioCards(),
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
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
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
            IconBtn(icon: Icons.dark_mode_outlined),
            SizedBox(width: 8),
            IconBtn(icon: Icons.notifications_outlined),
          ],
        ),
      ],
    );
  }

  Widget _buildPortfolioHeader() {
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
        const Text(
          'kr.525,000',
          style: TextStyle(
            color: AppConstants.black,
            fontSize: 38,
            fontWeight: FontWeight.w700,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          '487.4g of Gold',
          style: TextStyle(
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
            RichText(
              text: const TextSpan(
                style: TextStyle(fontSize: 13),
                children: [
                  TextSpan(
                    text: '+2.47% (kr12,962.88) ',
                    style: TextStyle(
                      color: AppConstants.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(
                    text: 'vs last month',
                    style: TextStyle(color: AppConstants.subtitle),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPortfolioCards() {
    return const Row(
      children: [
        Expanded(
          child: PortfolioCard(
            backgroundColor: AppConstants.gold,
            label: 'Gold',
            value: '487.4 g',
            textColor: Colors.white,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: PortfolioCard(
            backgroundColor: AppConstants.black,
            label: 'Value',
            value: 'kr.525,000',
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
