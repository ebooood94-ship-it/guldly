import 'package:flutter/material.dart';
import 'package:guldly/core/constants/app_constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/models/models.dart';
import '../../../core/providers/providers.dart';
import '../../../core/router/router.dart';
import '../../widgets/common/screen_header.dart';
import 'package:go_router/go_router.dart';

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletAsync = ref.watch(walletProvider);
    final txAsync = ref.watch(transactionsProvider);

    return Scaffold(
      backgroundColor: AppConstants.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ScreenHeader(title: 'Wallet'),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Gold wallet card
                    walletAsync.when(
                      data: (wallet) => _WalletCard(wallet: wallet),
                      loading: () => const _WalletCardSkeleton(),
                      error: (_, __) => const _WalletCardSkeleton(),
                    ),
                    const SizedBox(height: 28),
                    const Text('Recent transactions',
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppConstants.black)),
                    const SizedBox(height: 16),
                    txAsync.when(
                      data: (txs) => txs.isEmpty
                          ? const Center(
                              child: Text('No transactions yet',
                                  style:
                                      TextStyle(color: AppConstants.subtitle)))
                          : _TransactionList(transactions: txs),
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Text('Error: $e'),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WalletCard extends StatelessWidget {
  final Wallet? wallet;
  const _WalletCard({this.wallet});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFD4A017), Color(0xFFB8860B), Color(0xFFD4A017)],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            wallet != null
                ? 'kr.${NumberFormat('#,###.00').format(wallet!.balanceSek)}'
                : 'kr.0.00',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5),
          ),
          const SizedBox(height: 4),
          const Text('Wallet balance',
              style: TextStyle(color: Colors.white70, fontSize: 13)),
          const Spacer(),
          GestureDetector(
            onTap: () => context.push(Routes.addFunds),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white54),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_circle_outline, color: Colors.white, size: 16),
                  SizedBox(width: 6),
                  Text('Add funds',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WalletCardSkeleton extends StatelessWidget {
  const _WalletCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: AppConstants.gold.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}

class _TransactionList extends StatelessWidget {
  final List<Transaction> transactions;
  const _TransactionList({required this.transactions});

  Map<String, List<Transaction>> _groupByMonth() {
    final grouped = <String, List<Transaction>>{};
    for (final tx in transactions) {
      final key = DateFormat('MMMM yyyy').format(tx.createdAt);
      grouped.putIfAbsent(key, () => []).add(tx);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupByMonth();
    return Column(
      children: grouped.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text(entry.key,
                  style: const TextStyle(
                      color: AppConstants.subtitle,
                      fontWeight: FontWeight.w600,
                      fontSize: 14)),
              const SizedBox(width: 8),
              Expanded(child: Divider(color: Colors.grey.shade300)),
            ]),
            const SizedBox(height: 12),
            ...entry.value.map((tx) => _TransactionRow(tx: tx)),
            const SizedBox(height: 16),
          ],
        );
      }).toList(),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  final Transaction tx;
  const _TransactionRow({required this.tx});

  @override
  Widget build(BuildContext context) {
    final isPositive = tx.type == TransactionType.addFunds ||
        tx.type == TransactionType.sell ||
        tx.type == TransactionType.giftReceived;
    final color = isPositive ? AppConstants.green : AppConstants.black;
    final prefix = isPositive ? '+' : '-';

    return GestureDetector(
      onTap: () => _showDetail(context),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppConstants.green.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.currency_exchange,
                  color: AppConstants.green, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_txLabel(tx.type),
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppConstants.black)),
                  const SizedBox(height: 2),
                  Text(DateFormat('MMM dd, yyyy').format(tx.createdAt),
                      style: const TextStyle(
                          fontSize: 12, color: AppConstants.subtitle)),
                ],
              ),
            ),
            Text(
              '$prefix kr.${NumberFormat('#,###').format(tx.amountSek)}',
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _TransactionDetailSheet(tx: tx),
    );
  }

  String _txLabel(TransactionType type) {
    switch (type) {
      case TransactionType.addFunds:
        return 'Added funds';
      case TransactionType.buy:
        return 'Bought gold';
      case TransactionType.sell:
        return 'Sold gold';
      case TransactionType.giftSent:
        return 'Gift sent';
      case TransactionType.giftReceived:
        return 'Gift received';
      case TransactionType.delivery:
        return 'Delivery requested';
      case TransactionType.recurringBuy:
        return 'Recurring purchase';
    }
  }
}

