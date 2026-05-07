import 'package:flutter/material.dart';
import 'package:guldly/core/constants/app_constants.dart';
import '../../widgets/common/gold_button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/providers.dart';
import '../../widgets/common/back_header.dart';
import '../../widgets/common/payment_row.dart';
import '../../widgets/common/gold_card.dart';
import 'package:intl/intl.dart';

class AddFundsScreen extends ConsumerStatefulWidget {
  const AddFundsScreen({super.key});

  @override
  ConsumerState<AddFundsScreen> createState() => _AddFundsScreenState();
}

class _AddFundsScreenState extends ConsumerState<AddFundsScreen> {
  int _amountKr = 0;
  String _paymentMethod = 'card';
  static const _suggestions = [100, 250, 500, 1000, 2500, 5000];

  @override
  Widget build(BuildContext context) {
    final walletAsync = ref.watch(walletProvider);
    return Scaffold(
      backgroundColor: AppConstants.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            const BackHeader(title: 'Add funds'),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Amount',
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppConstants.black)),
                    const SizedBox(height: 12),
                    GoldCard(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Wallet',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                            color: AppConstants.black)),
                                    Text(
                                      walletAsync.when(
                                        data: (w) =>
                                            'Avl Bal = kr.${NumberFormat('#,###').format(w?.balanceSek ?? 0)}',
                                        loading: () => 'Loading...',
                                        error: (_, __) => 'Avl Bal = kr.0',
                                      ),
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppConstants.subtitle),
                                    ),
                                  ],
                                ),
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: AppConstants.gold
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                      Icons.account_balance_wallet_rounded,
                                      color: AppConstants.gold,
                                      size: 20),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'kr.${_amountKr == 0 ? '0' : NumberFormat('#,###').format(_amountKr)}',
                              style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w300,
                                  color: AppConstants.subtitle,
                                  letterSpacing: -1),
                            ),
                            const SizedBox(height: 16),
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text('Quick suggestion',
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: AppConstants.subtitle)),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _suggestions.map((amt) {
                                final sel = _amountKr == amt;
                                return GestureDetector(
                                  onTap: () => setState(() => _amountKr = amt),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: sel
                                          ? AppConstants.gold
                                              .withValues(alpha: 0.12)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: sel
                                            ? AppConstants.gold
                                            : const Color(0xFFDDDDDD),
                                      ),
                                    ),
                                    child: Text(
                                      'kr.${NumberFormat('#,###').format(amt)}',
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: sel
                                              ? AppConstants.gold
                                              : AppConstants.black,
                                          fontWeight: sel
                                              ? FontWeight.w600
                                              : FontWeight.w400),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    const Text('Payment method',
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppConstants.black)),
                    const SizedBox(height: 12),
                    GoldCard(
                      child: Column(
                        children: [
                          PaymentRow(
                            icon: Icons.credit_card_rounded,
                            title: 'Credit/Debit Card',
                            showCardLogos: true,
                            value: 'card',
                            groupValue: _paymentMethod,
                            onChanged: (v) =>
                                setState(() => _paymentMethod = v),
                            showDivider: true,
                          ),
                          PaymentRow(
                            icon: Icons.account_balance_rounded,
                            title: 'Bank Transfer',
                            subtitle: 'ACH Transfer (3–5 business days)',
                            value: 'bank',
                            groupValue: _paymentMethod,
                            onChanged: (v) =>
                                setState(() => _paymentMethod = v),
                            showDivider: false,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: GoldButton(label: 'Continue', onPressed: () {}),
            ),
          ],
        ),
      ),
    );
  }
}
