import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:growerp_models/growerp_models.dart';

class AccountingHomeWidget {
  static const String appGroupId = 'group.org.growerp.admin';
  static const String androidWidgetName = 'AccountingWidgetProvider';
  static const String iOSWidgetName = 'AccountingWidget';

  static Future<void> updateWidget(LedgerReport? report) async {
    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      return;
    }
    await HomeWidget.setAppGroupId(appGroupId);

    if (report == null || report.csvRows == null || report.csvRows!.isEmpty) {
      await HomeWidget.saveWidgetData<String>('accounting_chart_image', null);
      await HomeWidget.updateWidget(
        androidName: androidWidgetName,
        iOSName: iOSWidgetName,
      );
      return;
    }

    // Render the chart to an image
    final widget = MediaQuery(
      data: const MediaQueryData(
        size: Size(400, 280),
        textScaler: TextScaler.noScaling,
      ),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Material(
          color: Colors.white,
          child: SizedBox(
            width: 400,
            height: 280,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildStaticChart(report),
            ),
          ),
        ),
      ),
    );

    try {
      final path = await HomeWidget.renderFlutterWidget(
        widget,
        key: 'accounting_chart_image',
        logicalSize: const Size(400, 280),
      );

      await HomeWidget.saveWidgetData<String>('accounting_chart_image', path);
      await HomeWidget.updateWidget(androidName: androidWidgetName);
    } catch (e) {
      debugPrint('Error updating home widget: $e');
    }
  }

  static Widget _buildStaticChart(LedgerReport report) {
    final csvRows = report.csvRows!;
    double maxY = 0.0, minY = 0.0;
    final List<List<double>> data = [];
    int row = 1;

    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    for (int i = 0; i < 12; i++) {
      List<double> newRow = [];
      if (row < csvRows.length - 1 &&
          months.indexWhere(
                (m) =>
                    csvRows[row][0].length >= 3 &&
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

    Color getColor(int index) {
      switch (index) {
        case 0:
          return Colors.green; // Net Revenue
        case 1:
          return Colors.red; // Cost of Sales
        case 2:
          return Colors.blue; // Sales Expenses
        case 3:
          return Colors.amber; // G&A Expenses
        case 4:
          return Colors.purple; // Other Exp
        default:
          return Colors.lightBlue; // Net Op Income
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Revenue / Expense (Current Year)',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: LineChart(
            LineChartData(
              gridData: FlGridData(show: true, drawVerticalLine: false),
              titlesData: FlTitlesData(
                show: true,
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: AxisTitles(
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
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                for (int col = 0; col < data[0].length; col++)
                  LineChartBarData(
                    spots: [
                      for (int x = 0; x < data.length; x++)
                        FlSpot((x + 1).toDouble(), data[x][col]),
                    ],
                    isCurved: true,
                    preventCurveOverShooting: true,
                    color: getColor(col),
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                  ),
              ],
              maxY: maxY == 0 && minY == 0 ? 1 : maxY,
              minY: minY,
              clipData: const FlClipData.all(),
            ),
          ),
        ),
      ],
    );
  }
}
