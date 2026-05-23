import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/models.dart';
import '../../../core/providers/providers.dart';
import '../../../core/router/router.dart';
import '../../../core/utils/web_redirect.dart';
import '../../widgets/common/app_snackbar.dart';
import '../../widgets/common/back_header.dart';
import '../../widgets/common/gold_button.dart';
import '../../widgets/common/info_banner.dart';
import '../../widgets/common/section_label.dart';
import '../../widgets/common/suggestion_pills.dart';
import '../../widgets/gold/live_badge.dart';
import 'card_checkout_sheet.dart';

class BuyRecurringScreen extends ConsumerStatefulWidget {
  const BuyRecurringScreen({super.key});

  @override
  ConsumerState<BuyRecurringScreen> createState() => _BuyRecurringScreenState();
}

class _BuyRecurringScreenState extends ConsumerState<BuyRecurringScreen> {
  double _amount = 0;
  final _amountCtrl = TextEditingController();
  String _frequency = 'Månadsvis';
  String _selectedDay = 'Mån';
  bool _loading = false;

  static const _weekdays = ['Mån', 'Tis', 'Ons', 'Tor', 'Fre', 'Lör', 'Sön'];
  static const _sekPills = ['100 kr', '500 kr', '1 000 kr', '5 000 kr'];
  static const _sekValues = [100.0, 500.0, 1000.0, 5000.0];

  String? _selectedPill;

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  double _amountSek(double pricePerGram) => _amount;
  double _amountGrams(double pricePerGram) =>
      pricePerGram > 0 ? _amount / pricePerGram : 0;

  void _selectPill(String label, double value) {
    HapticFeedback.lightImpact();
    setState(() {
      _amount = value;
      _selectedPill = label;
      _amountCtrl.text = value.toInt().toString();
    });
  }

  String _scheduleLabel() {
    switch (_frequency) {
      case 'Dagligen':
        return 'Dagligen';
      case 'Veckovis':
        return 'Veckovis · $_selectedDay';
      default:
        return 'Månadsvis';
    }
  }

  String _nextPurchaseDate() {
    final now = DateTime.now();
    const days = _weekdays;
    if (_frequency == 'Dagligen') {
      final d = now.add(const Duration(days: 1));
      return '${d.day}/${d.month}/${d.year}';
    }
    if (_frequency == 'Veckovis') {
      final idx = days.indexOf(_selectedDay);
      final daysUntil = (idx - now.weekday + 8) % 7;
      final d = now.add(Duration(days: daysUntil == 0 ? 7 : daysUntil));
      return '${d.day}/${d.month}/${d.year}';
    }
    final next = DateTime(now.year, now.month + 1, 1);
    return '${next.day}/${next.month}/${next.year}';
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
          if (mounted) AppSnackbar.error(context, e);
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
      final days = _frequency == 'Månadsvis'
          ? ['1']
          : _frequency == 'Veckovis'
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
      if (mounted) AppSnackbar.error(context, e);
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
      throw Exception(response.data?['error'] ?? 'Betalningstjänsten ej tillgänglig');
    }
    redirectToUrl(checkoutUrl);
  }

  @override
  Widget build(BuildContext context) {
    final goldAsync = ref.watch(goldPriceProvider);
    final pricePerGram = goldAsync.value?.pricePerGramSek ?? 0;
    final amtGrams = pricePerGram > 0 ? _amount / pricePerGram : 0.0;

    return Scaffold(
      backgroundColor: AppConstants.background,
      body: SafeArea(
        child: Column(
          children: [
            const BackHeader(title: 'Köp guld'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.screenPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildAmountCard(goldAsync, amtGrams),
                    const SizedBox(height: AppConstants.sectionGap),
                    const SectionLabel('FREKVENS'),
                    _buildFrequencyCard(),
                    if (_frequency == 'Veckovis') ...[
                      const SizedBox(height: AppConstants.sectionGap),
                      const SectionLabel('VÄLJ DAG'),
                      _buildDaySelector(),
                    ],
                    const SizedBox(height: AppConstants.sectionGap),
                    const InfoBanner(
                      'Automatiska köp sker på valt schema. Du kan pausa eller avbryta när som helst.',
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppConstants.screenPadding, 8, AppConstants.screenPadding, 20),
              child: GoldButton(
                label: 'FORTSÄTT',
                loading: _loading,
                onPressed: _amount > 0 && !_loading ? _onContinue : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountCard(AsyncValue<GoldPrice> goldAsync, double amtGrams) {
    return Container(
      decoration: BoxDecoration(
        color: AppConstants.card,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        border: Border.all(color: AppConstants.divider, width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'GULD',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppConstants.black,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(width: 8),
              const LiveBadge(),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => _showAmountSheet(context),
            child: Column(
              children: [
                Text(
                  _amount > 0
                      ? '${NumberFormat('#,##0', 'sv_SE').format(_amount.toInt()).replaceAll(',', ' ')} kr'
                      : '0 kr',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 48,
                    fontStyle: FontStyle.italic,
                    color: AppConstants.black,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '≈ ${amtGrams.toStringAsFixed(4).replaceAll('.', ',')} g',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppConstants.subtitle,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SuggestionPills(
            labels: _sekPills,
            selected: _selectedPill,
            onTap: (label) {
              final idx = _sekPills.indexOf(label);
              if (idx >= 0) _selectPill(label, _sekValues[idx]);
            },
            pillContext: PillContext.gold,
          ),
        ],
      ),
    );
  }

  void _showAmountSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AmountInputSheet(
        initial: _amount,
        onConfirm: (v) => setState(() {
          _amount = v;
          _selectedPill = null;
        }),
      ),
    );
  }

  Widget _buildFrequencyCard() {
    const freqs = ['Dagligen', 'Veckovis', 'Månadsvis'];
    return Container(
      decoration: BoxDecoration(
        color: AppConstants.card,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        border: Border.all(color: AppConstants.divider, width: 1),
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
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? AppConstants.black : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  f,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
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
    return Container(
      decoration: BoxDecoration(
        color: AppConstants.card,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        border: Border.all(color: AppConstants.divider, width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
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
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: selected ? AppConstants.gold : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? AppConstants.gold : AppConstants.divider,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    day,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                      color: selected ? Colors.white : AppConstants.black,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined,
                  size: 14, color: AppConstants.subtitle),
              const SizedBox(width: 6),
              Text(
                'Nästa köp sker: ${_nextPurchaseDate()}',
                style: GoogleFonts.inter(
                    fontSize: 12, color: AppConstants.subtitle),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AmountInputSheet extends StatefulWidget {
  final double initial;
  final ValueChanged<double> onConfirm;
  const _AmountInputSheet({required this.initial, required this.onConfirm});

  @override
  State<_AmountInputSheet> createState() => _AmountInputSheetState();
}

class _AmountInputSheetState extends State<_AmountInputSheet> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
      text: widget.initial > 0 ? widget.initial.toInt().toString() : '',
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 20,
        right: 20,
        top: 20,
      ),
      decoration: const BoxDecoration(
        color: AppConstants.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _ctrl,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textAlign: TextAlign.center,
            style: GoogleFonts.playfairDisplay(
              fontSize: 36,
              fontStyle: FontStyle.italic,
              color: AppConstants.black,
            ),
            decoration: const InputDecoration(
              hintText: '0',
              suffixText: 'kr',
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
          ),
          const SizedBox(height: 16),
          GoldButton(
            label: 'BEKRÄFTA',
            onPressed: () {
              final v = double.tryParse(_ctrl.text) ?? 0;
              widget.onConfirm(v);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
