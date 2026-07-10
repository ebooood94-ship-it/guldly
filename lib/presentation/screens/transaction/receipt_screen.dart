import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/providers.dart';
import '../../../core/router/router.dart';
import '../../widgets/common/gold_button.dart';

class ReceiptScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> data;
  const ReceiptScreen({super.key, required this.data});

  @override
  ConsumerState<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends ConsumerState<ReceiptScreen> {
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    if (widget.data['fromStripeRedirect'] == true) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _syncAfterStripePayment());
    }
  }

  // Card payments are credited server-side by the stripe-webhook edge
  // function — the client records nothing (previously this screen credited
  // straight from URL parameters, which anyone could forge). Wait for the
  // session to restore after the redirect, give the webhook a moment to
  // land, then refresh the wallet.
  Future<void> _syncAfterStripePayment() async {
    if (!mounted) return;
    setState(() => _syncing = true);
    final supabase = ref.read(supabaseProvider);
    for (var i = 0; i < 20; i++) {
      if (!mounted) return;
      if (supabase.auth.currentSession != null) break;
      await Future.delayed(const Duration(milliseconds: 300));
    }
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    ref.invalidate(walletProvider);
    ref.invalidate(transactionsProvider);
    setState(() => _syncing = false);
  }

  @override
  Widget build(BuildContext context) {
    final type = widget.data['type'] as String? ?? 'Transaktion';
    final amountSek = (widget.data['amountSek'] as num?)?.toDouble() ?? 0;
    final goldGrams = (widget.data['goldGrams'] as num?)?.toDouble();
    final goldPrice = (widget.data['goldPricePerGramSek'] as num?)?.toDouble();
    final recipientName = widget.data['recipientName'] as String?;
    final recipientEmail = widget.data['recipientEmail'] as String?;
    final deliveryAddress = widget.data['deliveryAddress'] as String?;
    final paymentMethod = widget.data['paymentMethod'] as String?;
    final frequency = widget.data['frequency'] as String?;
    final fromStripe = widget.data['fromStripeRedirect'] == true;
    final giftPending = widget.data['giftStatus'] == 'pending';

    if (fromStripe && _syncing) {
      return Scaffold(
        backgroundColor: AppConstants.background,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppConstants.gold),
              const SizedBox(height: 16),
              Text('Bekräftar betalning…',
                  style: GoogleFonts.inter(
                      color: AppConstants.subtitle, fontSize: 14)),
            ],
          ),
        ),
      );
    }

    final fmtSek = NumberFormat('#,##0', 'sv_SE')
        .format(amountSek)
        .replaceAll(',', ' ');

    return Scaffold(
      backgroundColor: AppConstants.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 56),
                    Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        color: AppConstants.green.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_rounded,
                          color: AppConstants.green, size: 48),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _localizeType(type),
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppConstants.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      giftPending
                          ? 'Gåvan väntar på mottagaren'
                          : 'Transaktion bekräftad',
                      style: GoogleFonts.inter(
                          fontSize: 14, color: AppConstants.subtitle),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 28),
                      decoration: BoxDecoration(
                        color: AppConstants.goldLight,
                        borderRadius:
                            BorderRadius.circular(AppConstants.cardRadius),
                        border: Border.all(
                            color: AppConstants.gold.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '$fmtSek kr',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 40,
                              fontStyle: FontStyle.italic,
                              color: AppConstants.gold,
                              height: 1.0,
                            ),
                          ),
                          if (goldGrams != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              '${goldGrams.toStringAsFixed(4).replaceAll('.', ',')} g guld',
                              style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: AppConstants.subtitle),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    _ReceiptCard(
                      children: [
                        if (goldPrice != null)
                          _ReceiptRow(
                            label: 'Guldpris',
                            value:
                                '${NumberFormat('#,##0', 'sv_SE').format(goldPrice).replaceAll(',', ' ')} kr/g',
                          ),
                        if (frequency != null)
                          _ReceiptRow(label: 'Frekvens', value: frequency),
                        if (paymentMethod != null)
                          _ReceiptRow(
                            label: 'Betalning',
                            value: _formatPaymentMethod(paymentMethod),
                          ),
                        if (recipientName != null)
                          _ReceiptRow(
                              label: 'Mottagare', value: recipientName),
                        if (recipientEmail != null)
                          _ReceiptRow(label: 'E-post', value: recipientEmail),
                        if (deliveryAddress != null)
                          _ReceiptRow(
                              label: 'Leverans till',
                              value: deliveryAddress),
                        _ReceiptRow(
                          label: 'Datum',
                          value: DateFormat('d MMM yyyy · HH:mm')
                              .format(DateTime.now()),
                        ),
                      ],
                    ),
                    if (giftPending) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppConstants.giftIconBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppConstants.violet
                                  .withValues(alpha: 0.25)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.schedule_rounded,
                                color: AppConstants.violet, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '${recipientName ?? 'Mottagaren'} är inte Guldly-användare ännu. '
                                'Guldet levereras automatiskt när hen registrerar sig med denna e-postadress.',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  height: 1.4,
                                  color: AppConstants.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: GoldButton(
                label: 'KLAR',
                onPressed: () {
                  ref.invalidate(walletProvider);
                  ref.invalidate(transactionsProvider);
                  context.go(Routes.home);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _localizeType(String type) {
    switch (type) {
      case 'Buy Gold':
        return 'Köp guld';
      case 'Sell Gold':
        return 'Sälj guld';
      case 'Add Funds':
        return 'Insättning';
      case 'Gift Sent':
        return 'Gåva skickad';
      case 'Recurring Buy Setup':
        return 'Automatiskt köp';
      case 'Delivery Requested':
        return 'Leverans beställd';
      default:
        return type;
    }
  }

  String _formatPaymentMethod(String method) {
    switch (method) {
      case 'wallet':
        return 'Plånbok';
      case 'card':
        return 'Bankkort';
      case 'bank':
        return 'Banköverföring';
      default:
        return method;
    }
  }
}

class _ReceiptCard extends StatelessWidget {
  final List<Widget> children;
  const _ReceiptCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppConstants.card,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        border: Border.all(color: AppConstants.divider, width: 1),
      ),
      child: Column(
        children: children.asMap().entries.map((e) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: e.value,
              ),
              if (e.key < children.length - 1)
                const Divider(
                    height: 1,
                    thickness: 1,
                    color: AppConstants.divider),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  final String label;
  final String value;
  const _ReceiptRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 13, color: AppConstants.subtitle)),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppConstants.black,
            ),
          ),
        ),
      ],
    );
  }
}
