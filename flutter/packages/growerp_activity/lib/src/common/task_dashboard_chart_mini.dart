/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
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
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';

class _TaskStageSummaryItem {
  final String stageName;
  final int count;
  _TaskStageSummaryItem(this.stageName, this.count);
}

/// Compact task dashboard for the half-height 'Tasks' dashboard
/// tile: dense transaction-mix bars (type + count only) with the
/// counters in a row at the bottom. The tile
/// route must be listed in DashboardGrid.compactGraphicRoutes so the
/// icon+title render beside it.
class TaskDashboardChartMini extends StatelessWidget {
  const TaskDashboardChartMini({super.key});

  Widget _funnel(BuildContext context, List<_TaskStageSummaryItem> summary) {
    final colorScheme = Theme.of(context).colorScheme;
    if (summary.isEmpty) {
      return const Center(child: Text('No task data'));
    }
    int maxCount = 1;
    for (final item in summary) {
      if (item.count > maxCount) maxCount = item.count;
    }
    // Rows share the available height evenly so all stages always fit
    // without scaling, however small the tile gets.
    return LayoutBuilder(
      builder: (context, constraints) {
        final rowHeight = constraints.maxHeight / summary.length;
        final barHeight = (rowHeight - 4).clamp(4.0, 12.0);
        final labelStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          fontSize: (rowHeight - 4).clamp(8.0, 12.0),
        );
        return Column(
          children: summary.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final barColor = colorScheme.primary.withValues(
              alpha: 1.0 - (index * 0.6 / summary.length),
            );
            return SizedBox(
              height: rowHeight,
              child: Row(
                children: [
                  SizedBox(
                    width: 86,
                    child: Text(
                      item.stageName,
                      overflow: TextOverflow.ellipsis,
                      style: labelStyle,
                    ),
                  ),
                  Expanded(
                    child: Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        Container(
                          height: barHeight,
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: item.count / maxCount,
                          child: Container(
                            height: barHeight,
                            decoration: BoxDecoration(
                              color: barColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Text(
                      '${item.count}',
                      style: labelStyle,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final stats = state.authenticate?.stats;
        if (stats == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final summary = [
          _TaskStageSummaryItem('All', stats.allTasks),
          _TaskStageSummaryItem('To-Do', stats.todoActivities),
          _TaskStageSummaryItem('Events', stats.eventActivities),
        ];

        Widget counter(String label, int value) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$value', style: Theme.of(context).textTheme.titleMedium),
              Text(label, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        );
        
        final counters = [
          counter('all tasks', stats.allTasks),
          counter('to-do', stats.todoActivities),
          counter('events', stats.eventActivities),
          counter('un-invoiced', stats.notInvoicedHours),
        ];

        // Phones show the logo as a horizontal top-left strip, desktop as a
        // vertical badge on the left: inset the funnel accordingly.
        final isPhone = isAPhone(context);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Column(
            key: const Key('taskDashboardMini'),
            children: [
              // Keep the top-left corner clear: DashboardCard overlays the
              // icon+title there for compact graphic tiles.
              Expanded(
                child: Padding(
                  padding: isPhone
                      ? const EdgeInsets.only(top: 36)
                      : const EdgeInsets.only(left: compactGraphicLogoInset),
                  child: _funnel(context, summary),
                ),
              ),
              const SizedBox(height: 10),
              // Totals span the full tile width, also under the logo. On phones
              // one FittedBox scales the whole row so all counters stay the same
              // size; per-counter FittedBoxes would shrink only the wide labels.
              SizedBox(
                height: 38,
                child: isPhone
                    ? Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(mainAxisSize: MainAxisSize.min,
                              children: counters),
                        ),
                      )
                    : Row(
                        children: [
                          for (final c in counters)
                            Expanded(
                              child: FittedBox(fit: BoxFit.scaleDown, child: c),
                            ),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
