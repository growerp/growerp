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
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_marketing/l10n/generated/marketing_localizations.dart';

/// Compact marketing dashboard for the half-height 'Marketing' dashboard tile:
/// the social post content funnel as one bar per status, with the content
/// counters in a row at the bottom. The tile route must be listed in
/// DashboardGrid.compactGraphicRoutes so the icon+title render beside it.
class MarketingDashboardChartMini extends StatelessWidget {
  const MarketingDashboardChartMini({super.key});

  @override
  Widget build(BuildContext context) {
    final l = MarketingLocalizations.of(context)!;
    // read off the context before the async load: the callback runs after an
    // await, when this context may be gone
    final errorColor = Theme.of(context).colorScheme.error;
    return DashboardMiniLoader(
      tileKey: const Key('marketingDashboardMini'),
      emptyMessage: l.noContentData,
      load: (restClient) async {
        final dashboard = await restClient.getMarketingDashboard();
        return (
          bars: <DashboardBar>[
            for (final post in dashboard.postSummary)
              (
                label: _postStatusLabel(l, post.status),
                count: post.count,
                // posts stuck on a publish error are the one thing here that
                // needs acting on, so they get the error colour
                color: post.status == 'FAILED' ? errorColor : null,
              ),
          ],
          counters: <DashboardCounter>[
            (label: l.dashPosts, value: dashboard.totalPosts),
            (label: l.dashToApprove, value: dashboard.contentToApprove),
            (label: l.dashPlans, value: dashboard.activePlans),
            (label: l.dashEngagements, value: dashboard.newEngagements),
          ],
        );
      },
    );
  }
}

/// Post funnel statuses as the dashboard service emits them; show the raw
/// status for anything added later.
String _postStatusLabel(MarketingLocalizations l, String status) {
  switch (status) {
    case 'DRAFT':
      return l.dashPostDraft;
    case 'SCHEDULED':
      return l.dashPostScheduled;
    case 'BACKLOG':
      return l.dashPostBacklog;
    case 'PUBLISHED':
      return l.dashPostPublished;
    case 'FAILED':
      return l.dashPostFailed;
    default:
      return status;
  }
}
