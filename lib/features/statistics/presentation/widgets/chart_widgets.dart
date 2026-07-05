import 'dart:math';
import 'package:flutter/material.dart';
import '../../statistics_models.dart';

/// Renders a beautiful area chart with a gradient fill under the curve.
class GradientAreaChart extends StatelessWidget {
  final List<ChartDataPoint> data;
  final String title;
  final Color themeColor;
  final String valueSuffix;

  const GradientAreaChart({
    super.key,
    required this.data,
    required this.title,
    required this.themeColor,
    this.valueSuffix = '',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (data.isEmpty) {
      return Center(
        child: Text('No data available', style: theme.textTheme.bodyMedium),
      );
    }

    final maxVal = data.map((d) => d.value).fold<double>(1.0, (m, v) => max(m, v));

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 1000),
                curve: Curves.fastOutSlowIn,
                builder: (context, animVal, _) {
                  return CustomPaint(
                    size: Size.infinite,
                    painter: _AreaChartPainter(
                      data: data,
                      maxVal: maxVal,
                      color: themeColor,
                      animProgress: animVal,
                      isDark: isDark,
                      gridColor: theme.colorScheme.outlineVariant,
                      labelColor: theme.colorScheme.onSurfaceVariant,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AreaChartPainter extends CustomPainter {
  final List<ChartDataPoint> data;
  final double maxVal;
  final Color color;
  final double animProgress;
  final bool isDark;
  final Color gridColor;
  final Color labelColor;

  _AreaChartPainter({
    required this.data,
    required this.maxVal,
    required this.color,
    required this.animProgress,
    required this.isDark,
    required this.gridColor,
    required this.labelColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paddingLeft = 32.0;
    final paddingBottom = 24.0;
    final chartWidth = size.width - paddingLeft;
    final chartHeight = size.height - paddingBottom;

    if (chartWidth <= 0 || chartHeight <= 0) return;

    final gridPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.15)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()..style = PaintingStyle.fill;

    // Draw horizontal gridlines and Y-axis labels
    final steps = 4;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int i = 0; i <= steps; i++) {
      final y = chartHeight - (chartHeight / steps) * i;
      final val = (maxVal / steps) * i;
      
      canvas.drawLine(Offset(paddingLeft, y), Offset(size.width, y), gridPaint);
      
      textPainter.text = TextSpan(
        text: val.toStringAsFixed(val < 10 ? 1 : 0),
        style: TextStyle(color: labelColor.withValues(alpha: 0.6), fontSize: 9),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(0, y - 6));
    }

    // Map data points
    final points = <Offset>[];
    final dxStep = data.length > 1 ? chartWidth / (data.length - 1) : chartWidth;
    for (int i = 0; i < data.length; i++) {
      final val = data[i].value;
      final x = paddingLeft + i * dxStep;
      final y = chartHeight - (val / maxVal) * chartHeight * animProgress;
      points.add(Offset(x, y));
    }

    // Area Fill Path
    if (points.isNotEmpty) {
      final fillPath = Path()
        ..moveTo(paddingLeft, chartHeight);
      for (final p in points) {
        fillPath.lineTo(p.dx, p.dy);
      }
      fillPath.lineTo(points.last.dx, chartHeight);
      fillPath.close();

      fillPaint.shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: 0.4),
          color.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTRB(paddingLeft, 0, size.width, chartHeight));

      canvas.drawPath(fillPath, fillPaint);

      // Draw line path
      final linePath = Path()..moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        linePath.lineTo(points[i].dx, points[i].dy);
      }
      canvas.drawPath(linePath, linePaint);

      // Draw data dots and X-axis labels
      final dotPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      final dotBorder = Paint()
        ..color = isDark ? Colors.black : Colors.white;

      for (int i = 0; i < points.length; i++) {
        final p = points[i];
        canvas.drawCircle(p, 4.5, dotPaint);
        canvas.drawCircle(p, 2.5, dotBorder);

        // X Label
        textPainter.text = TextSpan(
          text: data[i].label,
          style: TextStyle(color: labelColor, fontSize: 9, fontWeight: FontWeight.w500),
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(p.dx - textPainter.width / 2, chartHeight + 6));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _AreaChartPainter oldDelegate) =>
      oldDelegate.animProgress != animProgress || oldDelegate.data != data;
}

/// Renders a beautiful bar chart with vertical bars.
class DistributionBarChart extends StatelessWidget {
  final List<ChartDataPoint> data;
  final String title;
  final Color themeColor;

  const DistributionBarChart({
    super.key,
    required this.data,
    required this.title,
    required this.themeColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (data.isEmpty) {
      return Center(
        child: Text('No data available', style: theme.textTheme.bodyMedium),
      );
    }

    final maxVal = data.map((d) => d.value).fold<double>(1.0, (m, v) => max(m, v));

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 1000),
                curve: Curves.fastOutSlowIn,
                builder: (context, animVal, _) {
                  return CustomPaint(
                    size: Size.infinite,
                    painter: _BarChartPainter(
                      data: data,
                      maxVal: maxVal,
                      color: themeColor,
                      animProgress: animVal,
                      gridColor: theme.colorScheme.outlineVariant,
                      labelColor: theme.colorScheme.onSurfaceVariant,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final List<ChartDataPoint> data;
  final double maxVal;
  final Color color;
  final double animProgress;
  final Color gridColor;
  final Color labelColor;

  _BarChartPainter({
    required this.data,
    required this.maxVal,
    required this.color,
    required this.animProgress,
    required this.gridColor,
    required this.labelColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paddingLeft = 32.0;
    final paddingBottom = 24.0;
    final chartWidth = size.width - paddingLeft;
    final chartHeight = size.height - paddingBottom;

    if (chartWidth <= 0 || chartHeight <= 0) return;

    final gridPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.15)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final barPaint = Paint()..style = PaintingStyle.fill;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // Grid lines
    final steps = 4;
    for (int i = 0; i <= steps; i++) {
      final y = chartHeight - (chartHeight / steps) * i;
      final val = (maxVal / steps) * i;
      canvas.drawLine(Offset(paddingLeft, y), Offset(size.width, y), gridPaint);
      textPainter.text = TextSpan(
        text: val.toStringAsFixed(val < 10 ? 1 : 0),
        style: TextStyle(color: labelColor.withValues(alpha: 0.6), fontSize: 9),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(0, y - 6));
    }

    final barCount = data.length;
    final rawBarWidth = chartWidth / (barCount * 1.5 + 0.5);
    final spacing = rawBarWidth * 0.5;

    for (int i = 0; i < barCount; i++) {
      final val = data[i].value;
      final h = (val / maxVal) * chartHeight * animProgress;
      
      final left = paddingLeft + spacing + i * (rawBarWidth + spacing);
      final right = left + rawBarWidth;
      final top = chartHeight - h;
      final bottom = chartHeight;

      // Draw rounded bar
      barPaint.shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color, color.withValues(alpha: 0.6)],
      ).createShader(Rect.fromLTRB(left, top, right, bottom));

      final rrect = RRect.fromRectAndCorners(
        Rect.fromLTRB(left, top, right, bottom),
        topLeft: const Radius.circular(6),
        topRight: const Radius.circular(6),
      );
      canvas.drawRRect(rrect, barPaint);

      // Label below
      textPainter.text = TextSpan(
        text: data[i].label,
        style: TextStyle(color: labelColor, fontSize: 9, fontWeight: FontWeight.w500),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(left + (rawBarWidth - textPainter.width) / 2, chartHeight + 6));
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) =>
      oldDelegate.animProgress != animProgress || oldDelegate.data != data;
}

/// Renders a beautiful donut/pie success chart.
class DonutChart extends StatelessWidget {
  final List<ChartDataPoint> data;
  final String title;

  const DonutChart({
    super.key,
    required this.data,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (data.isEmpty) {
      return Center(
        child: Text('No data available', style: theme.textTheme.bodyMedium),
      );
    }

    final total = data.fold<double>(0.0, (sum, d) => sum + d.value);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 1000),
                      curve: Curves.fastOutSlowIn,
                      builder: (context, animVal, _) {
                        return CustomPaint(
                          size: Size.infinite,
                          painter: _DonutChartPainter(
                            data: data,
                            total: total,
                            animProgress: animVal,
                            isDark: theme.brightness == Brightness.dark,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: data.map((d) {
                        final percentage = total > 0 ? (d.value / total) * 100 : 0.0;
                        final color = d.label == 'Success' ? Colors.green : Colors.red;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            children: [
                              Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${d.label}: ${percentage.toStringAsFixed(1)}%',
                                  style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final List<ChartDataPoint> data;
  final double total;
  final double animProgress;
  final bool isDark;

  _DonutChartPainter({
    required this.data,
    required this.total,
    required this.animProgress,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 8;

    if (radius <= 0) return;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14.0
      ..strokeCap = StrokeCap.round;

    double startAngle = -pi / 2;

    for (final segment in data) {
      final value = segment.value;
      final sweepAngle = total > 0 ? (value / total) * 2 * pi * animProgress : 0.0;
      paint.color = segment.label == 'Success' ? Colors.green : Colors.red;

      // Draw arc
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );

      startAngle += sweepAngle;
    }

    // Inside text painter
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final successRate = data.firstWhere((d) => d.label == 'Success', orElse: () => const ChartDataPoint(label: 'Success', value: 0)).value;
    final rate = total > 0 ? (successRate / total) * 100 : 100.0;

    textPainter.text = TextSpan(
      text: '${rate.toStringAsFixed(0)}%',
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white : Colors.black,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2));
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) =>
      oldDelegate.animProgress != animProgress || oldDelegate.data != data;
}

/// Animated radial Health Score dial.
class HealthDial extends StatelessWidget {
  final int score;

  const HealthDial({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color dialColor = Colors.green;
    if (score < 50) {
      dialColor = Colors.red;
    } else if (score < 80) {
      dialColor = Colors.orange;
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: score.toDouble()),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.fastOutSlowIn,
      builder: (context, val, _) {
        return CustomPaint(
          size: const Size(180, 180),
          painter: _HealthDialPainter(
            score: val,
            color: dialColor,
            isDark: isDark,
            trackColor: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        );
      },
    );
  }
}

class _HealthDialPainter extends CustomPainter {
  final double score;
  final Color color;
  final bool isDark;
  final Color trackColor;

  _HealthDialPainter({
    required this.score,
    required this.color,
    required this.isDark,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 12;

    // Track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16.0;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi * 0.75,
      pi * 1.5,
      false,
      trackPaint,
    );

    // Active score arc
    final activePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16.0
      ..strokeCap = StrokeCap.round;

    final sweepAngle = (score / 100.0) * pi * 1.5;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi * 0.75,
      sweepAngle,
      false,
      activePaint,
    );

    // Draw central score value
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    
    textPainter.text = TextSpan(
      text: score.toStringAsFixed(0),
      style: TextStyle(
        fontSize: 48,
        fontWeight: FontWeight.w900,
        color: color,
        letterSpacing: -1,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2 - 10));

    // Draw subtitle "Health Score"
    textPainter.text = TextSpan(
      text: 'HEALTH SCORE',
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white54 : Colors.black54,
        letterSpacing: 1.5,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(center.dx - textPainter.width / 2, center.dy + 30));
  }

  @override
  bool shouldRepaint(covariant _HealthDialPainter oldDelegate) =>
      oldDelegate.score != score || oldDelegate.color != color;
}
