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
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_sales/growerp_sales.dart';

/// Compact marketing dashboard for the 'Marketing' dashboard tile:
/// sales funnel bars plus lead/enrollment/assessment counters.
/// Set the tile's tileType='graphic' (auto via chartBuilder route match).
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

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return Center(
        child: Text(error!, style: const TextStyle(color: Colors.red)),
      );
    }
    if (dashboard == null) {
      return const Center(child: CircularProgressIndicator());
    }
    Widget counter(String label, int value) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$value', style: Theme.of(context).textTheme.titleMedium),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        key: const Key('marketingDashboardMini'),
        children: [
          Expanded(child: SalesFunnelChart(summary: dashboard!.stageSummary)),
          const SizedBox(height: 4),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                counter('leads', dashboard!.totalLeads),
                counter('assessments', dashboard!.assessmentCompletions),
                counter('nurturing', dashboard!.activeEnrollments),
                counter(
                  'nurtured',
                  dashboard!.completedEnrollments,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
