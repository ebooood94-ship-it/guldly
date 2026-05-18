import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/models.dart';
import '../../../core/providers/providers.dart';
import '../../../core/router/router.dart';
import 'card_checkout_sheet.dart';
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
  bool _isGramMode = false;
  double _amount = 0;
  final _amountCtrl = TextEditingController();
  bool _loading = false;

  static const _sekSuggestions = [100.0, 250.0, 500.0, 1000.0, 2500.0, 5000.0];
  static const _gramSuggestions = [0.1, 0.25, 0.5, 1.0, 2.5, 5.0];

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  double _amountSek(double pricePerGram) =>
      _isGramMode ? _amount * pricePerGram : _amount;

  double _amountGrams(double pricePerGram) =>
      _isGramMode ? _amount : (pricePerGram > 0 ? _amount / pricePerGram : 0);

  void _selectSuggestion(double value) {
    HapticFeedback.lightImpact();
    setState(() {
      _amount = value;
      _amountCtrl.text = _isGramMode
          ? value.toString().replaceAll(RegExp(r'\.?0+$'), '')
          : value.toInt().toString();
    });
  }

  void _onAmountChanged(String raw) {
    final cleaned = raw.replaceAll(',', '').replaceAll(' ', '');
    setState(() => _amount = double.tryParse(cleaned) ?? 0);
  }

  Future<void> _onContinue(double pricePerGram) async {
    final paymentMethod = ref.read(selectedPaymentMethodProvider);
    final amtSek = _amountSek(pricePerGram);
    final amtGrams = _amountGrams(pricePerGram);

    if (paymentMethod == 'card') {
      final paid = await showCardCheckout(
        context,
        amountSek: amtSek,
        goldGrams: amtGrams,
        goldPricePerGramSek: pricePerGram,
        supabase: ref.read(supabaseProvider),
      );
      if (!paid || !mounted) return;
    }

    setState(() => _loading = true);
    try {
      await ref.read(goldTransactionServiceProvider).buyGoldOnetime(
            amountSek: amtSek,
            goldGrams: amtGrams,
            goldPricePerGramSek: pricePerGram,
            paymentMethod: paymentMethod,
          );
      if (mounted) {
        context.go(Routes.receipt, extra: {
          'type': 'Buy Gold',
          'amountSek': amtSek,
          'goldGrams': amtGrams,
          'goldPricePerGramSek': pricePerGram,
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
    final pricePerGram = goldAsync.value?.pricePerGramSek ?? 0;
    final amtSek = _amountSek(pricePerGram);
    final amtGrams = _amountGrams(pricePerGram);
    final canContinue = _amount > 0 && !_loading && pricePerGram > 0;

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
                    GoldCard(
                        child: _buildAmountContent(
                            goldAsync, pricePerGram, amtSek, amtGrams)),
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
                onPressed:
                    canContinue ? () => _onContinue(pricePerGram) : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountContent(AsyncValue<GoldPrice> goldAsync,
      double pricePerGram, double amtSek, double amtGrams) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Gold label + live price + icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Gold',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppConstants.black)),
                  const SizedBox(height: 3),
                  Row(children: [
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
                  ]),
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
          const SizedBox(height: 16),

          // SEK / Grams mode toggle
          _buildModeToggle(),
          const SizedBox(height: 16),

          // Freeform amount input
          _buildAmountInput(),
          const SizedBox(height: 8),

          // Conversion hint
          if (_amount > 0 && pricePerGram > 0)
            Center(
              child: Text(
                _isGramMode
                    ? '≈ kr.${NumberFormat('#,###.##').format(amtSek)}'
                    : '≈ ${amtGrams.toStringAsFixed(4)}g',
                style: const TextStyle(
                    fontSize: 13, color: AppConstants.subtitle),
              ),
            ),
          const SizedBox(height: 16),

          const Text('Quick suggestion',
              style: TextStyle(fontSize: 13, color: AppConstants.subtitle)),
          const SizedBox(height: 10),
          _buildSuggestionChips(),
        ],
      ),
    );
  }

  Widget _buildModeToggle() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(children: [
        _modeTab('SEK', !_isGramMode),
        _modeTab('Grams', _isGramMode),
      ]),
    );
  }

  Widget _modeTab(String label, bool selected) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() {
            _isGramMode = label == 'Grams';
            _amount = 0;
            _amountCtrl.clear();
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: selected
                ? [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 4,
                        offset: const Offset(0, 1))
                  ]
                : [],
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color:
                  selected ? AppConstants.black : AppConstants.subtitle,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAmountInput() {
    return TextField(
      controller: _amountCtrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
      ],
      onChanged: _onAmountChanged,
      style: const TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w300,
        color: AppConstants.black,
        letterSpacing: -1,
      ),
      textAlign: TextAlign.center,
      decoration: InputDecoration(
        hintText: _isGramMode ? '0.00' : '0',
        hintStyle: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w300,
          color: AppConstants.divider,
          letterSpacing: -1,
        ),
        prefixText: _isGramMode ? '' : 'kr.',
        prefixStyle: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w300,
            color: AppConstants.subtitle,
            letterSpacing: -1),
        suffixText: _isGramMode ? ' g' : '',
        suffixStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w300,
            color: AppConstants.subtitle),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        counterText: '',
      ),
    );
  }

  Widget _buildSuggestionChips() {
    final suggestions =
        _isGramMode ? _gramSuggestions : _sekSuggestions;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: suggestions.map((val) {
        final selected = _amount == val;
        final label = _isGramMode
            ? '${val}g'.replaceAll(RegExp(r'\.?0+g$'), 'g')
            : 'kr.${NumberFormat('#,###').format(val.toInt())}';
        return GestureDetector(
          onTap: () => _selectSuggestion(val),
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
              label,
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
    );
  }
}
