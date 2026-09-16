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
import 'package:growerp_sales/l10n/generated/sales_localizations.dart';
import 'package:growerp_core/growerp_core.dart';

/// Compact CRM dashboard for the half-height 'Crm' dashboard tile: the open
/// opportunity pipeline of the last weeks as one bar per week, with the
/// party-role counters in a row at the bottom. The weeks come from the weekly
/// snapshot job, so a week only appears after that job has run for it. The tile
/// route must be listed in DashboardGrid.compactGraphicRoutes so the icon+title
/// render beside it.
class CrmDashboardChartMini extends StatelessWidget {
  const CrmDashboardChartMini({super.key, this.showEmployees = true});

  /// False in apps that do not administer staff (marketing), where an employee
  /// count on the CRM tile says nothing about the pipeline.
  final bool showEmployees;

  @override
  Widget build(BuildContext context) {
    final l = SalesLocalizations.of(context)!;
    return DashboardMiniLoader(
      tileKey: const Key('crmDashboardMini'),
      emptyMessage: l.noPipelineData,
      load: (restClient) async {
        final dashboard = await restClient.getCrmDashboard();
        return (
          bars: <DashboardBar>[
            for (final week in dashboard.weekSummary.asMap().entries)
              (
                label: week.key == 0
                    ? l.dashWeekCurrent
                    : l.dashWeeksAgo(week.key),
                count: week.value.opportunityCount,
                color: null,
              ),
          ],
          counters: <DashboardCounter>[
            (label: l.dashContacts, value: dashboard.totalContacts),
            (label: l.dashSuppliers, value: dashboard.suppliers),
            if (showEmployees)
              (label: l.dashEmployees, value: dashboard.employees),
            (label: l.dashAdmins, value: dashboard.admins),
          ],
        );
      },
    );
  }
}
