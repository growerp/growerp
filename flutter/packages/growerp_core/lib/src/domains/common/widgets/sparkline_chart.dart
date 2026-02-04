/*
 * This software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 * 
 * To the extent possible under law, the author(s) have dedicated all
 * copyright and related and neighboring rights to this software to the
 * public domain worldwide. This software is distributed without any
 * warranty.
 * 
 * You should have received a copy of the CC0 Public Domain Dedication
 * along with this software (see the LICENSE.md file). If not, see
 * <http://creativecommons.org/publicdomain/zero/1.0/>.
 */

import 'package:flutter/material.dart';
import 'dart:math' as math;

/// A mini sparkline chart widget for displaying trend data in compact spaces.
///
/// Perfect for dashboard cards, list items, and anywhere a quick visual
/// representation of data trends is needed.
///
/// Usage:
/// ```dart
/// SparklineChart(
///   data: [10, 25, 15, 30, 22, 35],
///   height: 32,
/// )
/// ```
class SparklineChart extends StatelessWidget {
  /// The data points to plot
  final List<double> data;

  /// Height of the chart
  final double height;

  /// Width of the chart (defaults to expand to available width)
  final double? width;

  /// Color of the line (defaults to theme primary)
  final Color? lineColor;

  /// Whether to show the gradient fill below the line
  final bool showGradientFill;

  /// Whether to show dots at each data point
  final bool showDots;

  /// Line thickness
  final double strokeWidth;

  /// Whether to show the trend indicator (up/down arrow)
  final bool showTrendIndicator;

  const SparklineChart({
    super.key,
    required this.data,
    this.height = 32,
    this.width,
    this.lineColor,
    this.showGradientFill = true,
    this.showDots = false,
    this.strokeWidth = 2.0,
    this.showTrendIndicator = false,
  });

  /// Calculates the trend direction based on comparing first and last data points
  double get trend {
    if (data.length < 2) return 0;
    return data.last - data.first;
  }

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return SizedBox(height: height, width: width);
    }

    final colorScheme = Theme.of(context).colorScheme;
    final effectiveLineColor = lineColor ?? colorScheme.primary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: height,
          width: width ?? 80,
          child: CustomPaint(
            painter: _SparklinePainter(
              data: data,
              lineColor: effectiveLineColor,
              showGradientFill: showGradientFill,
              showDots: showDots,
              strokeWidth: strokeWidth,
            ),
          ),
        ),
        if (showTrendIndicator && data.length >= 2) ...[
          const SizedBox(width: 4),
          Icon(
            trend >= 0 ? Icons.trending_up : Icons.trending_down,
            size: 14,
            color: trend >= 0
                ? const Color(0xFF10B981) // success color
                : const Color(0xFFEF4444), // danger color
          ),
        ],
      ],
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> data;
  final Color lineColor;
  final bool showGradientFill;
  final bool showDots;
  final double strokeWidth;

  _SparklinePainter({
    required this.data,
    required this.lineColor,
    required this.showGradientFill,
    required this.showDots,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final double minValue = data.reduce(math.min);
    final double maxValue = data.reduce(math.max);
    final double range = maxValue - minValue;
    final double padding = size.height * 0.1;
    final double chartHeight = size.height - (padding * 2);

    double normalizeY(double value) {
      if (range == 0) return size.height / 2;
      return padding + chartHeight - ((value - minValue) / range * chartHeight);
    }

    final double xStep = size.width / (data.length - 1);

    // Create path for the line
    final path = Path();
    path.moveTo(0, normalizeY(data.first));

    for (int i = 1; i < data.length; i++) {
      path.lineTo(i * xStep, normalizeY(data[i]));
    }

    // Draw gradient fill
    if (showGradientFill) {
      final fillPath = Path.from(path);
      fillPath.lineTo(size.width, size.height);
      fillPath.lineTo(0, size.height);
      fillPath.close();

      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            lineColor.withValues(alpha: 0.3),
            lineColor.withValues(alpha: 0.05),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

      canvas.drawPath(fillPath, fillPaint);
    }

    // Draw the line
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, linePaint);

    // Draw dots at each data point
    if (showDots) {
      final dotPaint = Paint()
        ..color = lineColor
        ..style = PaintingStyle.fill;

      for (int i = 0; i < data.length; i++) {
        canvas.drawCircle(
          Offset(i * xStep, normalizeY(data[i])),
          strokeWidth * 1.2,
          dotPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.showGradientFill != showGradientFill ||
        oldDelegate.showDots != showDots ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

/// A widget that combines a SparklineChart with a trend label
class SparklineTrend extends StatelessWidget {
  final List<double> data;
  final String? label;
  final double height;
  final double? width;
  final Color? lineColor;

  const SparklineTrend({
    super.key,
    required this.data,
    this.label,
    this.height = 28,
    this.width,
    this.lineColor,
  });

  double get percentChange {
    if (data.length < 2 || data.first == 0) return 0;
    return ((data.last - data.first) / data.first) * 100;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isPositive = percentChange >= 0;
    final trendColor = isPositive
        ? const Color(0xFF10B981) // success
        : const Color(0xFFEF4444); // danger

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SparklineChart(
          data: data,
          height: height,
          width: width,
          lineColor: lineColor ?? trendColor,
          showGradientFill: true,
        ),
        if (label != null || percentChange != 0) ...[
          const SizedBox(width: 8),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (label != null)
                Text(
                  label!,
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                    size: 12,
                    color: trendColor,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '${percentChange.abs().toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: trendColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ],
    );
  }
}
