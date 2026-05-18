import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/models.dart';
import '../../../core/providers/providers.dart';
import '../../../core/router/router.dart';
import '../../../core/utils/web_redirect.dart';
import '../../widgets/gold/live_badge.dart';
import 'card_checkout_sheet.dart';

class BuyRecurringScreen extends ConsumerStatefulWidget {
  const BuyRecurringScreen({super.key});

  @override
  ConsumerState<BuyRecurringScreen> createState() => _BuyRecurringScreenState();
}

class _BuyRecurringScreenState extends ConsumerState<BuyRecurringScreen> {
  // ── Amount ────────────────────────────────────────────────────────────────
  bool _isGramMode = false;
  double _amount = 0; // SEK or grams depending on _isGramMode
  final _amountCtrl = TextEditingController();

  // ── Schedule ──────────────────────────────────────────────────────────────
  String _frequency = 'Weekly';
  String _selectedDay = 'Sun'; // single day for weekly
  int _selectedDate = 1; // day-of-month for monthly

  bool _loading = false;

  static const _weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
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

  void _onAmountChanged(String raw, double pricePerGram) {
    final cleaned = raw.replaceAll(',', '').replaceAll(' ', '');
    final val = double.tryParse(cleaned) ?? 0;
    setState(() => _amount = val);
  }

  String _scheduleLabel() {
    switch (_frequency) {
      case 'Daily':
        return 'Daily';
      case 'Weekly':
        return 'Weekly · $_selectedDay';
      case 'Monthly':
        return 'Monthly · ${_ordinal(_selectedDate)}';
      default:
        return _frequency;
    }
  }

  String _ordinal(int n) {
    if (n >= 11 && n <= 13) return '${n}th';
    switch (n % 10) {
      case 1: return '${n}st';
      case 2: return '${n}nd';
      case 3: return '${n}rd';
      default: return '${n}th';
    }
  }

