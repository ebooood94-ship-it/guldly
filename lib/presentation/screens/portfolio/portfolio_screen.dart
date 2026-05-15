import 'package:flutter/material.dart';
import 'package:guldly/core/constants/app_constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/models/models.dart';
import '../../../core/providers/providers.dart';
import '../../widgets/common/error_view.dart';
import '../../widgets/common/gold_card.dart';

class PortfolioScreen extends ConsumerWidget {
  const PortfolioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletAsync = ref.watch(walletProvider);
    final subsAsync = ref.watch(subscriptionsProvider);
    final goldAsync = ref.watch(goldPriceProvider);
    final txAsync = ref.watch(transactionsProvider);

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
              Consumer(builder: (_, ref, __) {
                final history = ref.watch(goldPriceHistoryProvider);
                if (history.length >= 2) {
                  return SizedBox(
                    height: 40,
                    child: CustomPaint(
                      painter: _MiniChartPainter(history),
                      size: const Size(double.infinity, 40),
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),
              const SizedBox(height: 8),
              walletAsync.when(
                data: (wallet) => goldAsync.when(
                  data: (gold) {
                    final txs = txAsync.value ?? [];
                    final totalInvested = txs
                        .where((t) =>
                            t.type == TransactionType.buy ||
                            t.type == TransactionType.recurringBuy)
                        .fold<double>(0, (sum, t) => sum + t.amountSek);
                    return _PortfolioSummary(
                      wallet: wallet,
                      goldPrice: gold,
                      totalInvested: totalInvested,
                    );
                  },
                  loading: () => const _SummaryCard(
                      value: 'kr.0', grams: '0g', change: '—'),
                  error: (_, __) => const _SummaryCard(
                      value: 'kr.0', grams: '0g', change: '—'),
                ),
                loading: () => const _SummaryCard(
                    value: 'kr.0', grams: '0g', change: '—'),
                error: (_, __) => const _SummaryCard(
                    value: 'kr.0', grams: '0g', change: '—'),
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
                          txAsync.when(
                            data: (txs) {
                              final totalInvested = txs
                                  .where((t) =>
                                      t.type == TransactionType.buy ||
                                      t.type == TransactionType.recurringBuy)
                                  .fold<double>(
                                      0, (sum, t) => sum + t.amountSek);
                              return Text(
                                'kr.${NumberFormat('#,###').format(totalInvested)}',
                                style: const TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.w600),
                              );
                            },
                            loading: () => const Text('kr.0'),
                            error: (_, __) => const Text('kr.0'),
                          ),
                        ],
                      ),
                      Consumer(builder: (_, ref, __) {
                        final h = ref.watch(goldPriceHistoryProvider);
                        return SizedBox(
                          width: 80,
                          height: 40,
                          child: h.length >= 2
                              ? CustomPaint(painter: _MiniChartPainter(h))
                              : const SizedBox.shrink(),
                        );
                      }),
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
                            .map((s) => _SubscriptionCard(
                                  sub: s,
                                  onCancel: () => ref
                                      .read(goldTransactionServiceProvider)
                                      .cancelSubscription(s.id),
                                ))
                            .toList()),
                loading: () => const CircularProgressIndicator(),
                error: (e, _) => ErrorView(error: e),
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
  final double totalInvested;
  const _PortfolioSummary(
      {this.wallet, required this.goldPrice, required this.totalInvested});

  @override
  Widget build(BuildContext context) {
    final value = (wallet?.goldGrams ?? 0) * goldPrice.pricePerGramSek;
    final grams = wallet?.goldGrams ?? 0;

    String changeLabel;
    Color changeColor;
    IconData changeIcon;
    if (totalInvested <= 0) {
      changeLabel = '—';
      changeColor = AppConstants.subtitle;
      changeIcon = Icons.trending_flat_rounded;
    } else {
      final pct = (value - totalInvested) / totalInvested * 100;
      changeLabel = '${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(2)}%';
      changeColor = pct >= 0 ? AppConstants.green : AppConstants.error;
      changeIcon =
          pct >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded;
    }

    return _SummaryCard(
      value: 'kr.${NumberFormat('#,###').format(value)}',
      grams: '${grams.toStringAsFixed(1)}g of Gold',
      change: changeLabel,
      changeColor: changeColor,
      changeIcon: changeIcon,
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String value;
  final String grams;
  final String change;
  final Color changeColor;
  final IconData changeIcon;
  const _SummaryCard({
    required this.value,
    required this.grams,
    required this.change,
    this.changeColor = AppConstants.subtitle,
    this.changeIcon = Icons.trending_flat_rounded,
  });

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
          Icon(changeIcon, color: changeColor, size: 16),
          const SizedBox(width: 4),
          Text(change,
              style: TextStyle(color: changeColor, fontWeight: FontWeight.w600)),
          if (changeColor != AppConstants.subtitle)
            const Text(' vs cost basis',
                style: TextStyle(color: AppConstants.subtitle, fontSize: 13)),
        ]),
      ],
    );
  }
}

class _SubscriptionCard extends StatelessWidget {
  final Subscription sub;
  final Future<void> Function() onCancel;
  const _SubscriptionCard({required this.sub, required this.onCancel});

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
                GestureDetector(
                  onTap: () => _confirmCancel(context),
                  child: const Icon(Icons.settings_outlined,
                      color: AppConstants.subtitle, size: 20),
                ),
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

  void _confirmCancel(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel subscription?'),
        content: const Text(
          'This will stop future automatic gold purchases.',
          style: TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep it'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await onCancel();
            },
            child: const Text('Cancel subscription',
                style: TextStyle(color: AppConstants.error)),
          ),
        ],
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
  final List<double> prices;
  const _MiniChartPainter(this.prices);

  @override
  void paint(Canvas canvas, Size size) {
    if (prices.length < 2) return;
    final min = prices.reduce((a, b) => a < b ? a : b);
    final max = prices.reduce((a, b) => a > b ? a : b);
    final range = max - min == 0 ? 1.0 : max - min;

    final isUp = prices.last >= prices.first;
    final paint = Paint()
      ..color = isUp ? AppConstants.green : AppConstants.error
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final path = Path();
    for (var i = 0; i < prices.length; i++) {
      final x = i / (prices.length - 1) * size.width;
      final y = (1 - (prices[i] - min) / range) * size.height;
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_MiniChartPainter old) => old.prices != prices;
}
