import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/providers.dart';
import '../../widgets/common/back_header.dart';
import '../../widgets/common/gold_button.dart';
import '../../widgets/common/section_label.dart';

class BuyGoldScreen extends ConsumerStatefulWidget {
  const BuyGoldScreen({super.key});

  @override
  ConsumerState<BuyGoldScreen> createState() => _BuyGoldScreenState();
}

class _BuyGoldScreenState extends ConsumerState<BuyGoldScreen> {
  String _purchaseMode = 'recurring';
  String _paymentMethod = 'wallet';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.background,
      body: SafeArea(
        child: Column(
          children: [
            BackHeader(
              title: 'Köp guld',
              useSerifTitle: true,
              trailing: GestureDetector(
                onTap: () {},
                child: const Icon(Icons.notifications_outlined,
                    color: AppConstants.subtitle, size: 22),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.screenPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildLivePriceCard(),
                    const SizedBox(height: AppConstants.sectionGap),
                    const SectionLabel('VÄLJ KÖPSÄTT'),
                    _buildPurchaseModeCard(),
                    const SizedBox(height: AppConstants.sectionGap),
                    const SectionLabel('BETALMETOD'),
                    _buildPaymentMethodCard(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppConstants.screenPadding, 8, AppConstants.screenPadding, 20),
              child: GoldButton(
                label: 'FORTSÄTT',
                onPressed: () {
                  ref.read(selectedPaymentMethodProvider.notifier).state =
                      _paymentMethod;
                  if (_purchaseMode == 'recurring') {
                    context.push('/buy/recurring');
                  } else {
                    context.push('/buy/onetime');
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLivePriceCard() {
    final goldAsync = ref.watch(goldPriceProvider);
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
            child: const Icon(Icons.layers_rounded,
                color: AppConstants.gold, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GULDPRIS',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppConstants.subtitle,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 2),
                goldAsync.when(
                  data: (g) => Text(
                    '${NumberFormat('#,##0.##', 'sv_SE').format(g.pricePerGramSek).replaceAll(',', ' ')} kr/g',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 18,
                      fontStyle: FontStyle.italic,
                      color: AppConstants.black,
                    ),
                  ),
                  loading: () => Text('Laddar…',
                      style: GoogleFonts.inter(
                          fontSize: 14, color: AppConstants.subtitle)),
                  error: (_, __) => Text('Ej tillgängligt',
                      style: GoogleFonts.inter(
                          fontSize: 14, color: AppConstants.error)),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppConstants.green.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '+1,30%',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppConstants.green,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPurchaseModeCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppConstants.card,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        border: Border.all(color: AppConstants.divider, width: 1),
      ),
      child: Column(
        children: [
          _RadioRow(
            icon: Icons.repeat_rounded,
            iconBg: AppConstants.goldLight,
            iconColor: AppConstants.gold,
            title: 'Återkommande plan',
            subtitle: 'Automatisera dina guldköp med en plan.',
            value: 'recurring',
            groupValue: _purchaseMode,
            onChanged: (v) => setState(() => _purchaseMode = v),
            showDivider: true,
          ),
          _RadioRow(
            icon: Icons.monetization_on_outlined,
            iconBg: AppConstants.giftIconBg,
            iconColor: AppConstants.violet,
            title: 'Engångsköp',
            subtitle: 'Gör ett snabbt engångsinvestering i guld.',
            value: 'onetime',
            groupValue: _purchaseMode,
            onChanged: (v) => setState(() => _purchaseMode = v),
            showDivider: false,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppConstants.card,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        border: Border.all(color: AppConstants.divider, width: 1),
      ),
      child: Column(
        children: [
          _RadioRow(
            icon: Icons.account_balance_wallet_outlined,
            iconBg: AppConstants.goldLight,
            iconColor: AppConstants.gold,
            title: 'Plånbok',
            subtitle: ref.watch(walletProvider).when(
                  data: (w) =>
                      'Tillgängligt: ${NumberFormat('#,##0', 'sv_SE').format(w?.balanceSek ?? 0).replaceAll(',', ' ')} kr',
                  loading: () => 'Laddar…',
                  error: (_, __) => 'Tillgängligt: 0 kr',
                ),
            value: 'wallet',
            groupValue: _paymentMethod,
            onChanged: (v) => setState(() => _paymentMethod = v),
            showDivider: true,
          ),
          _RadioRow(
            icon: Icons.credit_card_rounded,
            iconBg: AppConstants.buyIconBg,
            iconColor: AppConstants.goldDark,
            title: 'Bankkort',
            subtitle: 'Visa •••• 4242',
            value: 'card',
            groupValue: _paymentMethod,
            onChanged: (v) => setState(() => _paymentMethod = v),
            showDivider: true,
          ),
          _RadioRow(
            icon: Icons.account_balance_rounded,
            iconBg: AppConstants.deliveryIconBg,
            iconColor: AppConstants.navy,
            title: 'Direktöverföring',
            subtitle: 'BankID signering',
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

class _RadioRow extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String value;
  final String groupValue;
  final ValueChanged<String> onChanged;
  final bool showDivider;

  const _RadioRow({
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
                      const SizedBox(height: 2),
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
