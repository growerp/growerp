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
