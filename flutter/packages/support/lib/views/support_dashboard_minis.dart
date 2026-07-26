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
    emptyMessage: 'No applications',
    counters: [
      MapEntry('apps', stats.applications),
      MapEntry('installs', stats.installs),
      MapEntry('assessed', stats.withAssessment),
      MapEntry('plain', stats.withoutAssessment),
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
    emptyMessage: 'No owner activity',
    counters: [
      MapEntry('owners', stats.owners),
      MapEntry('active', stats.active),
      MapEntry('users', stats.users),
      MapEntry('companies', stats.companies),
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
    emptyMessage: 'No system LLM usage',
    counters: [
      MapEntry('tenants', stats.tenants),
      MapEntry('actions', stats.actions),
      MapEntry('tokens in', stats.tokensIn),
      MapEntry('tokens out', stats.tokensOut),
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
    emptyMessage: 'No REST activity',
    counters: [
      MapEntry('users', stats.users),
      MapEntry('calls', stats.calls),
      MapEntry('avg/day', stats.avgPerDay),
      MapEntry('peak day', stats.peakDay),
    ],
  );
}
