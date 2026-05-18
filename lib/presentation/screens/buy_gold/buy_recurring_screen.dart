import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/models.dart';
import '../../../core/providers/providers.dart';
import '../../../core/router/router.dart';
import '../../widgets/gold/live_badge.dart';
import 'card_checkout_sheet.dart';

class BuyRecurringScreen extends ConsumerStatefulWidget {
  const BuyRecurringScreen({super.key});

  @override
  ConsumerState<BuyRecurringScreen> createState() => _BuyRecurringScreenState();
}

class _BuyRecurringScreenState extends ConsumerState<BuyRecurringScreen> {
  int _amountKr = 0;
  String _frequency = 'Weekly';
  final Set<String> _selectedDays = {'Sun'};
  bool _loading = false;

  static const _weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  static const _suggestions = [100, 250, 500, 1000, 2500, 5000];

  void _tap(int amount) {
    HapticFeedback.lightImpact();
    setState(() => _amountKr = amount);
  }

  void _toggleDay(String day) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedDays.contains(day)) {
        if (_selectedDays.length > 1) _selectedDays.remove(day);
      } else {
        _selectedDays.add(day);
      }
    });
  }

  Future<void> _onContinue() async {
    final paymentMethod = ref.read(selectedPaymentMethodProvider);
    final goldPrice = ref.read(goldPriceProvider).value;

    // For card payments, collect card details and charge the first instalment
    if (paymentMethod == 'card' && goldPrice != null) {
      final paid = await showCardCheckout(
        context,
        amountSek: _amountKr.toDouble(),
        goldGrams: _amountKr / goldPrice.pricePerGramSek,
        goldPricePerGramSek: goldPrice.pricePerGramSek,
        supabase: ref.read(supabaseProvider),
      );
      if (!paid || !mounted) return;
    }

    setState(() => _loading = true);
    try {
      await ref.read(goldTransactionServiceProvider).createRecurringSubscription(
            amountSek: _amountKr.toDouble(),
            frequency: _frequency,
            selectedDays: _selectedDays.toList(),
            paymentMethod: paymentMethod,
          );
      if (mounted) {
        context.go(Routes.receipt, extra: {
          'type': 'Recurring Buy Setup',
          'amountSek': _amountKr.toDouble(),
          'frequency': '$_frequency · ${_selectedDays.join(', ')}',
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
    final grams =
        (pricePerGramSek > 0 && _amountKr > 0) ? _amountKr / pricePerGramSek : 0.0;
    final gramsLabel = grams == 0 ? '≈0g' : '≈${grams.toStringAsFixed(2)}g';

    return Scaffold(
      backgroundColor: AppConstants.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildTopBar(),
                    const SizedBox(height: 24),
                    _buildSectionLabel('Amount'),
                    const SizedBox(height: 12),
                    _buildAmountCard(goldAsync, gramsLabel),
                    const SizedBox(height: 28),
                    _buildSectionLabel('Schedule'),
                    const SizedBox(height: 12),
                    _buildScheduleCard(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            _buildContinueButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: const Icon(Icons.arrow_back,
                color: AppConstants.black, size: 22),
          ),
        ),
        const Text(
          'Buy gold',
          style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppConstants.black),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: AppConstants.black),
    );
  }

  Widget _buildAmountCard(AsyncValue<GoldPrice> goldAsync, String gramsLabel) {
    return Container(
      decoration: BoxDecoration(
        color: AppConstants.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
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
                  const Text('Gold',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppConstants.black)),
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
                        error: (_, __) => const SizedBox.shrink(),
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
          const SizedBox(height: 18),
          Center(
            child: Column(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: ScaleTransition(scale: anim, child: child)),
                  child: Text(
                    'kr.${_amountKr == 0 ? '0' : _formatAmount(_amountKr)}',
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
                Text(gramsLabel,
                    style: const TextStyle(
                        fontSize: 13, color: AppConstants.subtitle)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('Quick suggestion',
              style: TextStyle(fontSize: 13, color: AppConstants.subtitle)),
          const SizedBox(height: 10),
          _buildSuggestionChips(),
        ],
      ),
    );
  }

  Widget _buildSuggestionChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _suggestions.map((amt) {
        final selected = _amountKr == amt;
        return GestureDetector(
          onTap: () => _tap(amt),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: selected
                  ? AppConstants.gold.withValues(alpha: 0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? AppConstants.gold : const Color(0xFFDDDDDD),
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Text(
              'kr.${_formatAmount(amt)}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? AppConstants.gold : AppConstants.black,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildScheduleCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppConstants.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: Column(
        children: [
          _buildFrequencySelector(),
          if (_frequency == 'Weekly') ...[
            const SizedBox(height: 16),
            _buildDaySelector(),
          ],
        ],
      ),
    );
  }

  Widget _buildFrequencySelector() {
    const freqs = ['Daily', 'Weekly', 'Monthly'];
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: freqs.map((f) {
          final selected = f == _frequency;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _frequency = f);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: selected ? AppConstants.gold : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                              color: AppConstants.gold.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2))
                        ]
                      : [],
                ),
                alignment: Alignment.center,
                child: Text(
                  f,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        selected ? FontWeight.w600 : FontWeight.w400,
                    color: selected ? Colors.white : AppConstants.subtitle,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDaySelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: _weekdays.map((day) {
        final selected = _selectedDays.contains(day);
        return GestureDetector(
          onTap: () => _toggleDay(day),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: selected ? AppConstants.gold : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected ? AppConstants.gold : const Color(0xFFDDDDDD),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              day,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                color: selected ? Colors.white : AppConstants.black,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildContinueButton() {
    final enabled = _amountKr > 0 && !_loading;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: GestureDetector(
        onTap: enabled ? _onContinue : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 54,
          decoration: BoxDecoration(
            color: enabled
                ? AppConstants.gold
                : AppConstants.gold.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(14),
            boxShadow: enabled
                ? [
                    BoxShadow(
                        color: AppConstants.gold.withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6))
                  ]
                : [],
          ),
          alignment: Alignment.center,
          child: _loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                )
              : const Text(
                  'Continue',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600),
                ),
        ),
      ),
    );
  }

  String _formatAmount(int amt) {
    if (amt >= 1000) {
      final s = amt.toString();
      return '${s.substring(0, s.length - 3)},${s.substring(s.length - 3)}';
    }
    return amt.toString();
  }
}
