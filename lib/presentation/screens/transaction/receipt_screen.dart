import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/router/router.dart';

class ReceiptScreen extends StatelessWidget {
  final Map<String, dynamic> data;
  const ReceiptScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final type = data['type'] as String? ?? 'Transaction';
    final amountSek = (data['amountSek'] as num?)?.toDouble() ?? 0;
    final goldGrams = (data['goldGrams'] as num?)?.toDouble();
    final goldPrice = (data['goldPricePerGramSek'] as num?)?.toDouble();
    final recipientName = data['recipientName'] as String?;
    final recipientEmail = data['recipientEmail'] as String?;
    final deliveryAddress = data['deliveryAddress'] as String?;
    final paymentMethod = data['paymentMethod'] as String?;
    final frequency = data['frequency'] as String?;

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
          style: const TextStyle(fontSize: 14, color: AppConstants.subtitle),
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
