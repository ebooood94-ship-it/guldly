import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/providers.dart';
import '../../../core/router/router.dart';

class ReceiptScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> data;
  const ReceiptScreen({super.key, required this.data});

  @override
  ConsumerState<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends ConsumerState<ReceiptScreen> {
  bool _recording = false;

  @override
  void initState() {
    super.initState();
    // When the user returns from Stripe Checkout on web, record the transaction.
    // We wait for Supabase auth to restore the session from localStorage before
    // attempting the RPC — a cold-start redirect means auth may not be ready yet.
    if (widget.data['fromStripeRedirect'] == true) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _waitForAuthThenRecord());
    }
  }

  /// Polls until auth is ready (max ~5 s), then records the transaction.
  Future<void> _waitForAuthThenRecord() async {
    setState(() => _recording = true);
    for (var i = 0; i < 20; i++) {
      final auth = ref.read(authStateProvider);
      final ready = !auth.isLoading && auth.value?.session != null;
      if (ready) {
        await _recordTransaction();
        return;
      }
      await Future.delayed(const Duration(milliseconds: 300));
    }
    // Auth never resolved — show the receipt anyway (Stripe already charged).
    if (mounted) setState(() => _recording = false);
  }

  Future<void> _recordTransaction() async {
    try {
      final amtSek = (widget.data['amountSek'] as num?)?.toDouble() ?? 0;
      final grams = (widget.data['goldGrams'] as num?)?.toDouble() ?? 0;
      final price =
          (widget.data['goldPricePerGramSek'] as num?)?.toDouble() ?? 0;
      final isAddFunds =
          widget.data['addFunds'] == true || widget.data['addFunds'] == 'true';

      final svc = ref.read(goldTransactionServiceProvider);

      if (isAddFunds) {
        await svc.addFunds(amountSek: amtSek, paymentMethod: 'card');
      } else {
        // One-time buy OR first instalment of a recurring setup
        await svc.buyGoldOnetime(
          amountSek: amtSek,
          goldGrams: grams,
          goldPricePerGramSek: price,
          paymentMethod: 'card',
        );
      }

      // Ensure providers refresh even if the service already invalidated them
      ref.invalidate(walletProvider);
      ref.invalidate(transactionsProvider);
    } catch (e) {
      // Non-critical — Stripe payment already succeeded.
      debugPrint('Receipt: failed to record transaction: $e');
    } finally {
      if (mounted) setState(() => _recording = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final type = widget.data['type'] as String? ?? 'Transaction';
    final amountSek = (widget.data['amountSek'] as num?)?.toDouble() ?? 0;
    final goldGrams = (widget.data['goldGrams'] as num?)?.toDouble();
    final goldPrice = (widget.data['goldPricePerGramSek'] as num?)?.toDouble();
    final recipientName = widget.data['recipientName'] as String?;
    final recipientEmail = widget.data['recipientEmail'] as String?;
    final deliveryAddress = widget.data['deliveryAddress'] as String?;
    final paymentMethod = widget.data['paymentMethod'] as String?;
    final frequency = widget.data['frequency'] as String?;
    final fromStripe = widget.data['fromStripeRedirect'] == true;

    // Show spinner while recording the transaction (web redirect case)
    if (fromStripe && _recording) {
      return const Scaffold(
        backgroundColor: AppConstants.background,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppConstants.gold),
              SizedBox(height: 16),
              Text('Confirming payment…',
                  style: TextStyle(color: AppConstants.subtitle)),
            ],
          ),
        ),
      );
    }

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
                      child: const Icon(
                        Icons.check_rounded,
                        color: AppConstants.green,
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      type,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppConstants.black,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Transaction confirmed',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppConstants.subtitle,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 28),
                      decoration: BoxDecoration(
                        color: AppConstants.gold.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppConstants.gold.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'kr.${NumberFormat('#,###.##').format(amountSek)}',
                            style: const TextStyle(
                              fontSize: 38,
                              fontWeight: FontWeight.w700,
                              color: AppConstants.gold,
                              letterSpacing: -1,
                            ),
                          ),
                          if (goldGrams != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              '${goldGrams.toStringAsFixed(3)}g of gold',
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppConstants.subtitle,
                              ),
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
                            label: 'Gold price',
                            value:
                                'kr.${NumberFormat('#,###.##').format(goldPrice)}/g',
                          ),
                        if (frequency != null)
                          _ReceiptRow(label: 'Frequency', value: frequency),
                        if (paymentMethod != null)
                          _ReceiptRow(
                            label: 'Payment',
                            value: _formatPaymentMethod(paymentMethod),
                          ),
                        if (recipientName != null)
                          _ReceiptRow(label: 'Recipient', value: recipientName),
                        if (recipientEmail != null)
                          _ReceiptRow(label: 'Email', value: recipientEmail),
                        if (deliveryAddress != null)
                          _ReceiptRow(
                              label: 'Delivery to', value: deliveryAddress),
                        _ReceiptRow(
                          label: 'Date',
                          value: DateFormat('MMM dd, yyyy • HH:mm')
                              .format(DateTime.now()),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => context.go(Routes.home),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppConstants.gold,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatPaymentMethod(String method) {
    switch (method) {
      case 'wallet':
        return 'Wallet';
      case 'creditCard':
        return 'Credit Card';
      case 'bankTransfer':
        return 'Bank Transfer';
      case 'card':
        return 'Credit/Debit Card';
      case 'bank':
        return 'Bank Transfer';
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
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: children.asMap().entries.map((e) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: e.value,
              ),
              if (e.key < children.length - 1)
                const Divider(height: 1, color: AppConstants.divider),
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
        Text(
          label,
          style:
              const TextStyle(fontSize: 14, color: AppConstants.subtitle),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppConstants.black,
            ),
          ),
        ),
      ],
    );
  }
}
