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
import 'package:growerp_marketing/l10n/generated/marketing_localizations.dart';

/// Compact marketing dashboard for the half-height 'Marketing' dashboard
/// tile: dense funnel bars (stage + count only) with the lead/enrollment/
/// assessment counters in a row at the bottom. The tile route must be listed
/// in DashboardGrid.compactGraphicRoutes so the icon+title render beside it.
class MarketingDashboardChartMini extends StatefulWidget {
  const MarketingDashboardChartMini({super.key});

  @override
  State<MarketingDashboardChartMini> createState() =>
      _MarketingDashboardChartMiniState();
}

class _MarketingDashboardChartMiniState
    extends State<MarketingDashboardChartMini> {
  MarketingDashboard? dashboard;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final result = await context.read<RestClient>().getMarketingDashboard();
      if (mounted) setState(() => dashboard = result);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    }
  }

  Widget _funnel(BuildContext context, List<OpportunitySummaryItem> summary) {
    final colorScheme = Theme.of(context).colorScheme;
    if (summary.isEmpty) {
      return Center(child: Text(MarketingLocalizations.of(context)!.noPipelineData));
    }
    int maxCount = 1;
    for (final item in summary) {
      if (item.opportunityCount > maxCount) maxCount = item.opportunityCount;
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
                      _stageLabel(context, item.stageId),
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
                          widthFactor: item.opportunityCount / maxCount,
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
                      '${item.opportunityCount}',
                      key: Key('funnelStage${item.stageId}'),
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
    final l = MarketingLocalizations.of(context)!;
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
      counter(l.dashLeads, dashboard!.totalLeads),
      counter(l.dashAssessments, dashboard!.assessmentCompletions),
      counter(l.dashNurturing, dashboard!.activeEnrollments),
      counter(l.dashNurtured, dashboard!.completedEnrollments),
    ];
    // Phones show the logo as a horizontal top-left strip, desktop as a
    // vertical badge on the left: inset the funnel accordingly.
    final isPhone = isAPhone(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Column(
        key: const Key('marketingDashboardMini'),
        children: [
          // Keep the top-left corner clear: DashboardCard overlays the
          // icon+title there for compact graphic tiles.
          Expanded(
            child: Padding(
              padding: isPhone
                  ? const EdgeInsets.only(top: 36)
                  : const EdgeInsets.only(left: compactGraphicLogoInset),
              child: _funnel(context, dashboard!.stageSummary),
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

/// Opportunity stage ids are the English stage names as seeded; translate the
/// standard ones and show the raw id for stages a company added itself.
String _stageLabel(BuildContext context, String stageId) {
  final l = MarketingLocalizations.of(context)!;
  switch (stageId) {
    case 'Prospecting':
      return l.dashStageProspecting;
    case 'Qualification':
      return l.dashStageQualification;
    case 'Demo/Meeting':
      return l.dashStageDemoMeeting;
    case 'Proposal':
      return l.dashStageProposal;
    case 'Quote':
      return l.dashStageQuote;
    case 'Closed Won':
      return l.dashStageClosedWon;
    case 'Closed Lost':
      return l.dashStageClosedLost;
    default:
      return stageId;
  }
}
