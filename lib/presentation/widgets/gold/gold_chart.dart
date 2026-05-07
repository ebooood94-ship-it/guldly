import 'package:flutter/material.dart';
import 'package:guldly/core/constants/app_constants.dart';

class GoldChart extends StatelessWidget {
  final String selectedPeriod;
  final Function(String) onPeriodChanged;

  const GoldChart({
    super.key,
    required this.selectedPeriod,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppConstants.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Gold',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppConstants.black,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Performance over time',
            style: TextStyle(fontSize: 13, color: AppConstants.subtitle),
          ),
          const SizedBox(height: 12),
          const SizedBox(height: 140, child: _GoldLineChart()),
          const SizedBox(height: 12),
          _buildPeriodSelector(),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    final periods = ['1D', '1W', '1M'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: periods.map((p) {
        final isSelected = p == selectedPeriod;
        return GestureDetector(
          onTap: () => onPeriodChanged(p),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 6),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected ? AppConstants.gold : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              p,
              style: TextStyle(
                color: isSelected ? Colors.white : AppConstants.subtitle,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _GoldLineChart extends StatelessWidget {
  const _GoldLineChart();

  static const List<double> _points = [
    0.05,
    0.08,
    0.12,
    0.09,
    0.15,
    0.13,
    0.20,
    0.18,
    0.25,
    0.30,
    0.27,
    0.35,
    0.38,
    0.33,
    0.42,
    0.45,
    0.50,
    0.47,
    0.55,
    0.60,
    0.58,
    0.65,
    0.70,
    0.75,
    0.72,
    0.80,
    0.85,
    0.82,
    0.90,
    1.0,
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, constraints) => CustomPaint(
        size: Size(constraints.maxWidth, constraints.maxHeight),
        painter: _ChartPainter(_points),
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<double> points;
  _ChartPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    const labelPadding = 14.0;
    final chartH = h - labelPadding * 2;

    final path = Path();
    final fillPath = Path();

    for (var i = 0; i < points.length; i++) {
      final x = i / (points.length - 1) * w;
      final y = labelPadding + (1 - points[i]) * chartH;
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, y);
      } else {
        final prevX = (i - 1) / (points.length - 1) * w;
        final prevY = labelPadding + (1 - points[i - 1]) * chartH;
        final cpX = (prevX + x) / 2;
        path.cubicTo(cpX, prevY, cpX, y, x, y);
        fillPath.cubicTo(cpX, prevY, cpX, y, x, y);
      }
    }

    fillPath.lineTo(w, h);
    fillPath.lineTo(0, h);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppConstants.gold.withValues(alpha: 0.25),
          AppConstants.gold.withValues(alpha: 0.0)
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = AppConstants.gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    canvas.drawPath(path, linePaint);

    final endX = w;
    final endY = labelPadding + (1 - points.last) * chartH;
    canvas.drawCircle(
        Offset(endX, endY), 5, Paint()..color = AppConstants.gold);
    canvas.drawCircle(
      Offset(endX, endY),
      5,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