class _TransactionDetailSheet extends StatelessWidget {
  final Transaction tx;
  const _TransactionDetailSheet({required this.tx});

  @override
  Widget build(BuildContext context) {
    final isPositive = tx.type == TransactionType.addFunds ||
        tx.type == TransactionType.sell ||
        tx.type == TransactionType.giftReceived;
    final amountColor = isPositive ? AppConstants.green : AppConstants.black;
    final prefix = isPositive ? '+' : '-';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppConstants.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _txLabel(tx.type),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppConstants.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$prefix kr.${NumberFormat('#,###.##').format(tx.amountSek)}',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w300,
              color: amountColor,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 24),
          _DetailRow(
            label: 'Status',
            value:
                tx.status.name[0].toUpperCase() + tx.status.name.substring(1),
          ),
          const Divider(height: 16, color: AppConstants.divider),
          _DetailRow(
            label: 'Date',
            value: DateFormat('MMM dd, yyyy • HH:mm').format(tx.createdAt),
          ),
          if (tx.goldGrams != null) ...[
            const Divider(height: 16, color: AppConstants.divider),
            _DetailRow(
              label: 'Gold',
              value: '${tx.goldGrams!.toStringAsFixed(3)}g',
            ),
          ],
          if (tx.goldPricePerGramSek != null) ...[
            const Divider(height: 16, color: AppConstants.divider),
            _DetailRow(
              label: 'Gold price',
              value:
                  'kr.${NumberFormat('#,###.##').format(tx.goldPricePerGramSek)}/g',
            ),
          ],
          if (tx.paymentMethod != null) ...[
            const Divider(height: 16, color: AppConstants.divider),
            _DetailRow(
              label: 'Payment',
              value: _formatPaymentMethod(tx.paymentMethod!),
            ),
          ],
          if (tx.recipientName != null) ...[
            const Divider(height: 16, color: AppConstants.divider),
            _DetailRow(label: 'Recipient', value: tx.recipientName!),
          ],
          if (tx.recipientEmail != null) ...[
            const Divider(height: 16, color: AppConstants.divider),
            _DetailRow(label: 'Email', value: tx.recipientEmail!),
          ],
          if (tx.deliveryAddress != null) ...[
            const Divider(height: 16, color: AppConstants.divider),
            _DetailRow(label: 'Delivery to', value: tx.deliveryAddress!),
          ],
          const Divider(height: 16, color: AppConstants.divider),
          _DetailRow(
            label: 'Ref',
            value: tx.id.substring(0, 8).toUpperCase(),
          ),
        ],
      ),
    );
  }

  String _txLabel(TransactionType type) {
    switch (type) {
      case TransactionType.addFunds:
        return 'Added funds';
      case TransactionType.buy:
        return 'Bought gold';
      case TransactionType.sell:
        return 'Sold gold';
      case TransactionType.giftSent:
        return 'Gift sent';
      case TransactionType.giftReceived:
        return 'Gift received';
      case TransactionType.delivery:
        return 'Delivery requested';
      case TransactionType.recurringBuy:
        return 'Recurring purchase';
    }
  }

  String _formatPaymentMethod(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.wallet:
        return 'Wallet';
      case PaymentMethod.creditCard:
        return 'Credit Card';
      case PaymentMethod.bankTransfer:
        return 'Bank Transfer';
    }
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 14, color: AppConstants.subtitle)),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppConstants.black),
          ),
        ),
      ],
    );
  }
}
