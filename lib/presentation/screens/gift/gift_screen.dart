import 'package:flutter/material.dart';
import 'package:guldly/core/constants/app_constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/common/back_header.dart';
import '../../widgets/common/gold_text_field.dart';
import 'package:intl/intl.dart';
import '../../widgets/common/field_label.dart';
import '../../widgets/common/projection_row.dart';
import '../../../core/providers/providers.dart';
import '../../../core/router/router.dart';
import '../../widgets/common/gold_card.dart';
import '../../widgets/common/gold_button.dart';
import '../../widgets/common/tab_button.dart';

class GiftScreen extends ConsumerStatefulWidget {
  const GiftScreen({super.key});

  @override
  ConsumerState<GiftScreen> createState() => _GiftScreenState();
}

class _GiftScreenState extends ConsumerState<GiftScreen> {
  bool _isSEK = false;
  double _grams = 0;
  int _amountSek = 0;
  bool _loading = false;
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  static const _gramSuggestions = [15.0, 31.0, 62.0, 155.0];
  static const _sekSuggestions = [100, 250, 500, 1000];

  Future<void> _onContinue(double goldPricePerGramSek) async {
    if (_nameCtrl.text.trim().isEmpty || _emailCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in recipient details'),
          backgroundColor: AppConstants.error,
        ),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(goldTransactionServiceProvider).sendGift(
            amountSek: _amountSek.toDouble(),
            goldGrams: _grams,
            recipientName: _nameCtrl.text.trim(),
            recipientEmail: _emailCtrl.text.trim(),
            goldPricePerGramSek: goldPricePerGramSek,
            isSEKMode: _isSEK,
          );
      if (mounted) {
        final effectiveAmountSek = _isSEK
            ? _amountSek.toDouble()
            : _grams * goldPricePerGramSek;
        final effectiveGrams = _isSEK
            ? _amountSek / goldPricePerGramSek
            : _grams;
        context.go(Routes.receipt, extra: {
          'type': 'Gift Sent',
          'amountSek': effectiveAmountSek,
          'goldGrams': effectiveGrams,
          'goldPricePerGramSek': goldPricePerGramSek,
          'recipientName': _nameCtrl.text.trim(),
          'recipientEmail': _emailCtrl.text.trim(),
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
    final walletAsync = ref.watch(walletProvider);
    final goldAsync = ref.watch(goldPriceProvider);

    return Scaffold(
      backgroundColor: AppConstants.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            const BackHeader(title: 'Gift'),
            const SizedBox(height: 16),
            // SEK / Gold toggle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F0F0),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(children: [
                  Expanded(
                      child: TabButton(
                          label: 'SEK',
                          selected: _isSEK,
                          onTap: () => setState(() => _isSEK = true))),
                  Expanded(
                      child: TabButton(
                          label: 'Gold',
                          selected: !_isSEK,
                          onTap: () => setState(() => _isSEK = false))),
                ]),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Amount',
                        style: TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w700)),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text('Gold',
                                          style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14)),
                                      walletAsync.when(
                                        data: (w) => Text(
                                            'Avl Au = ${(w?.goldGrams ?? 0).toStringAsFixed(1)}g',
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: AppConstants.subtitle)),
                                        loading: () => const Text('Loading...'),
                                        error: (_, __) =>
                                            const Text('Avl Au = 0g'),
                                      ),
                                    ]),
                                Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                        color: AppConstants.gold
                                            .withValues(alpha: 0.12),
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                    child: const Icon(Icons.layers_rounded,
                                        color: AppConstants.gold, size: 20)),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Center(
                                child: Column(children: [
                              Text(
                                _isSEK
                                    ? 'kr.${_amountSek == 0 ? '0' : NumberFormat('#,###').format(_amountSek)}'
                                    : '${_grams == 0 ? '0' : _grams.toStringAsFixed(1)}g',
                                style: const TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w300,
                                    color: AppConstants.subtitle,
                                    letterSpacing: -1),
                              ),
                              goldAsync.when(
                                data: (g) => Text(
                                  _isSEK
                                      ? '≈${(_amountSek / g.pricePerGramSek).toStringAsFixed(2)}g'
                                      : '≈kr.${NumberFormat('#,###').format(_grams * g.pricePerGramSek)}',
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: AppConstants.subtitle),
                                ),
                                loading: () => const Text('≈kr.0'),
                                error: (_, __) => const Text('≈kr.0'),
                              ),
                            ])),
                            const SizedBox(height: 16),
                            const Align(
                                alignment: Alignment.centerLeft,
                                child: Text('Quick suggestion',
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: AppConstants.subtitle))),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: (_isSEK
                                      ? _sekSuggestions.map((e) => e.toDouble())
                                      : _gramSuggestions)
                                  .map((amt) {
                                final label = _isSEK
                                    ? 'kr.${NumberFormat('#,###').format(amt.toInt())}'
                                    : '${amt.toStringAsFixed(0)}g';
                                final sel = _isSEK
                                    ? _amountSek == amt.toInt()
                                    : _grams == amt;
                                return GestureDetector(
                                  onTap: () => setState(() {
                                    if (_isSEK) {
                                      _amountSek = amt.toInt();
                                    } else {
                                      _grams = amt;
                                    }
                                  }),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: sel
                                          ? const Color(0xFF9B59B6)
                                              .withValues(alpha: 0.12)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                          color: sel
                                              ? const Color(0xFF9B59B6)
                                              : const Color(0xFFDDDDDD)),
                                    ),
                                    child: Text(label,
                                        style: TextStyle(
                                            fontSize: 13,
                                            color: sel
                                                ? const Color(0xFF9B59B6)
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
                    const SizedBox(height: 24),
                    const Text('Recipient Details',
                        style: TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    GoldCard(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(children: [
                          const FieldLabel('Name'),
                          const SizedBox(height: 6),
                          GoldTextField(
                              label: 'Name',
                              hint: 'Enter recipient name here',
                              controller: _nameCtrl),
                          const SizedBox(height: 14),
                          const FieldLabel('Email'),
                          const SizedBox(height: 6),
                          GoldTextField(
                              label: 'Email',
                              hint: 'Enter recipient email here',
                              controller: _emailCtrl,
                              keyboardType: TextInputType.emailAddress),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text('Summary',
                        style: TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    GoldCard(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(children: [
                          ProjectionRow(
                              'Amount',
                              _isSEK
                                  ? 'kr.${NumberFormat('#,###').format(_amountSek)}'
                                  : 'kr.0',
                              AppConstants.black),
                          const SizedBox(height: 8),
                          goldAsync.when(
                            data: (g) => ProjectionRow(
                                'Gold',
                                _isSEK
                                    ? '${(_amountSek / g.pricePerGramSek).toStringAsFixed(2)}g'
                                    : '${_grams.toStringAsFixed(1)}g',
                                AppConstants.black),
                            loading: () => const ProjectionRow(
                                'Gold', '0g', AppConstants.black),
                            error: (_, __) => const ProjectionRow(
                                'Gold', '0g', AppConstants.black),
                          ),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: goldAsync.when(
                data: (g) {
                  final hasAmount = _isSEK ? _amountSek > 0 : _grams > 0;
                  return GoldButton(
                    label: 'Continue',
                    loading: _loading,
                    onPressed: (hasAmount && !_loading)
                        ? () => _onContinue(g.pricePerGramSek)
                        : null,
                  );
                },
                loading: () =>
                    const GoldButton(label: 'Continue', onPressed: null),
                error: (_, __) =>
                    const GoldButton(label: 'Continue', onPressed: null),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
