import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../widgets/common/gold_button.dart';

class BuyGoldScreen extends StatefulWidget {
  const BuyGoldScreen({super.key});

  @override
  State<BuyGoldScreen> createState() => _BuyGoldScreenState();
}

class _BuyGoldScreenState extends State<BuyGoldScreen> {
  int _selectedTab = 1; // Buy tab active
  String _purchaseMode = 'recurring'; // 'recurring' | 'onetime'
  String _paymentMethod = 'wallet'; // 'wallet' | 'card' | 'bank'

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    _buildHeader(),
                    const SizedBox(height: 20),
                    _buildRateCard(),
                    const SizedBox(height: 28),
                    _buildSectionLabel('Purchase mode'),
                    const SizedBox(height: 12),
                    _buildPurchaseModeCard(),
                    const SizedBox(height: 28),
                    _buildSectionLabel('Payment method'),
                    const SizedBox(height: 12),
                    _buildPaymentMethodCard(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            _buildContinueButton(),
            _buildBottomNav(),
          ],
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child:
              const Icon(Icons.arrow_back, color: AppConstants.black, size: 24),
        ),
        const SizedBox(width: 12),
        const Text(
          'Buy Gold',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppConstants.black,
          ),
        ),
      ],
    );
  }

  // ── Rate card ──────────────────────────────────────────────────────────────
  Widget _buildRateCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppConstants.card,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon + "Rate" label
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppConstants.gold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.layers_rounded,
                    color: AppConstants.gold, size: 20),
              ),
              const SizedBox(width: 10),
              const Text(
                'Rate',
                style: TextStyle(
                    color: AppConstants.subtitle,
                    fontSize: 14,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Price row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'kr.25,796.19',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppConstants.black,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 10),
              // Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppConstants.green.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_upward_rounded,
                        color: AppConstants.green, size: 12),
                    SizedBox(width: 2),
                    Text(
                      '1.30%',
                      style: TextStyle(
                        color: AppConstants.green,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'vs last rate',
                style: TextStyle(color: AppConstants.subtitle, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Per troy ounce  •  Real-time pricing',
            style: TextStyle(color: AppConstants.subtitle, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ── Section label ──────────────────────────────────────────────────────────
  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: AppConstants.black,
      ),
    );
  }

  // ── Purchase mode card ─────────────────────────────────────────────────────
  Widget _buildPurchaseModeCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppConstants.card,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          _PurchaseModeRow(
            icon: Icons.repeat_rounded,
            iconBg: const Color(0xFFE8F0FE),
            iconColor: const Color(0xFF5B8DEF),
            title: 'Recurring Plan',
            subtitle:
                'Automate your gold purchases with a\nplan that fits your lifestyle.',
            value: 'recurring',
            groupValue: _purchaseMode,
            onChanged: (v) => setState(() => _purchaseMode = v),
            showDivider: true,
          ),
          _PurchaseModeRow(
            icon: Icons.monetization_on_outlined,
            iconBg: const Color(0xFFF3E8FF),
            iconColor: const Color(0xFF9B59B6),
            title: 'One-time purchase',
            subtitle:
                'Make a quick, one-time gold investment\nwhenever you like.',
            value: 'onetime',
            groupValue: _purchaseMode,
            onChanged: (v) => setState(() => _purchaseMode = v),
            showDivider: false,
          ),
        ],
      ),
    );
  }

  // ── Payment method card ────────────────────────────────────────────────────
  Widget _buildPaymentMethodCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppConstants.card,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          _PaymentMethodRow(
            icon: Icons.account_balance_wallet_outlined,
            iconBg: const Color(0xFFF0F0F0),
            iconColor: AppConstants.subtitle,
            title: 'Wallet Balance',
            subtitle: 'Available Balance: kr.525,000.00',
            value: 'wallet',
            groupValue: _paymentMethod,
            onChanged: (v) => setState(() => _paymentMethod = v),
            showDivider: true,
          ),
          _PaymentMethodRow(
            icon: Icons.credit_card_rounded,
            iconBg: const Color(0xFFF0F0F0),
            iconColor: AppConstants.subtitle,
            title: 'Credit/Debit Card',
            subtitle: null,
            cardLogos: true,
            value: 'card',
            groupValue: _paymentMethod,
            onChanged: (v) => setState(() => _paymentMethod = v),
            showDivider: true,
          ),
          _PaymentMethodRow(
            icon: Icons.account_balance_rounded,
            iconBg: const Color(0xFFF0F0F0),
            iconColor: AppConstants.subtitle,
            title: 'Bank Transfer',
            subtitle: 'ACH Transfer (3–5 business days)',
            value: 'bank',
            groupValue: _paymentMethod,
            onChanged: (v) => setState(() => _paymentMethod = v),
            showDivider: false,
          ),
        ],
      ),
    );
  }

  Widget _buildContinueButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: GoldButton(
        label: 'Continue',
        onPressed: () {
          if (_purchaseMode == 'recurring') {
            context.push('/buy/recurring');
          } else {
            context.push('/buy/onetime');
          }
        },
      ),
    );
  }

  // ── Bottom nav ─────────────────────────────────────────────────────────────
  Widget _buildBottomNav() {
    final items = [
      const _NavItem(icon: Icons.home_rounded, label: 'Home'),
      const _NavItem(icon: Icons.shopping_bag_outlined, label: 'Buy'),
      const _NavItem(
          icon: Icons.account_balance_wallet_outlined, label: 'Wallet'),
      const _NavItem(icon: Icons.pie_chart_outline_rounded, label: 'Portfolio'),
      const _NavItem(icon: Icons.menu_rounded, label: 'More'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppConstants.card,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items.asMap().entries.map((e) {
          final isSelected = e.key == _selectedTab;
          return GestureDetector(
            onTap: () {
              if (e.key == 0) {
                Navigator.of(context).pop(); // Go back to home
              } else {
                setState(() => _selectedTab = e.key);
                // Show coming soon for other tabs
                if (e.key != 1) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${e.value.label} screen coming soon!'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                }
              }
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(e.value.icon,
                    color:
                        isSelected ? AppConstants.gold : AppConstants.subtitle,
                    size: 24),
                const SizedBox(height: 3),
                Text(
                  e.value.label,
                  style: TextStyle(
                    color:
                        isSelected ? AppConstants.gold : AppConstants.subtitle,
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Purchase Mode Row ────────────────────────────────────────────────────────
class _PurchaseModeRow extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String value;
  final String groupValue;
  final ValueChanged<String> onChanged;
  final bool showDivider;

  const _PurchaseModeRow({
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppConstants.black,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppConstants.subtitle,
                            height: 1.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _GoldRadio(selected: selected),
              ],
            ),
          ),
          if (showDivider)
            const Divider(
                height: 1,
                thickness: 1,
                color: AppConstants.background,
                indent: 16,
                endIndent: 16),
        ],
      ),
    );
  }
}

// ─── Payment Method Row ───────────────────────────────────────────────────────
class _PaymentMethodRow extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final bool cardLogos;
  final String value;
  final String groupValue;
  final ValueChanged<String> onChanged;
  final bool showDivider;

  const _PaymentMethodRow({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.cardLogos = false,
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppConstants.black,
                        ),
                      ),
                      const SizedBox(height: 3),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: const TextStyle(
                              fontSize: 12, color: AppConstants.subtitle),
                        ),
                      if (cardLogos) _buildCardLogos(),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _GoldRadio(selected: selected),
              ],
            ),
          ),
          if (showDivider)
            const Divider(
                height: 1,
                thickness: 1,
                color: AppConstants.background,
                indent: 16,
                endIndent: 16),
        ],
      ),
    );
  }

  Widget _buildCardLogos() {
    final logos = [
      {'label': 'VISA', 'color': const Color(0xFF1A1F71)},
      {'label': 'MC', 'color': const Color(0xFFEB001B)},
      {'label': 'AMEX', 'color': const Color(0xFF2E77BC)},
    ];
    return Row(
      children: logos.map((l) {
        return Container(
          margin: const EdgeInsets.only(right: 5, top: 4),
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFDDDDDD)),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            l['label'] as String,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: l['color'] as Color,
              letterSpacing: 0.3,
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Gold Radio Button ────────────────────────────────────────────────────────
class _GoldRadio extends StatelessWidget {
  final bool selected;
  const _GoldRadio({required this.selected});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? AppConstants.gold : const Color(0xFFCCCCCC),
          width: selected ? 6 : 2,
        ),
      ),
    );
  }
}

// ─── Nav Item Model ───────────────────────────────────────────────────────────
class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}
