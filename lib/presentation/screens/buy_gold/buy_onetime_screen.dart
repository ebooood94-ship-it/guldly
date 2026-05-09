import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/providers.dart';
import '../../../core/router/router.dart';
import '../../../core/services/stripe_service.dart';
import '../../widgets/common/back_header.dart';
import '../../widgets/common/gold_button.dart';
import '../../widgets/common/gold_card.dart';
import '../../widgets/gold/live_badge.dart';

class BuyOnetimeScreen extends ConsumerStatefulWidget {
  const BuyOnetimeScreen({super.key});

  @override
  ConsumerState<BuyOnetimeScreen> createState() => _BuyOnetimeScreenState();
}

class _BuyOnetimeScreenState extends ConsumerState<BuyOnetimeScreen> {
  int _amountKr = 0;
  bool _loading = false;
  static const List<int> _suggestions = [100, 250, 500, 1000, 2500, 5000];

  void _tap(int amount) {
    HapticFeedback.lightImpact();
    setState(() => _amountKr = amount);
  }

  Future<void> _onContinue(double pricePerGramSek) async {
    final paymentMethod = ref.read(selectedPaymentMethodProvider);
    setState(() => _loading = true);
    try {
      if (paymentMethod == 'card') {
        final paid = await StripeService.pay(
          amountSek: _amountKr.toDouble(),
          supabase: ref.read(supabaseProvider),
        );
        if (!paid) return; // user cancelled — no error shown
      }
      await ref.read(goldTransactionServiceProvider).buyGoldOnetime(
            amountSek: _amountKr.toDouble(),
            goldGrams: _amountKr / pricePerGramSek,
            goldPricePerGramSek: pricePerGramSek,
            paymentMethod: paymentMethod,
          );
      if (mounted) {
        context.go(Routes.receipt, extra: {
          'type': 'Buy Gold',
          'amountSek': _amountKr.toDouble(),
          'goldGrams': _amountKr / pricePerGramSek,
          'goldPricePerGramSek': pricePerGramSek,
          'paymentMethod': paymentMethod,
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppConstants.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final goldAsync = ref.watch(goldPriceProvider);
    final pricePerGramSek = goldAsync.value?.pricePerGramSek ?? 0;
    final grams = pricePerGramSek > 0 ? _amountKr / pricePerGramSek : 0.0;
    final gramsLabel = grams == 0 ? '≈0g' : '≈${grams.toStringAsFixed(2)}g';

    return Scaffold(
      backgroundColor: AppConstants.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            const BackHeader(title: 'Buy gold'),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Amount',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppConstants.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GoldCard(child: _buildAmountContent(goldAsync, gramsLabel)),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: GoldButton(
                label: 'Continue',
                loading: _loading,
                onPressed: (_amountKr > 0 && !_loading && pricePerGramSek > 0)
                    ? () => _onContinue(pricePerGramSek)
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountContent(goldAsync, String gramsLabel) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Gold',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppConstants.black,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      goldAsync.when(
                        data: (g) => Text(
                          'kr.${NumberFormat('#,###.##').format(g.pricePerGramSek)}/g',
                          style: const TextStyle(
                              fontSize: 12, color: AppConstants.subtitle),
                        ),
                        loading: () => const Text('Loading...',
                            style: TextStyle(
                                fontSize: 12, color: AppConstants.subtitle)),
                        error: (_, __) => const Text('—',
                            style: TextStyle(
                                fontSize: 12, color: AppConstants.subtitle)),
                      ),
                      const SizedBox(width: 6),
                      const LiveBadge(),
                    ],
                  ),
                ],
              ),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppConstants.gold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.layers_rounded,
                    color: AppConstants.gold, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Center(
            child: Column(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: ScaleTransition(scale: anim, child: child),
                  ),
                  child: Text(
                    'kr.${_amountKr == 0 ? '0' : NumberFormat('#,###').format(_amountKr)}',
                    key: ValueKey(_amountKr),
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w300,
                      color: AppConstants.subtitle,
                      letterSpacing: -1,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  gramsLabel,
                  style: const TextStyle(
                      fontSize: 13, color: AppConstants.subtitle),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Quick suggestion',
            style: TextStyle(fontSize: 13, color: AppConstants.subtitle),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _suggestions.map((amt) {
              final selected = _amountKr == amt;
              return GestureDetector(
                onTap: () => _tap(amt),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppConstants.gold.withValues(alpha: 0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected
                          ? AppConstants.gold
                          : const Color(0xFFDDDDDD),
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Text(
                    'kr.${NumberFormat('#,###').format(amt)}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.w400,
                      color:
                          selected ? AppConstants.gold : AppConstants.black,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
