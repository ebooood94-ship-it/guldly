import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:guldly/core/constants/app_constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/providers.dart';
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
        ((math.pow(1 + monthlyRate, _period) - 1) / monthlyRate) *
        (1 + monthlyRate);
  }

  double get _totalReturn => _projectedValue - _totalInvestment;

  /// Returns normalized [0,1] portfolio value at each month from 0.._period.
  List<double> _buildChartPoints() {
    final months = _period.toInt().clamp(2, 360);
    final monthlyRate = _annualReturn / 12;
    final points = <double>[];
    double maxVal = 0;
    for (var m = 0; m <= months; m++) {
      double val;
      if (monthlyRate == 0) {
        val = _monthly * m;
      } else {
        val = _monthly *
            ((math.pow(1 + monthlyRate, m) - 1) / monthlyRate) *
            (1 + monthlyRate);
      }
      points.add(val);
      if (val > maxVal) maxVal = val;
    }
    if (maxVal == 0) return List.filled(points.length, 0.0);
    return points.map((v) => v / maxVal).toList();
  }

  @override
  Widget build(BuildContext context) {
    final goldAsync = ref.watch(goldPriceProvider);

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
              const SizedBox(height: 16),
              goldAsync.when(
                data: (g) => Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppConstants.gold.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppConstants.gold.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Live gold price',
                          style: TextStyle(
                              fontSize: 13, color: AppConstants.subtitle)),
                      Text(
                        'kr.${NumberFormat('#,###.##').format(g.pricePerGramSek)}/g',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppConstants.gold),
                      ),
                    ],
                  ),
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 16),
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
              // Growth chart
              if (_monthly > 0 && _period > 0) ...[
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 3))
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Growth Projection',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppConstants.black)),
                          Text(
                            '${_period.toInt()} months',
                            style: const TextStyle(
                                fontSize: 12, color: AppConstants.subtitle),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'kr.${NumberFormat('#,###').format(_totalInvestment)} invested → kr.${NumberFormat('#,###').format(_projectedValue)}',
                        style: const TextStyle(
                            fontSize: 11, color: AppConstants.subtitle),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 120,
                        child: _ProjectionChart(
                          points: _buildChartPoints(),
                          invested: _totalInvestment,
                          projected: _projectedValue,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
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

class _ProjectionChart extends StatelessWidget {
  final List<double> points;
  final double invested;
  final double projected;

  const _ProjectionChart({
    required this.points,
    required this.invested,
    required this.projected,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) => CustomPaint(
        size: Size(constraints.maxWidth, constraints.maxHeight),
        painter: _ProjectionPainter(points: points, invested: invested, projected: projected),
      ),
    );
  }
}

class _ProjectionPainter extends CustomPainter {
  final List<double> points;
  final double invested;
  final double projected;

  _ProjectionPainter({required this.points, required this.invested, required this.projected});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final w = size.width;
    final h = size.height;
    const labelH = 16.0;
    final chartH = h - labelH;

    final path = Path();
    final fillPath = Path();

    for (var i = 0; i < points.length; i++) {
      final x = i / (points.length - 1) * w;
      final y = labelH + (1 - points[i]) * chartH;
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, y);
      } else {
        final prevX = (i - 1) / (points.length - 1) * w;
        final prevY = labelH + (1 - points[i - 1]) * chartH;
        final cpX = (prevX + x) / 2;
        path.cubicTo(cpX, prevY, cpX, y, x, y);
        fillPath.cubicTo(cpX, prevY, cpX, y, x, y);
      }
    }

    fillPath.lineTo(w, h);
    fillPath.lineTo(0, h);
    fillPath.close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppConstants.gold.withValues(alpha: 0.20),
            AppConstants.gold.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = AppConstants.gold
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Dot at end
    final endY = labelH + (1 - points.last) * chartH;
    canvas.drawCircle(Offset(w, endY), 4.5, Paint()..color = AppConstants.gold);
    canvas.drawCircle(
      Offset(w, endY),
      4.5,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Dashed invested line (straight)
    if (projected > 0 && invested > 0) {
      final investedNorm = invested / projected;
      final investedY = labelH + (1 - investedNorm) * chartH;
      final dashPaint = Paint()
        ..color = AppConstants.subtitle.withValues(alpha: 0.4)
        ..strokeWidth = 1;
      var x = 0.0;
      while (x < w) {
        canvas.drawLine(Offset(x, investedY), Offset(x + 6, investedY), dashPaint);
        x += 12;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ProjectionPainter old) =>
      old.points != points || old.invested != invested || old.projected != projected;
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
