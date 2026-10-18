/*
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:intl/intl.dart';

import '../l10n/generated/support_localizations.dart';

enum SignupRange { week, month, quarter }

/// Line chart of signups over all apps: one point per day for the last week
/// or month, one point per week for the last quarter.
class SignupChart extends StatelessWidget {
  const SignupChart({
    super.key,
    required this.dailyCounts,
    required this.range,
    required this.onRangeChanged,
  });

  final List<SignupDayCount> dailyCounts;
  final SignupRange range;
  final ValueChanged<SignupRange> onRangeChanged;

  static String _isoDate(DateTime date) =>
      DateFormat('yyyy-MM-dd').format(date);

  /// Points oldest first as (first day of the point, count).
  List<(DateTime, int)> _points() {
    final perDay = {for (final day in dailyCounts) day.date: day.count};
    final now = DateTime.now();
    final (points, daysPerPoint) = switch (range) {
      SignupRange.week => (7, 1),
      SignupRange.month => (30, 1),
      SignupRange.quarter => (13, 7),
    };
    return [
      for (var point = points - 1; point >= 0; point--)
        () {
          final first = DateTime(
            now.year,
            now.month,
            now.day - point * daysPerPoint - daysPerPoint + 1,
          );
          var count = 0;
          for (var day = 0; day < daysPerPoint; day++) {
            count +=
                perDay[_isoDate(
                  DateTime(first.year, first.month, first.day + day),
                )] ??
                0;
          }
          return (first, count);
        }(),
    ];
  }

  /// 'Oct 05' on the first label and where the month changes, else '06'.
  String _label(List<(DateTime, int)> points, int index) {
    final every = switch (range) {
      SignupRange.week => 1,
      SignupRange.month => 5,
      SignupRange.quarter => 2,
    };
    // count back from the newest point so today is always labeled
    if ((points.length - 1 - index) % every != 0) return '';
    final date = points[index].$1;
    final previous = index - every >= 0 ? points[index - every].$1 : null;
    return previous == null || previous.month != date.month
        ? DateFormat('MMM dd').format(date)
        : DateFormat('dd').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final localizations = SupportLocalizations.of(context)!;
    final theme = Theme.of(context);
    final points = _points();
    final total = points.fold<int>(0, (sum, point) => sum + point.$2);
    final maxCount = points.fold<int>(
      0,
      (max, point) => point.$2 > max ? point.$2 : max,
    );
    // about 5 whole-number grid lines whatever the counts
    final interval = maxCount <= 5 ? 1.0 : (maxCount / 5).ceilToDouble();
    final maxY = maxCount == 0 ? 5.0 : (maxCount / interval).ceil() * interval;
    final labelStyle = theme.textTheme.bodySmall?.copyWith(fontSize: 11);
    final lineColor = theme.colorScheme.primary;

    return Card(
      key: const Key('signupChart'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 28, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    localizations.signupsCount(total),
                    key: const Key('signupChartTotal'),
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                DropdownButton<SignupRange>(
                  key: const Key('signupRangeDropDown'),
                  value: range,
                  items: [
                    DropdownMenuItem(
                      value: SignupRange.week,
                      child: Text(localizations.signupRangeWeek),
                    ),
                    DropdownMenuItem(
                      value: SignupRange.month,
                      child: Text(localizations.signupRangeMonth),
                    ),
                    DropdownMenuItem(
                      value: SignupRange.quarter,
                      child: Text(localizations.signupRangeQuarter),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) onRangeChanged(value);
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: (points.length - 1).toDouble(),
                  minY: 0,
                  maxY: maxY,
                  gridData: FlGridData(
                    drawVerticalLine: false,
                    horizontalInterval: interval,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: theme.colorScheme.outlineVariant,
                      strokeWidth: 0.5,
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      left: BorderSide(color: theme.colorScheme.outline),
                      bottom: BorderSide(color: theme.colorScheme.outline),
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(),
                    rightTitles: const AxisTitles(),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: interval,
                        reservedSize: 32,
                        getTitlesWidget: (value, meta) =>
                            Text(value.toInt().toString(), style: labelStyle),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        reservedSize: 24,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= points.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              _label(points, index),
                              style: labelStyle,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      fitInsideHorizontally: true,
                      fitInsideVertically: true,
                      getTooltipColor: (_) => theme.colorScheme.inverseSurface,
                      getTooltipItems: (spots) => [
                        for (final spot in spots)
                          LineTooltipItem(
                            '${_isoDate(points[spot.x.toInt()].$1)}\n'
                            '${spot.y.toInt()}',
                            TextStyle(
                              color: theme.colorScheme.onInverseSurface,
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      isCurved: true,
                      preventCurveOverShooting: true,
                      color: lineColor,
                      barWidth: 2.5,
                      dotData: FlDotData(
                        getDotPainter: (spot, percent, bar, index) =>
                            FlDotCirclePainter(
                              radius: 3.5,
                              color: lineColor,
                              strokeWidth: 1.5,
                              strokeColor: theme.colorScheme.surface,
                            ),
                      ),
                      spots: [
                        for (var i = 0; i < points.length; i++)
                          FlSpot(i.toDouble(), points[i].$2.toDouble()),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
