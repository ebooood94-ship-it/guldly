import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/models.dart';
import '../../../core/providers/providers.dart';
import '../../../core/router/router.dart';
import '../../widgets/common/error_view.dart';
import '../../widgets/common/gold_button.dart';
import '../../widgets/gold/gold_logo.dart';

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletAsync = ref.watch(walletProvider);
    final txAsync = ref.watch(transactionsProvider);

    return Scaffold(
      backgroundColor: AppConstants.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppConstants.gold,
          onRefresh: () async {
            ref.invalidate(walletProvider);
            ref.invalidate(transactionsProvider);
          },
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.screenPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const GoldLogo(size: LogoSize.small),
                          GestureDetector(
                            onTap: () => context.push(Routes.notifications),
                            child: const Icon(Icons.notifications_outlined,
                                size: 22, color: AppConstants.black),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Plånbok',
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: AppConstants.black,
                        ),
                      ),
                      const SizedBox(height: 16),
                      walletAsync.when(
                        data: (w) => _BalanceCard(wallet: w),
                        loading: () => const _BalanceCardSkeleton(),
                        error: (_, __) => const _BalanceCardSkeleton(),
                      ),
                      const SizedBox(height: AppConstants.sectionGap),
                      _buildDarkBanner(),
                      const SizedBox(height: AppConstants.sectionGap),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.screenPadding),
                sliver: txAsync.when(
                  data: (txs) => txs.isEmpty
                      ? SliverToBoxAdapter(
                          child: Center(
                            child: Text(
                              'Inga transaktioner än',
                              style: GoogleFonts.inter(
                                  color: AppConstants.subtitle, fontSize: 14),
                            ),
                          ),
                        )
                      : _TransactionList(transactions: txs),
                  loading: () => const SliverToBoxAdapter(
                      child: Center(
                          child: CircularProgressIndicator(
                              color: AppConstants.gold))),
                  error: (e, _) =>
                      SliverToBoxAdapter(child: ErrorView(error: e)),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDarkBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppConstants.black,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SÄKERHET',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppConstants.gold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Säkerhet i världsklass',
            style: GoogleFonts.playfairDisplay(
              fontSize: 18,
              fontStyle: FontStyle.italic,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {},
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white38, width: 1),
                borderRadius:
                    BorderRadius.circular(AppConstants.buttonRadius),
              ),
              child: Text(
                'LÄS OM VÅR FÖRVARING',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final Wallet? wallet;
  const _BalanceCard({this.wallet});

  @override
  Widget build(BuildContext context) {
    final balance = wallet?.balanceSek ?? 0;
    final fmt = NumberFormat('#,##0', 'sv_SE').format(balance).replaceAll(',', ' ');

    return Container(
      decoration: BoxDecoration(
        color: AppConstants.card,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        border: Border.all(color: AppConstants.divider, width: 1),
        // 4px left gold accent border via BoxDecoration + ClipRRect trick:
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 100,
            decoration: const BoxDecoration(
              color: AppConstants.gold,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppConstants.cardRadius),
                bottomLeft: Radius.circular(AppConstants.cardRadius),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PLÅNBOKSSALDO',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppConstants.subtitle,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$fmt kr',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 30,
                      fontStyle: FontStyle.italic,
                      color: AppConstants.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GoldButton(
                    label: '+ LÄGG TILL MEDEL',
                    variant: GoldButtonVariant.ghost,
                    onPressed: () => context.push(Routes.addFunds),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanceCardSkeleton extends StatelessWidget {
  const _BalanceCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: AppConstants.divider,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
      ),
    );
  }
}

class _TransactionList extends StatelessWidget {
  final List<Transaction> transactions;
  const _TransactionList({required this.transactions});

  Map<String, List<Transaction>> _groupByMonth() {
    final grouped = <String, List<Transaction>>{};
    const months = [
      'januari', 'februari', 'mars', 'april', 'maj', 'juni',
      'juli', 'augusti', 'september', 'oktober', 'november', 'december'
    ];
    for (final tx in transactions) {
      final key =
          '${months[tx.createdAt.month - 1].toUpperCase()} ${tx.createdAt.year}';
      grouped.putIfAbsent(key, () => []).add(tx);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupByMonth();
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (ctx, i) {
          final entries = grouped.entries.toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  entries[i].key,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppConstants.subtitle,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              ...entries[i]
                  .value
                  .map((tx) => _TransactionRow(tx: tx)),
              const SizedBox(height: 16),
            ],
          );
        },
        childCount: grouped.length,
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  final Transaction tx;
  const _TransactionRow({required this.tx});

  bool get _isPositive =>
      tx.type == TransactionType.addFunds ||
      tx.type == TransactionType.sell ||
      tx.type == TransactionType.giftReceived;

  String _txLabel() {
    switch (tx.type) {
      case TransactionType.addFunds:
        return 'Insättning';
      case TransactionType.buy:
        return 'Köpte guld';
      case TransactionType.sell:
        return 'Sålde guld';
      case TransactionType.giftSent:
        return 'Gåva skickad';
      case TransactionType.giftReceived:
        return 'Gåva mottagen';
      case TransactionType.delivery:
        return 'Leverans beställd';
      case TransactionType.recurringBuy:
        return 'Återkommande köp';
    }
  }

  String _fmtDate() {
    const months = [
      'jan', 'feb', 'mar', 'apr', 'maj', 'jun',
      'jul', 'aug', 'sep', 'okt', 'nov', 'dec'
    ];
    final d = tx.createdAt;
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final color = _isPositive ? AppConstants.green : AppConstants.error;
    final prefix = _isPositive ? '+' : '-';
    final fmt = NumberFormat('#,##0', 'sv_SE')
        .format(tx.amountSek)
        .replaceAll(',', ' ');

    return GestureDetector(
      onTap: () => _showDetail(context),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppConstants.goldLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.currency_exchange,
                  color: AppConstants.gold, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_txLabel(),
                      style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppConstants.black)),
                  Text(_fmtDate(),
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppConstants.subtitle)),
                ],
              ),
            ),
            Text(
              '$prefix $fmt kr',
              style: GoogleFonts.inter(
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
}

class _TransactionDetailSheet extends StatelessWidget {
  final Transaction tx;
  const _TransactionDetailSheet({required this.tx});

  bool get _isPositive =>
      tx.type == TransactionType.addFunds ||
      tx.type == TransactionType.sell ||
      tx.type == TransactionType.giftReceived;

  String _txLabel() {
    switch (tx.type) {
      case TransactionType.addFunds:
        return 'Insättning';
      case TransactionType.buy:
        return 'Köpte guld';
      case TransactionType.sell:
        return 'Sålde guld';
      case TransactionType.giftSent:
        return 'Gåva skickad';
      case TransactionType.giftReceived:
        return 'Gåva mottagen';
      case TransactionType.delivery:
        return 'Leverans beställd';
      case TransactionType.recurringBuy:
        return 'Återkommande köp';
    }
  }

  String _fmtPayment(PaymentMethod m) {
    switch (m) {
      case PaymentMethod.wallet:
        return 'Plånbok';
      case PaymentMethod.creditCard:
        return 'Bankkort';
      case PaymentMethod.bankTransfer:
        return 'Banköverföring';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _isPositive ? AppConstants.green : AppConstants.black;
    final prefix = _isPositive ? '+' : '-';
    final fmt = NumberFormat('#,##0.##', 'sv_SE')
        .format(tx.amountSek)
        .replaceAll(',', ' ');

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
          Text(_txLabel(),
              style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppConstants.black)),
          const SizedBox(height: 4),
          Text('$prefix $fmt kr',
              style: GoogleFonts.playfairDisplay(
                fontSize: 28,
                fontStyle: FontStyle.italic,
                color: color,
              )),
          const SizedBox(height: 20),
          _row('Status',
              '${tx.status.name[0].toUpperCase()}${tx.status.name.substring(1)}'),
          const Divider(height: 16, color: AppConstants.divider),
          _row('Datum',
              DateFormat('d MMM yyyy, HH:mm').format(tx.createdAt)),
          if (tx.goldGrams != null) ...[
            const Divider(height: 16, color: AppConstants.divider),
            _row('Guld',
                '${tx.goldGrams!.toStringAsFixed(3).replaceAll('.', ',')} g'),
          ],
          if (tx.paymentMethod != null) ...[
            const Divider(height: 16, color: AppConstants.divider),
            _row('Betalning', _fmtPayment(tx.paymentMethod!)),
          ],
          if (tx.recipientName != null) ...[
            const Divider(height: 16, color: AppConstants.divider),
            _row('Mottagare', tx.recipientName!),
          ],
          const Divider(height: 16, color: AppConstants.divider),
          _row('Ref', tx.id.substring(0, 8).toUpperCase()),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 13, color: AppConstants.subtitle)),
        Flexible(
          child: Text(value,
              textAlign: TextAlign.right,
              style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppConstants.black)),
        ),
      ],
    );
  }
}
