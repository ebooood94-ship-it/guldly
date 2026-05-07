import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../widgets/common/back_header.dart';
import '../../widgets/common/gold_button.dart';
import '../../widgets/common/gold_card.dart';

class BuyOnetimeScreen extends ConsumerStatefulWidget {
  const BuyOnetimeScreen({super.key});

  @override
  ConsumerState<BuyOnetimeScreen> createState() => _BuyOnetimeScreenState();
}

class _BuyOnetimeScreenState extends ConsumerState<BuyOnetimeScreen> {
  int _amountKr = 0;
  static const double _pricePerOz = 25796.19;
  static const double _gramsPerOz = 31.1035;
  static const List<int> _suggestions = [100, 250, 500, 1000, 2500, 5000];

  double get _grams =>
      _amountKr == 0 ? 0 : (_amountKr / _pricePerOz) * _gramsPerOz;

  String get _gramsLabel =>
      _grams == 0 ? '≈0g' : '≈${_grams.toStringAsFixed(2)}g';

  void _tap(int amount) {
    HapticFeedback.lightImpact();
    setState(() => _amountKr = amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            const BackHeader(title: 'Buy gold'),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Amount',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppConstants.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GoldCard(child: _buildAmountContent()),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: GoldButton(
                label: 'Continue',
                onPressed: _amountKr > 0 ? () {} : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountContent() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gold info row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Gold',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppConstants.black,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Text(
                        'kr.25,796.19',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppConstants.subtitle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      _LiveBadge(),
                    ],
                  ),
                ],
              ),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppConstants.gold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.layers_rounded,
                  color: AppConstants.gold,
                  size: 20,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Big amount display
          Center(
            child: Column(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: ScaleTransition(scale: anim, child: child),
                  ),
                  child: Text(
                    'kr.${_amountKr == 0 ? '0' : NumberFormat('#,###').format(_amountKr)}',
                    key: ValueKey(_amountKr),
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w300,
                      color: AppConstants.subtitle,
                      letterSpacing: -1,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _gramsLabel,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppConstants.subtitle,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Quick suggestions
          const Text(
            'Quick suggestion',
            style: TextStyle(fontSize: 13, color: AppConstants.subtitle),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _suggestions.map((amt) {
              final selected = _amountKr == amt;
              return GestureDetector(
                onTap: () => _tap(amt),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppConstants.gold.withValues(alpha: 0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected
                          ? AppConstants.gold
                          : const Color(0xFFDDDDDD),
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Text(
                    'kr.${NumberFormat('#,###').format(amt)}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      color: selected ? AppConstants.gold : AppConstants.black,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ─── Live Badge ───────────────────────────────────────────────────────────────
class _LiveBadge extends StatefulWidget {
  @override
  State<_LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<_LiveBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.4, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppConstants.green.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FadeTransition(
            opacity: _pulse,
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: AppConstants.green,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 4),
          const Text(
            'Live',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppConstants.green,
            ),
          ),
        ],
      ),
    );
  }
}
