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
import 'package:growerp_models/growerp_models.dart';

/// Horizontal funnel bars: one row per pipeline stage showing the
/// opportunity count (bar length) with total and weighted amounts.
class SalesFunnelChart extends StatelessWidget {
  const SalesFunnelChart({super.key, required this.summary});

  final List<OpportunitySummaryItem> summary;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (summary.isEmpty) {
      return const Center(child: Text('No pipeline data'));
    }
    int maxCount = 1;
    for (final item in summary) {
      if (item.opportunityCount > maxCount) maxCount = item.opportunityCount;
    }
    return Column(
      key: const Key('salesFunnelChart'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: summary.map((item) {
        final index = summary.indexOf(item);
        final barColor = colorScheme.primary.withValues(
          alpha: 1.0 - (index * 0.6 / summary.length),
        );
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              SizedBox(
                width: 100,
                child: Text(
                  item.stageId,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      height: 16,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: item.opportunityCount / maxCount,
                      child: Container(
                        height: 16,
                        decoration: BoxDecoration(
                          color: barColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 130,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    '${item.opportunityCount} · '
                    '${item.totalAmount ?? '0'} '
                    '(${item.weightedAmount ?? '0'})',
                    key: Key('funnelStage${item.stageId}'),
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
