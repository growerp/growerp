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
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_outreach/l10n/generated/outreach_localizations.dart';

/// Compact outreach dashboard for the half-height 'Outreach' dashboard
/// tile: dense message-status funnel bars (status + count only) with the
/// campaign/message counters in a row at the bottom. The tile route must be
/// listed in DashboardGrid.compactGraphicRoutes so the icon+title render
/// beside it.
class OutreachDashboardChartMini extends StatefulWidget {
  const OutreachDashboardChartMini({super.key});

  @override
  State<OutreachDashboardChartMini> createState() =>
      _OutreachDashboardChartMiniState();
}

class _OutreachDashboardChartMiniState
    extends State<OutreachDashboardChartMini> {
  OutreachDashboard? dashboard;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final result = await context.read<RestClient>().getOutreachDashboard();
      if (mounted) setState(() => dashboard = result);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    }
  }

  Widget _funnel(
    BuildContext context,
    List<OutreachStatusSummaryItem> summary,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    if (summary.isEmpty) {
      return Center(child: Text(OutreachLocalizations.of(context)!.noMessageData));
    }
    int maxCount = 1;
    for (final item in summary) {
      if (item.count > maxCount) maxCount = item.count;
    }
    // Rows share the available height evenly so all statuses always fit
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
                      _statusLabel(context, item.status),
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
                      key: Key('outreachStatus${item.status}'),
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
    final l = OutreachLocalizations.of(context)!;
    if (error != null) {
      return Center(
        child: Text(error!, style: const TextStyle(color: Colors.red)),
      );
    }
    if (dashboard == null) {
      return const Center(child: CircularProgressIndicator());
    }
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
      counter(l.dashCampaigns, dashboard!.totalCampaigns),
      counter(l.dashActive, dashboard!.activeCampaigns),
      counter(l.dashSent, dashboard!.messagesSent),
      counter(l.dashReplies, dashboard!.responsesReceived),
    ];
    // Phones show the logo as a horizontal top-left strip, desktop as a
    // vertical badge on the left: inset the funnel accordingly.
    final isPhone = isAPhone(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Column(
        key: const Key('outreachDashboardMini'),
        children: [
          // Keep the top-left corner clear: DashboardCard overlays the
          // icon+title there for compact graphic tiles.
          Expanded(
            child: Padding(
              padding: isPhone
                  ? const EdgeInsets.only(top: 36)
                  : const EdgeInsets.only(left: compactGraphicLogoInset),
              child: _funnel(context, dashboard!.statusSummary),
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
  }
}

/// Message statuses arrive as backend codes; an unknown code falls back to the
/// code itself so a newly added status still shows on the tile.
String _statusLabel(BuildContext context, String status) {
  final l = OutreachLocalizations.of(context)!;
  switch (status) {
    case 'PENDING':
      return l.dashStatusPending;
    case 'SENT':
      return l.dashStatusSent;
    case 'RESPONDED':
      return l.dashStatusResponded;
    case 'FAILED':
      return l.dashStatusFailed;
    default:
      return status;
  }
}