  Future<void> _onContinue() async {
    final paymentMethod = ref.read(selectedPaymentMethodProvider);
    final goldPrice = ref.read(goldPriceProvider).value;
    if (goldPrice == null) return;

    final amtSek = _amountSek(goldPrice.pricePerGramSek);
    final amtGrams = _amountGrams(goldPrice.pricePerGramSek);

    if (paymentMethod == 'card') {
      if (kIsWeb) {
        setState(() => _loading = true);
        try {
          await _webStripeRedirect(amtSek, amtGrams, goldPrice.pricePerGramSek);
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(e.toString().replaceFirst('Exception: ', '')),
              backgroundColor: AppConstants.error,
            ));
          }
        } finally {
          if (mounted) setState(() => _loading = false);
        }
        return;
      }

      final paid = await showCardCheckout(
        context,
        amountSek: amtSek,
        goldGrams: amtGrams,
        goldPricePerGramSek: goldPrice.pricePerGramSek,
        supabase: ref.read(supabaseProvider),
      );
      if (!paid || !mounted) return;
    }

    setState(() => _loading = true);
    try {
      final days = _frequency == 'Monthly'
          ? ['$_selectedDate']
          : _frequency == 'Weekly'
              ? [_selectedDay]
              : ['daily'];

      await ref.read(goldTransactionServiceProvider).createRecurringSubscription(
            amountSek: amtSek,
            frequency: _frequency,
            selectedDays: days,
            paymentMethod: paymentMethod,
          );
      if (mounted) {
        context.go(Routes.receipt, extra: {
          'type': 'Recurring Buy Setup',
          'amountSek': amtSek,
          'goldGrams': amtGrams,
          'goldPricePerGramSek': goldPrice.pricePerGramSek,
          'frequency': _scheduleLabel(),
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

  Future<void> _webStripeRedirect(
      double amtSek, double amtGrams, double price) async {
    final supabase = ref.read(supabaseProvider);
    final origin = webOrigin;
    final schedule = Uri.encodeComponent(_scheduleLabel());
    final type = Uri.encodeComponent('Recurring Buy Setup');
    final successUrl =
        '$origin/#/receipt?type=$type&amount=$amtSek&grams=$amtGrams&price=$price&paymentMethod=card&frequency=$schedule&success=true';
    final cancelUrl = '$origin/#/buy/recurring';

    final response = await supabase.functions.invoke(
      'create-payment-intent',
      body: {
        'mode': 'web_checkout',
        'amount': amtSek,
        'currency': 'sek',
        'goldGrams': amtGrams,
        'successUrl': successUrl,
        'cancelUrl': cancelUrl,
      },
    );

    final checkoutUrl = response.data?['checkoutUrl'] as String?;
    if (checkoutUrl == null) {
      final err = response.data?['error'] as String?;
      throw Exception(err ?? 'Payment service unavailable');
    }
    redirectToUrl(checkoutUrl);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final goldAsync = ref.watch(goldPriceProvider);
    final pricePerGram = goldAsync.value?.pricePerGramSek ?? 0;

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
                    _buildAmountCard(goldAsync, pricePerGram),
                    const SizedBox(height: 28),
                    _buildSectionLabel('Schedule'),
                    const SizedBox(height: 12),
                    _buildScheduleCard(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            _buildContinueButton(pricePerGram),
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

  Widget _buildSectionLabel(String text) => Text(
        text,
        style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppConstants.black),
      );

  // ── Amount card ───────────────────────────────────────────────────────────

  Widget _buildAmountCard(AsyncValue<GoldPrice> goldAsync, double pricePerGram) {
    final amtSek = _amountSek(pricePerGram);
    final amtGrams = _amountGrams(pricePerGram);

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
          // Header row: Gold label + live price + icon
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
                      error: (_, __) => const SizedBox.shrink(),
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

          // SEK / Grams toggle
          _buildModeToggle(),
          const SizedBox(height: 16),

          // Text input
          _buildAmountInput(pricePerGram),
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

          // Quick suggestions
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
      child: Row(
        children: [
          _modeTab('SEK', !_isGramMode),
          _modeTab('Grams', _isGramMode),
        ],
      ),
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
              color: selected ? AppConstants.black : AppConstants.subtitle,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAmountInput(double pricePerGram) {
    final prefix = _isGramMode ? '' : 'kr.';
    final suffix = _isGramMode ? ' g' : '';
    final hint = _isGramMode ? '0.00' : '0';

    return TextField(
      controller: _amountCtrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
      ],
      onChanged: (v) => _onAmountChanged(v, pricePerGram),
      style: const TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w300,
        color: AppConstants.black,
        letterSpacing: -1,
      ),
      textAlign: TextAlign.center,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w300,
          color: AppConstants.divider,
          letterSpacing: -1,
        ),
        prefixText: prefix,
        prefixStyle: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w300,
            color: AppConstants.subtitle,
            letterSpacing: -1),
        suffixText: suffix,
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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: selected
                  ? AppConstants.gold.withValues(alpha: 0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color:
                    selected ? AppConstants.gold : const Color(0xFFDDDDDD),
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? AppConstants.gold : AppConstants.black,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Schedule card ─────────────────────────────────────────────────────────

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
          if (_frequency == 'Monthly') ...[
            const SizedBox(height: 16),
            _buildDateSelector(),
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
                              color:
                                  AppConstants.gold.withValues(alpha: 0.3),
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
                    color:
                        selected ? Colors.white : AppConstants.subtitle,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Weekly: single-select day
  Widget _buildDaySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Every',
            style: TextStyle(fontSize: 13, color: AppConstants.subtitle)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: _weekdays.map((day) {
            final selected = _selectedDay == day;
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedDay = day);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: selected ? AppConstants.gold : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected
                        ? AppConstants.gold
                        : const Color(0xFFDDDDDD),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  day,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w400,
                    color: selected ? Colors.white : AppConstants.black,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // Monthly: date 1–28 in a scrollable grid
  Widget _buildDateSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('On the',
            style: TextStyle(fontSize: 13, color: AppConstants.subtitle)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(28, (i) {
            final date = i + 1;
            final selected = _selectedDate == date;
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedDate = date);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: selected ? AppConstants.gold : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected
                        ? AppConstants.gold
                        : const Color(0xFFDDDDDD),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$date',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w400,
                    color: selected ? Colors.white : AppConstants.black,
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 6),
        const Text(
          'Dates after the 28th are skipped in shorter months.',
          style: TextStyle(fontSize: 11, color: AppConstants.subtitle),
        ),
      ],
    );
  }

  // ── Continue button ───────────────────────────────────────────────────────

  Widget _buildContinueButton(double pricePerGram) {
    final enabled = _amount > 0 && !_loading &&
        (_isGramMode ? true : _amount >= 1);
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
}
