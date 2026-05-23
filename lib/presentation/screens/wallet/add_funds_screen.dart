import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/providers.dart';
import '../../../core/router/router.dart';
import '../../../core/services/stripe_service.dart';
import '../../../core/utils/web_redirect.dart';
import '../../widgets/common/app_snackbar.dart';
import '../../widgets/common/back_header.dart';
import '../../widgets/common/gold_button.dart';
import '../../widgets/common/section_label.dart';
import '../../widgets/common/suggestion_pills.dart';

class AddFundsScreen extends ConsumerStatefulWidget {
  const AddFundsScreen({super.key});

  @override
  ConsumerState<AddFundsScreen> createState() => _AddFundsScreenState();
}

class _AddFundsScreenState extends ConsumerState<AddFundsScreen> {
  int _amountKr = 0;
  String? _selectedPill;
  String _paymentMethod = 'card';
  bool _loading = false;

  static const _pillLabels = ['100 kr', '250 kr', '500 kr', '1 000 kr'];
  static const _pillValues = [100, 250, 500, 1000];

  Future<void> _onContinue() async {
    setState(() => _loading = true);
    try {
      if (_paymentMethod == 'card') {
        if (kIsWeb) {
          await _webStripeRedirect();
          return;
        }
        final paid = await StripeService.pay(
          amountSek: _amountKr.toDouble(),
          supabase: ref.read(supabaseProvider),
        );
        if (!paid || !mounted) return;
      }
      await ref.read(goldTransactionServiceProvider).addFunds(
            amountSek: _amountKr.toDouble(),
            paymentMethod: _paymentMethod,
          );
      if (mounted) {
        context.go(Routes.receipt, extra: {
          'type': 'Add Funds',
          'amountSek': _amountKr.toDouble(),
          'paymentMethod': _paymentMethod,
        });
      }
    } catch (e) {
      if (mounted) AppSnackbar.error(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _webStripeRedirect() async {
    final supabase = ref.read(supabaseProvider);
    final origin = webOrigin;
    final type = Uri.encodeComponent('Add Funds');
    final successUrl =
        '$origin/#/receipt?type=$type&amount=${_amountKr.toDouble()}&paymentMethod=card&addFunds=true&success=true';
    final cancelUrl = '$origin/#/wallet/add-funds';
    final response = await supabase.functions.invoke(
      'create-payment-intent',
      body: {
        'mode': 'web_checkout',
        'amount': _amountKr.toDouble(),
        'currency': 'sek',
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
    final walletAsync = ref.watch(walletProvider);
    final balance = walletAsync.value?.balanceSek ?? 0;
    final fmtBalance =
        NumberFormat('#,##0', 'sv_SE').format(balance).replaceAll(',', ' ');

    return Scaffold(
      backgroundColor: AppConstants.background,
      body: SafeArea(
        child: Column(
          children: [
            const BackHeader(title: 'Lägg till medel', useSerifTitle: true),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.screenPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildWalletInfo(fmtBalance),
                    const SizedBox(height: AppConstants.sectionGap),
                    _buildAmountHero(),
                    const SizedBox(height: 16),
                    Center(
                      child: SuggestionPills(
                        labels: _pillLabels,
                        selected: _selectedPill,
                        onTap: (label) {
                          final idx = _pillLabels.indexOf(label);
                          if (idx >= 0) {
                            setState(() {
                              _amountKr = _pillValues[idx];
                              _selectedPill = label;
                            });
                          }
                        },
                        pillContext: PillContext.gold,
                      ),
                    ),
                    const SizedBox(height: AppConstants.sectionGap),
                    const SectionLabel('BETALNINGSSÄTT'),
                    _buildPaymentCard(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppConstants.screenPadding, 0, AppConstants.screenPadding, 20),
              child: GoldButton(
                label: 'FORTSÄTT',
                loading: _loading,
                onPressed: (_amountKr > 0 && !_loading) ? _onContinue : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletInfo(String fmtBalance) {
    return Container(
      decoration: BoxDecoration(
        color: AppConstants.card,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        border: Border.all(color: AppConstants.divider, width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppConstants.goldLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.account_balance_wallet_outlined,
                color: AppConstants.gold, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Plånbok',
                  style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppConstants.black)),
              Text('Nuvarande saldo: $fmtBalance kr',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: AppConstants.subtitle)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAmountHero() {
    final fmt = _amountKr > 0
        ? '${NumberFormat('#,##0', 'sv_SE').format(_amountKr).replaceAll(',', ' ')} kr'
        : '0 kr';
    return Center(
      child: Text(
        fmt,
        style: GoogleFonts.playfairDisplay(
          fontSize: 48,
          fontStyle: FontStyle.italic,
          color: AppConstants.black,
          height: 1.0,
        ),
      ),
    );
  }

  Widget _buildPaymentCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppConstants.card,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        border: Border.all(color: AppConstants.divider, width: 1),
      ),
      child: Column(
        children: [
          _PayRow(
            icon: Icons.credit_card_rounded,
            iconBg: AppConstants.buyIconBg,
            iconColor: AppConstants.goldDark,
            title: 'Kredit-/betalkort',
            subtitle: 'Visa, Mastercard',
            value: 'card',
            groupValue: _paymentMethod,
            onChanged: (v) => setState(() => _paymentMethod = v),
            showDivider: true,
          ),
          _PayRow(
            icon: Icons.account_balance_rounded,
            iconBg: AppConstants.deliveryIconBg,
            iconColor: AppConstants.navy,
            title: 'Banköverföring',
            subtitle: 'ACH, 3–5 bankdagar',
            value: 'bank',
            groupValue: _paymentMethod,
            onChanged: (v) => setState(() => _paymentMethod = v),
            showDivider: false,
          ),
        ],
      ),
    );
  }
}

class _PayRow extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String value;
  final String groupValue;
  final ValueChanged<String> onChanged;
  final bool showDivider;

  const _PayRow({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    return GestureDetector(
      onTap: () => onChanged(value),
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppConstants.black)),
                      Text(subtitle,
                          style: GoogleFonts.inter(
                              fontSize: 12, color: AppConstants.subtitle)),
                    ],
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? AppConstants.gold : AppConstants.divider,
                      width: selected ? 6 : 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (showDivider)
            const Divider(
                height: 1,
                thickness: 1,
                color: AppConstants.divider,
                indent: 16,
                endIndent: 16),
        ],
      ),
    );
  }
}
