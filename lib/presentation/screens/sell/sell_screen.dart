import 'package:flutter/material.dart';
import 'package:guldly/core/constants/app_constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/providers.dart';
import '../../widgets/common/gold_card.dart';
import '../../widgets/common/gold_button.dart';
import '../../widgets/common/back_header.dart';
import 'package:intl/intl.dart';

class SellScreen extends ConsumerStatefulWidget {
  const SellScreen({super.key});

  @override
  ConsumerState<SellScreen> createState() => _SellScreenState();
}

class _SellScreenState extends ConsumerState<SellScreen> {
  double _grams = 0;
  static const _suggestions = [10.0, 25.0, 50.0, 100.0];

  @override
  Widget build(BuildContext context) {
    final walletAsync = ref.watch(walletProvider);
    final goldAsync = ref.watch(goldPriceProvider);

    return Scaffold(
      backgroundColor: AppConstants.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            const BackHeader(title: 'Sell Gold'),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Amount',
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppConstants.black)),
                    const SizedBox(height: 12),
                    GoldCard(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Gold',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14)),
                                    walletAsync.when(
                                      data: (w) => Text(
                                          'Avl Au = ${w?.goldGrams.toStringAsFixed(1) ?? 0}g',
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: AppConstants.subtitle)),
                                      loading: () => const Text('Loading...'),
                                      error: (_, __) =>
                                          const Text('Avl Au = 0g'),
                                    ),
                                  ],
                                ),
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: AppConstants.gold
                                        .withValues(alpha: 0.12),
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
                                  Text(
                                    '${_grams == 0 ? '0' : _grams.toStringAsFixed(1)}g',
                                    style: const TextStyle(
                                        fontSize: 40,
                                        fontWeight: FontWeight.w300,
                                        color: AppConstants.subtitle,
                                        letterSpacing: -1),
                                  ),
                                  goldAsync.when(
                                    data: (g) => Text(
                                      '≈kr.${NumberFormat('#,###').format(_grams * g.pricePerGramSek)}',
                                      style: const TextStyle(
                                          fontSize: 13,
                                          color: AppConstants.subtitle),
                                    ),
                                    loading: () => const Text('≈kr.0'),
                                    error: (_, __) => const Text('≈kr.0'),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text('Quick suggestion',
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: AppConstants.subtitle)),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _suggestions.map((amt) {
                                final sel = _grams == amt;
                                return GestureDetector(
                                  onTap: () => setState(() => _grams = amt),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: sel
                                          ? AppConstants.gold
                                              .withValues(alpha: 0.12)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                          color: sel
                                              ? AppConstants.gold
                                              : const Color(0xFFDDDDDD)),
                                    ),
                                    child: Text('${amt.toStringAsFixed(0)}g',
                                        style: TextStyle(
                                            fontSize: 13,
                                            color: sel
                                                ? AppConstants.gold
                                                : AppConstants.black,
                                            fontWeight: sel
                                                ? FontWeight.w600
                                                : FontWeight.w400)),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: GoldButton(
                  label: 'Continue', onPressed: _grams > 0 ? () {} : null),
            ),
          ],
        ),
      ),
    );
  }
}
