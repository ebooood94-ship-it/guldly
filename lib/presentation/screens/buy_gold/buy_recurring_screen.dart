import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─── Colour tokens ────────────────────────────────────────────────────────────
const kGold = Color(0xFFD4A017);
const kGoldDark = Color(0xFFB8860B);
const kBlack = Color(0xFF111111);
const kBg = Color(0xFFF5F5F5);
const kCard = Colors.white;
const kSubtitle = Color(0xFF888888);

class BuyRecurringScreen extends StatefulWidget {
  const BuyRecurringScreen({super.key});

  @override
  State<BuyRecurringScreen> createState() => _BuyRecurringScreenState();
}

class _BuyRecurringScreenState extends State<BuyRecurringScreen> {
  // ── Amount state ──────────────────────────────────────────────────────────
  int _amountKr = 0;
  static const double _pricePerOz = 25796.19;
  static const double _gramsPerOz = 31.1035;

  // ── Schedule state ────────────────────────────────────────────────────────
  String _frequency = 'Weekly'; // Daily | Weekly | Monthly
  final Set<String> _selectedDays = {'Sun'};

  static const _weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  static const _suggestions = [100, 250, 500, 1000, 2500, 5000];

  double get _grams =>
      _amountKr == 0 ? 0 : (_amountKr / _pricePerOz) * _gramsPerOz;

  String get _gramsLabel {
    if (_grams == 0) return '≈0g';
    return '≈${_grams.toStringAsFixed(2)}g';
  }

  void _tap(int amount) {
    HapticFeedback.lightImpact();
    setState(() => _amountKr = amount);
  }

  void _toggleDay(String day) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedDays.contains(day)) {
        if (_selectedDays.length > 1) _selectedDays.remove(day);
      } else {
        _selectedDays.add(day);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildTopBar(),
                    const SizedBox(height: 24),
                    _buildSectionLabel('Amount'),
                    const SizedBox(height: 12),
                    _buildAmountCard(),
                    const SizedBox(height: 28),
                    _buildSectionLabel('Schedule'),
                    const SizedBox(height: 12),
                    _buildScheduleCard(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            _buildContinueButton(),
          ],
        ),
      ),
    );
  }

  // ── Top bar ────────────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: const Icon(Icons.arrow_back, color: kBlack, size: 22),
          ),
        ),
        const Text(
          'Buy gold',
          style: TextStyle(
              fontSize: 17, fontWeight: FontWeight.w600, color: kBlack),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
          fontSize: 17, fontWeight: FontWeight.w700, color: kBlack),
    );
  }

  // ── Amount card ────────────────────────────────────────────────────────────
  Widget _buildAmountCard() {
    return Container(
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
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
                  const Text('Gold',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: kBlack)),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Text('kr.25,796.19',
                          style: TextStyle(fontSize: 12, color: kSubtitle)),
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
                  color: kGold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.layers_rounded, color: kGold, size: 20),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Big amount display
          Center(
            child: Column(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: ScaleTransition(scale: anim, child: child)),
                  child: Text(
                    'kr.${_amountKr == 0 ? '0' : _formatAmount(_amountKr)}',
                    key: ValueKey(_amountKr),
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w300,
                      color: kSubtitle,
                      letterSpacing: -1,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _gramsLabel,
                  style: const TextStyle(fontSize: 13, color: kSubtitle),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Quick suggestions
          const Text('Quick suggestion',
              style: TextStyle(fontSize: 13, color: kSubtitle)),
          const SizedBox(height: 10),
          _buildSuggestionChips(),
        ],
      ),
    );
  }

  Widget _buildSuggestionChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _suggestions.map((amt) {
        final selected = _amountKr == amt;
        return GestureDetector(
          onTap: () => _tap(amt),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color:
                  selected ? kGold.withValues(alpha: 0.12) : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? kGold : const Color(0xFFDDDDDD),
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Text(
              'kr.${_formatAmount(amt)}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? kGold : kBlack,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Schedule card ──────────────────────────────────────────────────────────
  Widget _buildScheduleCard() {
    return Container(
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: Column(
        children: [
          _buildFrequencySelector(),
          if (_frequency == 'Weekly') ...[
            const SizedBox(height: 16),
            _buildDaySelector(),
          ],
        ],
      ),
    );
  }

  Widget _buildFrequencySelector() {
    final freqs = ['Daily', 'Weekly', 'Monthly'];
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: freqs.map((f) {
          final selected = f == _frequency;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _frequency = f);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: selected ? kGold : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                              color: kGold.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2))
                        ]
                      : [],
                ),
                alignment: Alignment.center,
                child: Text(
                  f,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    color: selected ? Colors.white : kSubtitle,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDaySelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: _weekdays.map((day) {
        final selected = _selectedDays.contains(day);
        return GestureDetector(
          onTap: () => _toggleDay(day),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: selected ? kGold : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected ? kGold : const Color(0xFFDDDDDD),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              day,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                color: selected ? Colors.white : kBlack,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Continue button ────────────────────────────────────────────────────────
  Widget _buildContinueButton() {
    final enabled = _amountKr > 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: GestureDetector(
        onTap: enabled ? () {} : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 54,
          decoration: BoxDecoration(
            color: enabled ? kGold : kGold.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(14),
            boxShadow: enabled
                ? [
                    BoxShadow(
                        color: kGold.withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6))
                  ]
                : [],
          ),
          alignment: Alignment.center,
          child: const Text(
            'Continue',
            style: TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  String _formatAmount(int amt) {
    if (amt >= 1000) {
      final s = amt.toString();
      return '${s.substring(0, s.length - 3)},${s.substring(s.length - 3)}';
    }
    return amt.toString();
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
    _ctrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 1))
          ..repeat(reverse: true);
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
        color: const Color(0xFF2ECC71).withValues(alpha: 0.12),
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
                color: Color(0xFF2ECC71),
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
              color: Color(0xFF2ECC71),
            ),
          ),
        ],
      ),
    );
  }
}
