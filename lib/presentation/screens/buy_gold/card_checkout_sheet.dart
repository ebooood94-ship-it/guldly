import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:guldly/core/constants/app_constants.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _stripePublishableKey =
    'pk_test_51TUpnp5YGUKTIsY7CugQwPteWhQm1sFJJLnmS0IzWAYt7BrNqdOxQ0FaMWT6rkmOgtbDHpyvXs9I1lUlIXI0ceQh00FT57ufJh';

/// Shows the checkout order summary, then collects payment.
/// Returns true when payment succeeds.
Future<bool> showCardCheckout(
  BuildContext context, {
  required double amountSek,
  required double goldGrams,
  required double goldPricePerGramSek,
  required SupabaseClient supabase,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _CardCheckoutSheet(
      amountSek: amountSek,
      goldGrams: goldGrams,
      goldPricePerGramSek: goldPricePerGramSek,
      supabase: supabase,
    ),
  );
  return result ?? false;
}

class _CardCheckoutSheet extends StatefulWidget {
  final double amountSek;
  final double goldGrams;
  final double goldPricePerGramSek;
  final SupabaseClient supabase;

  const _CardCheckoutSheet({
    required this.amountSek,
    required this.goldGrams,
    required this.goldPricePerGramSek,
    required this.supabase,
  });

  @override
  State<_CardCheckoutSheet> createState() => _CardCheckoutSheetState();
}

class _CardCheckoutSheetState extends State<_CardCheckoutSheet> {
  final _nameCtrl = TextEditingController();
  CardFieldInputDetails? _cardDetails;
  bool _loading = false;
  String? _error;

  bool get _cardComplete => _cardDetails?.complete == true;

  /// On web we need name + complete card. On mobile the payment sheet handles it.
  bool get _canPay =>
      !_loading &&
      (!kIsWeb || (_cardComplete && _nameCtrl.text.trim().isNotEmpty));

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<String> _fetchClientSecret() async {
    final response = await widget.supabase.functions.invoke(
      'create-payment-intent',
      body: {'amount': widget.amountSek, 'currency': 'sek'},
    );
    final secret = response.data?['clientSecret'] as String?;
    if (secret == null) {
      final err = response.data?['error'] as String?;
      throw Exception(err ?? 'Payment service unavailable');
    }
    return secret;
  }

  Future<void> _pay() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      Stripe.publishableKey = _stripePublishableKey;

