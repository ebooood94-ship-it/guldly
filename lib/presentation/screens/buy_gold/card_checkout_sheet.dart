import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:guldly/core/constants/app_constants.dart';
import 'package:intl/intl.dart';
import '../../../core/services/stripe_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Shows the card checkout bottom sheet and returns true if payment succeeded.
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
  final _cardCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _cvcCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  bool get _isValid =>
      _cardCtrl.text.replaceAll(' ', '').length == 16 &&
      _expiryCtrl.text.length == 5 &&
      _cvcCtrl.text.length >= 3 &&
      _nameCtrl.text.trim().isNotEmpty;

  Future<void> _pay() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final paid = await StripeService.pay(
        amountSek: widget.amountSek,
        supabase: widget.supabase,
      );
      if (mounted) Navigator.of(context).pop(paid);
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
  void dispose() {
    _cardCtrl.dispose();
    _expiryCtrl.dispose();
    _cvcCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###.##');
    final bottom = MediaQuery.of(context).viewInsets.bottom;

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
            // Handle bar
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
            Row(
              children: [
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
                    Text('Secure payment via Stripe',
                        style: TextStyle(
                            fontSize: 12, color: AppConstants.subtitle)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Order summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppConstants.background,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  _SummaryRow('Gold', '${widget.goldGrams.toStringAsFixed(2)}g'),
                  const SizedBox(height: 8),
                  _SummaryRow('Price/g',
                      'kr.${fmt.format(widget.goldPricePerGramSek)}'),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Divider(height: 1, color: AppConstants.divider),
                  ),
                  _SummaryRow('Total', 'kr.${fmt.format(widget.amountSek)}',
                      bold: true, color: AppConstants.gold),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Card fields
            const Text('Card Details',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.black)),
            const SizedBox(height: 12),

            _CardField(
              label: 'Name on card',
              hint: 'Full Name',
              controller: _nameCtrl,
              inputType: TextInputType.name,
              onChanged: () => setState(() {}),
            ),
            const SizedBox(height: 10),
            _CardField(
              label: 'Card number',
              hint: '1234 5678 9012 3456',
              controller: _cardCtrl,
              inputType: TextInputType.number,
              maxLength: 19,
              formatter: _CardNumberFormatter(),
              onChanged: () => setState(() {}),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _CardField(
                    label: 'Expiry',
                    hint: 'MM/YY',
                    controller: _expiryCtrl,
                    inputType: TextInputType.number,
                    maxLength: 5,
                    formatter: _ExpiryFormatter(),
                    onChanged: () => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _CardField(
                    label: 'CVC',
                    hint: '123',
                    controller: _cvcCtrl,
                    inputType: TextInputType.number,
                    maxLength: 4,
                    obscure: true,
                    onChanged: () => setState(() {}),
                  ),
                ),
              ],
            ),

            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppConstants.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppConstants.error.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: AppConstants.error, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_error!,
                          style: const TextStyle(
                              fontSize: 12, color: AppConstants.error)),
                    ),
                  ],
                ),
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
                  color: (_isValid && !_loading)
                      ? AppConstants.gold
                      : AppConstants.gold.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: (_isValid && !_loading)
                      ? [
                          BoxShadow(
                              color: AppConstants.gold.withValues(alpha: 0.35),
                              blurRadius: 16,
                              offset: const Offset(0, 6))
                        ]
                      : [],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: (_isValid && !_loading) ? _pay : null,
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
                Text('Secured by Stripe',
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
            style: const TextStyle(fontSize: 13, color: AppConstants.subtitle)),
        Text(value,
            style: TextStyle(
                fontSize: 13,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                color: color ?? AppConstants.black)),
      ],
    );
  }
}

class _CardField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final TextInputType inputType;
  final int? maxLength;
  final TextInputFormatter? formatter;
  final bool obscure;
  final VoidCallback onChanged;

  const _CardField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.inputType,
    required this.onChanged,
    this.maxLength,
    this.formatter,
    this.obscure = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12, color: AppConstants.subtitle)),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          keyboardType: inputType,
          obscureText: obscure,
          maxLength: maxLength,
          onChanged: (_) => onChanged(),
          inputFormatters: [if (formatter != null) formatter!],
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                const TextStyle(color: AppConstants.divider, fontSize: 14),
            counterText: '',
            filled: true,
            fillColor: AppConstants.background,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppConstants.divider, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppConstants.gold, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length && i < 16; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    final str = buffer.toString();
    return TextEditingValue(
      text: str,
      selection: TextSelection.collapsed(offset: str.length),
    );
  }
}

class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll('/', '');
    if (digits.length > 4) return oldValue;
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i == 2) buffer.write('/');
      buffer.write(digits[i]);
    }
    final str = buffer.toString();
    return TextEditingValue(
      text: str,
      selection: TextSelection.collapsed(offset: str.length),
    );
  }
}
