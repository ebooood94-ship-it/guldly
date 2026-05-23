import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/providers.dart';
import '../../../core/router/router.dart';
import '../../../core/utils/web_redirect.dart';
import '../../widgets/common/app_snackbar.dart';
import '../../widgets/common/back_header.dart';
import '../../widgets/common/gold_button.dart';
import '../../widgets/common/section_label.dart';
import '../../widgets/common/suggestion_pills.dart';
import 'card_checkout_sheet.dart';

class BuyOnetimeScreen extends ConsumerStatefulWidget {
  const BuyOnetimeScreen({super.key});

  @override
  ConsumerState<BuyOnetimeScreen> createState() => _BuyOnetimeScreenState();
}

class _BuyOnetimeScreenState extends ConsumerState<BuyOnetimeScreen> {
  double _amount = 0;
  String? _selectedPill;
  bool _loading = false;

  static const _sekPills = ['100 kr', '500 kr', '1 000 kr', '5 000 kr'];
  static const _sekValues = [100.0, 500.0, 1000.0, 5000.0];

  double _amountSek() => _amount;
  double _amountGrams(double pricePerGram) =>
      pricePerGram > 0 ? _amount / pricePerGram : 0.0;

  void _selectPill(String label, double value) {
    HapticFeedback.lightImpact();
    setState(() {
      _amount = value;
      _selectedPill = label;
    });
  }

  Future<void> _onContinue(double pricePerGram) async {
    final paymentMethod = ref.read(selectedPaymentMethodProvider);
    final amtSek = _amountSek();
    final amtGrams = _amountGrams(pricePerGram);

    if (paymentMethod == 'card') {
      if (kIsWeb) {
        setState(() => _loading = true);
        try {
          await _webStripeRedirect(amtSek, amtGrams, pricePerGram, 'Buy Gold');
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
      if (mounted) AppSnackbar.error(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _webStripeRedirect(
      double amtSek, double amtGrams, double price, String type) async {
    final supabase = ref.read(supabaseProvider);
    final origin = webOrigin;
    final encodedType = Uri.encodeComponent(type);
    final successUrl =
        '$origin/#/receipt?type=$encodedType&amount=$amtSek&grams=$amtGrams&price=$price&paymentMethod=card&success=true';
    final cancelUrl = '$origin/#/buy/onetime';
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
      throw Exception(
          response.data?['error'] ?? 'Betalningstjänsten ej tillgänglig');
    }
    redirectToUrl(checkoutUrl);
  }

  @override
  Widget build(BuildContext context) {
    final goldAsync = ref.watch(goldPriceProvider);
    final pricePerGram = goldAsync.value?.pricePerGramSek ?? 0.0;
    final amtGrams = _amountGrams(pricePerGram);
    final canContinue = _amount > 0 && !_loading && pricePerGram > 0;

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
                    const SectionLabel('VÄLJ BELOPP'),
                    _buildAmountCard(pricePerGram, amtGrams),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppConstants.screenPadding, 0, AppConstants.screenPadding, 8),
              child: Column(
                children: [
                  GoldButton(
                    label: 'FORTSÄTT',
                    loading: _loading,
                    onPressed: canContinue ? () => _onContinue(pricePerGram) : null,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Säker betalning med Swish eller Bankgiro',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppConstants.subtitle,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountCard(double pricePerGram, double amtGrams) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppConstants.card,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        border: Border.all(color: AppConstants.divider, width: 1),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => _showAmountSheet(context),
            child: Text(
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
          ),
          const SizedBox(height: 6),
          Text(
            '≈ ${amtGrams.toStringAsFixed(4).replaceAll('.', ',')} g guld',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppConstants.subtitle,
            ),
          ),
          const SizedBox(height: 20),
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
            decoration: InputDecoration(
              hintText: '0',
              suffixText: 'kr',
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              hintStyle: GoogleFonts.playfairDisplay(
                fontSize: 36,
                fontStyle: FontStyle.italic,
                color: AppConstants.divider,
              ),
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
