import 'package:flutter/material.dart';
import 'package:guldly/core/constants/app_constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/common/back_header.dart';
import 'package:intl/intl.dart';
import '../../widgets/common/gold_card.dart';

class CalculatorScreen extends ConsumerStatefulWidget {
  const CalculatorScreen({super.key});

  @override
  ConsumerState<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends ConsumerState<CalculatorScreen> {
  final _monthlyCtrl = TextEditingController(text: '100');
  final _periodCtrl = TextEditingController(text: '12');
  final _returnCtrl = TextEditingController(text: '8');

  double get _monthly => double.tryParse(_monthlyCtrl.text) ?? 0;
  double get _period => double.tryParse(_periodCtrl.text) ?? 0;
  double get _annualReturn => (double.tryParse(_returnCtrl.text) ?? 0) / 100;

  double get _totalInvestment => _monthly * _period;
  double get _projectedValue {
    if (_period == 0 || _monthly == 0) return 0;
    final monthlyRate = _annualReturn / 12;
    if (monthlyRate == 0) return _totalInvestment;
    return _monthly *
        ((pow(1 + monthlyRate, _period) - 1) / monthlyRate) *
        (1 + monthlyRate);
  }

  double get _totalReturn => _projectedValue - _totalInvestment;

  double pow(double base, double exp) {
    double result = 1;
    for (var i = 0; i < exp; i++) {
      result *= base;
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const BackHeader(title: 'Calculator'),
              const SizedBox(height: 24),
              GoldCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _CalcField('Monthly Investment', _monthlyCtrl, 'SEK',
                          () => setState(() {})),
                      const SizedBox(height: 16),
                      _CalcField('Investment Period', _periodCtrl, 'months',
                          () => setState(() {})),
                      const SizedBox(height: 16),
                      _CalcField('Expected Annual Return', _returnCtrl, '%',
                          () => setState(() {})),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Projections',
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
                      _ProjectionRow(
                          'Total Investment',
                          'kr.${NumberFormat('#,###').format(_totalInvestment)}',
                          AppConstants.black),
                      const SizedBox(height: 12),
                      _ProjectionRow(
                          'Projected Value',
                          'kr.${NumberFormat('#,###').format(_projectedValue)}',
                          AppConstants.black),
                      const SizedBox(height: 12),
                      _ProjectionRow(
                          'Total Return',
                          'kr.${NumberFormat('#,###').format(_totalReturn)}',
                          AppConstants.green),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _CalcField extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  final String suffix;
  final VoidCallback onChanged;
  const _CalcField(this.label, this.ctrl, this.suffix, this.onChanged);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 13, color: AppConstants.subtitle)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          onChanged: (_) => onChanged(),
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            suffixText: suffix,
            suffixStyle: const TextStyle(color: AppConstants.subtitle),
            filled: true,
            fillColor: const Color(0xFFF5F5F5),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}

class _ProjectionRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  const _ProjectionRow(this.label, this.value, this.valueColor);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 14, color: AppConstants.subtitle)),
        Text(value,
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600, color: valueColor)),
      ],
    );
  }
}