      if (kIsWeb) {
        // ── Web ──────────────────────────────────────────────────────────
        // CardField renders Stripe Elements iframes — no raw card data ever
        // leaves the browser. createPaymentMethod tokenises via Stripe.js.
        final clientSecret = await _fetchClientSecret();

        final pm = await Stripe.instance.createPaymentMethod(
          params: PaymentMethodParams.card(
            paymentMethodData: PaymentMethodData(
              billingDetails: BillingDetails(name: _nameCtrl.text.trim()),
            ),
          ),
        );

        // Confirm the PaymentIntent server-side (secret key, no restrictions)
        final response = await widget.supabase.functions.invoke(
          'create-payment-intent',
          body: {
            'clientSecret': clientSecret,
            'paymentMethodId': pm.id,
          },
        );

        final data = response.data as Map<String, dynamic>?;
        if (data == null) throw Exception('Payment service unavailable');
        if (data['error'] != null) throw Exception(data['error'] as String);

        if (mounted) Navigator.of(context).pop(data['succeeded'] == true);
      } else {
        // ── Mobile ───────────────────────────────────────────────────────
        // presentPaymentSheet shows Stripe's native card UI.
        final clientSecret = await _fetchClientSecret();

        await Stripe.instance.initPaymentSheet(
          paymentSheetParameters: SetupPaymentSheetParameters(
            paymentIntentClientSecret: clientSecret,
            merchantDisplayName: 'Guldly',
            appearance: const PaymentSheetAppearance(
              colors: PaymentSheetAppearanceColors(
                primary: AppConstants.gold,
              ),
            ),
          ),
        );

        await Stripe.instance.presentPaymentSheet();
        if (mounted) Navigator.of(context).pop(true);
      }
    } on StripeException catch (e) {
      if (e.error.code == FailureCode.Canceled) {
        if (mounted) setState(() => _loading = false);
      } else {
        if (mounted) {
          setState(() {
            _error = e.error.localizedMessage ?? 'Payment failed';
            _loading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final fmt = NumberFormat('#,###.##');

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppConstants.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Header
            Row(children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppConstants.gold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.credit_card_rounded,
                    color: AppConstants.gold, size: 22),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Checkout',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppConstants.black)),
                  Text('Secured by Stripe',
                      style: TextStyle(
                          fontSize: 12, color: AppConstants.subtitle)),
                ],
              ),
            ]),
            const SizedBox(height: 20),

            // Order summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppConstants.background,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(children: [
                _SummaryRow(
                    'Gold', '${widget.goldGrams.toStringAsFixed(4)}g'),
                const SizedBox(height: 8),
                _SummaryRow('Price per gram',
                    'kr.${fmt.format(widget.goldPricePerGramSek)}'),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Divider(height: 1, color: AppConstants.divider),
                ),
                _SummaryRow(
                  'Total',
                  'kr.${fmt.format(widget.amountSek)}',
                  bold: true,
                  color: AppConstants.gold,
                ),
              ]),
            ),

            // Web: Stripe Elements card fields
            if (kIsWeb) ...[
              const SizedBox(height: 20),
              const Text('Name on card',
                  style: TextStyle(
                      fontSize: 12, color: AppConstants.subtitle)),
              const SizedBox(height: 5),
              TextField(
                controller: _nameCtrl,
                keyboardType: TextInputType.name,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Full Name',
                  hintStyle: const TextStyle(
                      color: Color(0xFFCCCCCC), fontSize: 14),
                  filled: true,
                  fillColor: AppConstants.background,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 14),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: AppConstants.divider, width: 1)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: AppConstants.gold, width: 1.5)),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Card details',
                  style: TextStyle(
                      fontSize: 12, color: AppConstants.subtitle)),
              const SizedBox(height: 5),
              // CardField renders Stripe's own iframes — PCI compliant,
              // no raw card data exposed to our app code.
              CardField(
                onCardChanged: (details) =>
                    setState(() => _cardDetails = details),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppConstants.background,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 14),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: AppConstants.divider, width: 1)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: AppConstants.gold, width: 1.5)),
                ),
              ),
            ] else ...[
              // Mobile: Stripe payment sheet handles card entry
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppConstants.gold.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(children: [
                  Icon(Icons.lock_outline,
                      size: 16, color: AppConstants.gold),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tap Pay to enter your card details securely via Stripe.',
                      style: TextStyle(
                          fontSize: 12, color: AppConstants.subtitle),
                    ),
                  ),
                ]),
              ),
            ],

            // Error banner
            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppConstants.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppConstants.error.withValues(alpha: 0.2)),
                ),
                child: Row(children: [
                  const Icon(Icons.error_outline,
                      color: AppConstants.error, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_error!,
                        style: const TextStyle(
                            fontSize: 12, color: AppConstants.error)),
                  ),
                ]),
              ),
            ],

            const SizedBox(height: 20),

            // Pay button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: _canPay
                      ? AppConstants.gold
                      : AppConstants.gold.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: _canPay
                      ? [
                          BoxShadow(
                              color:
                                  AppConstants.gold.withValues(alpha: 0.35),
                              blurRadius: 16,
                              offset: const Offset(0, 6))
                        ]
                      : [],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: _canPay ? _pay : null,
                    child: Center(
                      child: _loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              'Pay kr.${NumberFormat('#,###').format(widget.amountSek)}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600),
                            ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline,
                    size: 13, color: AppConstants.subtitle),
                SizedBox(width: 4),
                Text('256-bit SSL encryption · Stripe',
                    style: TextStyle(
                        fontSize: 11, color: AppConstants.subtitle)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? color;
  const _SummaryRow(this.label, this.value,
      {this.bold = false, this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13, color: AppConstants.subtitle)),
        Text(value,
            style: TextStyle(
                fontSize: 13,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                color: color ?? AppConstants.black)),
      ],
    );
  }
}
