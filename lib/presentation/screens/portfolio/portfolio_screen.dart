import 'package:flutter/material.dart';
import 'package:guldly/core/constants/app_constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/models/models.dart';
import '../../../core/providers/providers.dart';
import '../../widgets/common/gold_card.dart';

class PortfolioScreen extends ConsumerWidget {
  const PortfolioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletAsync = ref.watch(walletProvider);
    final subsAsync = ref.watch(subscriptionsProvider);
    final goldAsync = ref.watch(goldPriceProvider);

    return Scaffold(
      backgroundColor: AppConstants.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Text('Portfolio',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppConstants.black)),
              const SizedBox(height: 20),
              // Portfolio summary
              walletAsync.when(
                data: (wallet) => goldAsync.when(
                  data: (gold) =>
                      _PortfolioSummary(wallet: wallet, goldPrice: gold),
                  loading: () => const _SummaryCard(
                      value: 'kr.0', grams: '0g', change: '+0%'),
                  error: (_, __) => const _SummaryCard(
                      value: 'kr.0', grams: '0g', change: '+0%'),
                ),
                loading: () => const _SummaryCard(
                    value: 'kr.0', grams: '0g', change: '+0%'),
                error: (_, __) => const _SummaryCard(
                    value: 'kr.0', grams: '0g', change: '+0%'),
              ),
              const SizedBox(height: 20),
              // Deposit vs current value card
              GoldCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Deposit',
                              style: TextStyle(
                                  fontSize: 12, color: AppConstants.subtitle)),
                          const SizedBox(height: 4),
                          walletAsync.when(
                            data: (w) => Text(
                              'kr.${NumberFormat('#,###').format((w?.goldGrams ?? 0) * 350)}',
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w600),
                            ),
                            loading: () => const Text('kr.0'),
                            error: (_, __) => const Text('kr.0'),
                          ),
                        ],
                      ),
                      // Mini chart placeholder
                      SizedBox(
                        width: 80,
                        height: 40,
                        child: CustomPaint(painter: _MiniChartPainter()),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Current value',
                              style: TextStyle(
                                  fontSize: 12, color: AppConstants.subtitle)),
                          const SizedBox(height: 4),
                          walletAsync.when(
                            data: (w) => goldAsync.when(
                              data: (g) => Text(
                                'kr.${NumberFormat('#,###').format((w?.goldGrams ?? 0) * g.pricePerGramSek)}',
                                style: const TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.w600),
                              ),
                              loading: () => const Text('kr.0'),
                              error: (_, __) => const Text('kr.0'),
                            ),
                            loading: () => const Text('kr.0'),
                            error: (_, __) => const Text('kr.0'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              const Text('Active Subscription',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppConstants.black)),
              const SizedBox(height: 12),
              subsAsync.when(
                data: (subs) => subs.isEmpty
                    ? const GoldCard(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Center(
                            child: Text('No active subscriptions',
                                style: TextStyle(color: AppConstants.subtitle)),
                          ),
                        ),
                      )
                    : Column(
                        children: subs
                            .map((s) => _SubscriptionCard(sub: s))
                            .toList()),
                loading: () => const CircularProgressIndicator(),
                error: (e, _) => Text('$e'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _PortfolioSummary extends StatelessWidget {
  final Wallet? wallet;
  final GoldPrice goldPrice;
  const _PortfolioSummary({this.wallet, required this.goldPrice});

  @override
  Widget build(BuildContext context) {
    final value = (wallet?.goldGrams ?? 0) * goldPrice.pricePerGramSek;
    final grams = wallet?.goldGrams ?? 0;
    return _SummaryCard(
      value: 'kr.${NumberFormat('#,###').format(value)}',
      grams: '${grams.toStringAsFixed(1)}g of Gold',
      change: '+2.47%',
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String value;
  final String grams;
  final String change;
  const _SummaryCard(
      {required this.value, required this.grams, required this.change});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('My Portfolio',
            style: TextStyle(fontSize: 14, color: AppConstants.subtitle)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w700,
                color: AppConstants.black,
                letterSpacing: -1)),
        Text(grams,
            style: const TextStyle(
                color: AppConstants.gold,
                fontSize: 15,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Row(children: [
          const Icon(Icons.trending_up_rounded,
              color: AppConstants.green, size: 16),
          const SizedBox(width: 4),
          Text(change,
              style: const TextStyle(
                  color: AppConstants.green, fontWeight: FontWeight.w600)),
          const Text(' vs last month',
              style: TextStyle(color: AppConstants.subtitle, fontSize: 13)),
        ]),
      ],
    );
  }
}

class _SubscriptionCard extends StatelessWidget {
  final Subscription sub;
  const _SubscriptionCard({required this.sub});

  @override
  Widget build(BuildContext context) {
    return GoldCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                        color: AppConstants.gold.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.layers_rounded,
                        color: AppConstants.gold, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${sub.frequency.name[0].toUpperCase()}${sub.frequency.name.substring(1)} Gold Investment',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ]),
                const Icon(Icons.settings_outlined,
                    color: AppConstants.subtitle, size: 20),
              ],
            ),
            const SizedBox(height: 10),
            RichText(
                text: TextSpan(children: [
              TextSpan(
                  text: 'kr.${NumberFormat('#,###').format(sub.amountSek)} ',
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppConstants.black)),
              TextSpan(
                  text: sub.frequency.name,
                  style: const TextStyle(
                      fontSize: 14, color: AppConstants.subtitle)),
            ])),
            const SizedBox(height: 6),
            Text(
              'Schedule: ${_scheduleLabel(sub)}',
              style:
                  const TextStyle(fontSize: 13, color: AppConstants.subtitle),
            ),
            if (sub.nextPaymentDate != null) ...[
              const SizedBox(height: 2),
              Text(
                'Next Payment: ${DateFormat('dd MMM yyyy').format(sub.nextPaymentDate!)}',
                style:
                    const TextStyle(fontSize: 13, color: AppConstants.subtitle),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _scheduleLabel(Subscription sub) {
    switch (sub.frequency) {
      case RecurringFrequency.daily:
        return 'Every day';
      case RecurringFrequency.weekly:
        return sub.daysOfWeek?.join(', ') ?? 'Weekly';
      case RecurringFrequency.monthly:
        return 'First of each month';
    }
  }
}

class _MiniChartPainter extends CustomPainter {
  static const pts = [0.5, 0.4, 0.6, 0.45, 0.7, 0.65, 0.8];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppConstants.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final path = Path();
    for (var i = 0; i < pts.length; i++) {
      final x = i / (pts.length - 1) * size.width;
      final y = (1 - pts[i]) * size.height;
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}
