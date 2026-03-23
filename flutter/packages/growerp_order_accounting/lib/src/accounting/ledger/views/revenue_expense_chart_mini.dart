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

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:intl/intl.dart';
import 'package:growerp_order_accounting/l10n/generated/order_accounting_localizations.dart';

import '../../accounting.dart';

/// Compact revenue/expense line chart for embedding in a dashboard tile.
///
/// Shows only the LineChart for the current year — no period navigation.
/// Set the tile's `tileType='graphic'` in the MenuItem config to get the 2×2 size.
class RevenueExpenseChartMini extends StatelessWidget {
  const RevenueExpenseChartMini({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LedgerBloc(context.read<RestClient>())
        ..add(
          LedgerFetch(
            ReportType.revenueExpense,
            periodName: 'Y${DateTime.now().year}',
          ),
        ),
      child: const _RevenueExpenseChartMiniBody(),
    );
  }
}

class _RevenueExpenseChartMiniBody extends StatelessWidget {
  const _RevenueExpenseChartMiniBody();

  Color _getColor(BuildContext context, int index) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return switch (index) {
      0 => cs.success, // Net Revenue — emerald green
      1 => cs.danger, // Cost of Sales — red
      2 => cs.info, // Sales Expenses — blue
      3 => cs.warning, // G&A Expenses — amber
      4 => isDark
          ? const Color(0xFFC084FC)
          : const Color(0xFF7C3AED), // Other Exp — violet
      _ => isDark
          ? const Color(0xFF38BDF8)
          : const Color(0xFF0284C7), // Net Op Income — sky blue
    };
  }

  Widget _buildEmptyChart(
    BuildContext context,
    List<String> months, {
    bool showLabel = true,
  }) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lineColor = cs.onSurface.withValues(alpha: 0.18);
    final gridColor = cs.onSurface.withValues(alpha: 0.08);
    final labelColor = cs.onSurface.withValues(alpha: 0.3);

    // Shaped placeholder data mirroring a typical revenue/expense pattern
    // (6 series × 12 months): net revenue, cost of sales, sales exp,
    // gen/admin exp, other exp, net operating income
    const placeholderData = [
      [20, 25, 35, 45, 60, 80, 110, 140, 160, 130, 90, 40],
      [10, 12, 18, 22, 30, 40, 55, 70, 80, 65, 45, 20],
      [5, 5, 6, 7, 8, 9, 10, 11, 10, 8, 7, 5],
      [8, 9, 10, 12, 14, 16, 18, 20, 22, 20, 17, 12],
      [1, 1, 2, 2, 2, 3, 3, 3, 2, 2, 1, 1],
      [5, 6, 8, 10, 14, 18, 24, 30, 35, 20, 10, -5],
    ];

    final dummyLines = placeholderData
        .map(
          (series) => LineChartBarData(
            spots: [
              for (int x = 0; x < series.length; x++)
                FlSpot((x + 1).toDouble(), series[x].toDouble()),
            ],
            isCurved: true,
            preventCurveOverShooting: true,
            color: lineColor,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
        )
        .toList();

    return Stack(
      fit: StackFit.expand,
      children: [
        // Dimmed placeholder chart
        Padding(
          padding: const EdgeInsets.all(8),
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 40,
                getDrawingHorizontalLine: (_) =>
                    FlLine(color: gridColor, strokeWidth: 1),
              ),
              titlesData: FlTitlesData(
                show: true,
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    reservedSize: 20,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt() - 1;
                      if (idx < 0 || idx >= months.length) {
                        return const SizedBox.shrink();
                      }
                      if (idx % 3 != 0) return const SizedBox.shrink();
                      return Text(
                        months[idx],
                        style: TextStyle(fontSize: 9, color: labelColor),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: dummyLines,
              minY: -10,
              maxY: 170,
              clipData: const FlClipData.all(),
            ),
          ),
        ),
        // "No data" overlay — only shown after loading completes
        if (showLabel)
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: isDark
                    ? cs.surface.withValues(alpha: 0.85)
                    : cs.surface.withValues(alpha: 0.90),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: cs.outline.withValues(alpha: 0.25),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: cs.shadow.withValues(alpha: 0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.bar_chart_rounded,
                    size: 24,
                    color: cs.primary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'No data found',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Post transactions to see\nrevenue & expense trends',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.55),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = OrderAccountingLocalizations.of(context)!;
    final months = [
      localizations.jan, localizations.feb, localizations.mar,
      localizations.apr, localizations.may, localizations.jun,
      localizations.jul, localizations.aug, localizations.sep,
      localizations.oct, localizations.nov, localizations.dec,
    ];

    return BlocBuilder<LedgerBloc, LedgerState>(
      builder: (context, state) {
        // Show greyed placeholder until real data is confirmed
        // Treat all-zero rows as "no data" — the chart would be invisible anyway.
        final hasData = state.status == LedgerStatus.success &&
            state.ledgerReport?.csvRows != null &&
            state.ledgerReport!.csvRows!.isNotEmpty &&
            state.ledgerReport!.csvRows!.any(
              (row) => row.skip(1).any(
                (cell) => (double.tryParse(cell) ?? 0.0) != 0.0,
              ),
            );

        if (!hasData) {
          final showLabel = state.status != LedgerStatus.initial &&
              state.status != LedgerStatus.loading;
          return _buildEmptyChart(context, months, showLabel: showLabel);
        }

        final csvRows = state.ledgerReport!.csvRows!;
        double maxY = 0.0, minY = 0.0;
        final List<List<double>> data = [];
        int row = 1;
        for (int i = 0; i < 12; i++) {
          List<double> newRow = [];
          if (row < csvRows.length - 1 &&
              months.indexWhere(
                    (m) => csvRows[row][0].length >= 3 &&
                        csvRows[row][0].substring(0, 3) == m,
                  ) ==
                  i) {
            for (int cell = 1; cell < csvRows[row].length; cell++) {
              final v = double.tryParse(csvRows[row][cell]) ?? 0.0;
              if (v < minY) minY = v;
              if (v > maxY) maxY = v;
              newRow.add(v);
            }
            row++;
          } else {
            newRow = List.filled(
              csvRows[0].length > 1 ? csvRows[0].length - 1 : 6,
              0.0,
            );
          }
          data.add(newRow);
        }


        return Padding(
          padding: const EdgeInsets.all(8),
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxY == minY ? 1 : (maxY - minY) / 4,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.2),
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    reservedSize: 20,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt() - 1;
                      if (idx < 0 || idx >= months.length) {
                        return const SizedBox.shrink();
                      }
                      // Show only every 3rd month to avoid overlap
                      if (idx % 3 != 0) return const SizedBox.shrink();
                      return Text(
                        months[idx],
                        style: TextStyle(
                          fontSize: 9,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineTouchData: LineTouchData(
                enabled: true,
                touchTooltipData: LineTouchTooltipData(
                  fitInsideVertically: true,
                  fitInsideHorizontally: true,
                  getTooltipItems: (touchedSpots) {
                    final csvRows = state.ledgerReport!.csvRows!;
                    return touchedSpots.map((spot) {
                      if (spot.y == 0.0) return null;
                      final seriesLabel = csvRows[0][spot.barIndex + 1];
                      return LineTooltipItem(
                        '$seriesLabel\n'
                        '${NumberFormat('#,##0').format(spot.y)}',
                        TextStyle(
                          color: _getColor(context, spot.barIndex),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
              lineBarsData: [
                for (int col = 0; col < data[0].length; col++)
                  LineChartBarData(
                    spots: [
                      for (int x = 0; x < data.length; x++)
                        FlSpot((x + 1).toDouble(), data[x][col]),
                    ],
                    isCurved: true,
                    preventCurveOverShooting: true,
                    color: _getColor(context, col),
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: false),
                  ),
              ],
              maxY: maxY == 0 && minY == 0 ? 1 : maxY,
              minY: minY,
              clipData: const FlClipData.all(),
            ),
          ),
        );
      },
    );
  }
}
