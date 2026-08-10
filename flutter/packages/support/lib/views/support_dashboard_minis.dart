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

import '../l10n/generated/support_localizations.dart';
import 'support_chart_mini.dart';

/// The four support dashboard tile charts. All data comes from a single
/// get#SupportDashboard call made once by SupportDashboardContent.

class ApplicationsDashboardChartMini extends StatelessWidget {
  const ApplicationsDashboardChartMini({super.key, required this.stats});
  final SupportApplicationsStats stats;

  @override
  Widget build(BuildContext context) => SupportChartMini(
    name: 'applications',
    bars: stats.bars,
    emptyMessage: SupportLocalizations.of(context)!.dashNoApplications,
    counters: [
      MapEntry(SupportLocalizations.of(context)!.dashApps, stats.applications),
      MapEntry(SupportLocalizations.of(context)!.dashInstalls, stats.installs),
      MapEntry(SupportLocalizations.of(context)!.dashAssessed, stats.withAssessment),
      MapEntry(SupportLocalizations.of(context)!.dashPlain, stats.withoutAssessment),
    ],
  );
}

class OwnersDashboardChartMini extends StatelessWidget {
  const OwnersDashboardChartMini({super.key, required this.stats});
  final SupportOwnersStats stats;

  @override
  Widget build(BuildContext context) => SupportChartMini(
    name: 'owners',
    bars: stats.bars,
    emptyMessage: SupportLocalizations.of(context)!.dashNoOwnerActivity,
    counters: [
      MapEntry(SupportLocalizations.of(context)!.dashOwners, stats.owners),
      MapEntry(SupportLocalizations.of(context)!.dashActive, stats.active),
      MapEntry(SupportLocalizations.of(context)!.dashUsers, stats.users),
      MapEntry(SupportLocalizations.of(context)!.dashCompanies, stats.companies),
    ],
  );
}

class LlmUsageDashboardChartMini extends StatelessWidget {
  const LlmUsageDashboardChartMini({super.key, required this.stats});
  final SupportLlmUsageStats stats;

  @override
  Widget build(BuildContext context) => SupportChartMini(
    name: 'llmUsage',
    bars: stats.bars,
    emptyMessage: SupportLocalizations.of(context)!.dashNoLlmUsage,
    counters: [
      MapEntry(SupportLocalizations.of(context)!.dashTenants, stats.tenants),
      MapEntry(SupportLocalizations.of(context)!.dashActions, stats.actions),
      MapEntry(SupportLocalizations.of(context)!.dashTokensIn, stats.tokensIn),
      MapEntry(SupportLocalizations.of(context)!.dashTokensOut, stats.tokensOut),
    ],
  );
}

class RestUsageDashboardChartMini extends StatelessWidget {
  const RestUsageDashboardChartMini({super.key, required this.stats});
  final SupportRestUsageStats stats;

  @override
  Widget build(BuildContext context) => SupportChartMini(
    name: 'restUsage',
    bars: stats.bars,
    emptyMessage: SupportLocalizations.of(context)!.dashNoRestActivity,
    counters: [
      MapEntry(SupportLocalizations.of(context)!.dashUsers, stats.users),
      MapEntry(SupportLocalizations.of(context)!.dashCalls, stats.calls),
      MapEntry(SupportLocalizations.of(context)!.dashAvgPerDay, stats.avgPerDay),
      MapEntry(SupportLocalizations.of(context)!.dashPeakDay, stats.peakDay),
    ],
  );
}
