import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/providers.dart';
import '../../widgets/common/back_header.dart';
import '../../widgets/common/section_label.dart';

class CalculatorScreen extends ConsumerStatefulWidget {
  const CalculatorScreen({super.key});

  @override
  ConsumerState<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends ConsumerState<CalculatorScreen> {
  final _monthlyCtrl = TextEditingController(text: '100');
  final _periodCtrl = TextEditingController(text: '12');
  final _returnCtrl = TextEditingController(text: '8');

  @override
  void dispose() {
    _monthlyCtrl.dispose();
    _periodCtrl.dispose();
    _returnCtrl.dispose();
    super.dispose();
  }

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

  String _fmt(double v) =>
      NumberFormat('#,##0', 'sv_SE').format(v).replaceAll(',', ' ');

  @override
  Widget build(BuildContext context) {
    final goldAsync = ref.watch(goldPriceProvider);

    return Scaffold(
      backgroundColor: AppConstants.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const BackHeader(title: 'Kalkylator'),
              const SizedBox(height: 16),
              goldAsync.when(
                data: (g) => Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppConstants.goldLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppConstants.gold.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Live guldpris',
                          style: GoogleFonts.inter(
                              fontSize: 13, color: AppConstants.subtitle)),
                      Text(
                        '${_fmt(g.pricePerGramSek)} kr/g',
                        style: GoogleFonts.inter(
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
              const SizedBox(height: AppConstants.sectionGap),
              const SectionLabel('INMATNING'),
              Container(
                decoration: BoxDecoration(
                  color: AppConstants.card,
                  borderRadius: BorderRadius.circular(AppConstants.cardRadius),
                  border: Border.all(color: AppConstants.divider, width: 1),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _CalcField(
                      label: 'MÅNADSBELOPP',
                      controller: _monthlyCtrl,
                      suffix: 'kr',
                      onChanged: () => setState(() {}),
                    ),
                    const Divider(height: 24, color: AppConstants.divider),
                    _CalcField(
                      label: 'SPARPERIOD',
                      controller: _periodCtrl,
                      suffix: 'månader',
                      onChanged: () => setState(() {}),
                    ),
                    const Divider(height: 24, color: AppConstants.divider),
                    _CalcField(
                      label: 'FÖRVÄNTAD ÅRSAVKASTNING',
                      controller: _returnCtrl,
                      suffix: '%',
                      onChanged: () => setState(() {}),
                    ),
                  ],
                ),
              ),
              if (_monthly > 0 && _period > 0) ...[
                const SizedBox(height: AppConstants.sectionGap),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppConstants.card,
                    borderRadius:
                        BorderRadius.circular(AppConstants.cardRadius),
                    border: Border.all(color: AppConstants.divider, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Tillväxtprognos',
                              style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppConstants.black)),
                          Text(
                            '${_period.toInt()} månader',
                            style: GoogleFonts.inter(
                                fontSize: 12, color: AppConstants.subtitle),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_fmt(_totalInvestment)} kr investerat → ${_fmt(_projectedValue)} kr',
                        style: GoogleFonts.inter(
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
              ],
              const SizedBox(height: AppConstants.sectionGap),
              const SectionLabel('PROGNOS'),
              Container(
                decoration: BoxDecoration(
                  color: AppConstants.card,
                  borderRadius: BorderRadius.circular(AppConstants.cardRadius),
                  border: Border.all(color: AppConstants.divider, width: 1),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _ResultRow(
                      label: 'Total investering',
                      value: '${_fmt(_totalInvestment)} kr',
                      color: AppConstants.black,
                    ),
                    const Divider(height: 20, color: AppConstants.divider),
                    _ResultRow(
                      label: 'Prognostiserat värde',
                      value: '${_fmt(_projectedValue)} kr',
                      color: AppConstants.black,
                    ),
                    const Divider(height: 20, color: AppConstants.divider),
                    _ResultRow(
                      label: 'Total avkastning',
                      value: '${_fmt(_totalReturn)} kr',
                      color: AppConstants.green,
                    ),
                  ],
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
  final TextEditingController controller;
  final String suffix;
  final VoidCallback onChanged;

  const _CalcField({
    required this.label,
    required this.controller,
    required this.suffix,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppConstants.subtitle,
              letterSpacing: 1.0,
            )),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          onChanged: (_) => onChanged(),
          keyboardType: TextInputType.number,
          style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppConstants.black),
          decoration: InputDecoration(
            suffixText: suffix,
            suffixStyle: GoogleFonts.inter(
                color: AppConstants.subtitle, fontSize: 13),
            filled: true,
            fillColor: AppConstants.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppConstants.divider),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppConstants.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: AppConstants.gold, width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }
}

class _ResultRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ResultRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 13, color: AppConstants.subtitle)),
        Text(value,
            style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color)),
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
        painter: _ProjectionPainter(
            points: points, invested: invested, projected: projected),
      ),
    );
  }
}

class _ProjectionPainter extends CustomPainter {
  final List<double> points;
  final double invested;
  final double projected;

  _ProjectionPainter(
      {required this.points,
      required this.invested,
      required this.projected});

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
            AppConstants.gold.withValues(alpha: 0.18),
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

    final endY = labelH + (1 - points.last) * chartH;
    canvas.drawCircle(
        Offset(w, endY), 4.5, Paint()..color = AppConstants.gold);
    canvas.drawCircle(
      Offset(w, endY),
      4.5,
      Paint()
        ..color = AppConstants.card
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    if (projected > 0 && invested > 0) {
      final investedNorm = invested / projected;
      final investedY = labelH + (1 - investedNorm) * chartH;
      final dashPaint = Paint()
        ..color = AppConstants.subtitle.withValues(alpha: 0.4)
        ..strokeWidth = 1;
      var x = 0.0;
      while (x < w) {
        canvas.drawLine(
            Offset(x, investedY), Offset(x + 6, investedY), dashPaint);
        x += 12;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ProjectionPainter old) =>
      old.points != points ||
      old.invested != invested ||
      old.projected != projected;
}
