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
import 'package:growerp_adk/l10n/generated/adk_localizations.dart';

/// Agent-jobs tile: active / paused / locked breakdown.
class AdkJobsDashboardChartMini extends StatelessWidget {
  const AdkJobsDashboardChartMini({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AdkLocalizations.of(context)!;
    return DashboardMiniLoader(
      tileKey: const Key('adkJobsDashboardMini'),
      emptyMessage: l.adk_dashNoJobs,
      load: (rest) async {
        final jobs = (await rest.getAdkJobs()).adkJobs;
        final locked = jobs.where((j) => j.isLocked).length;
        final paused = jobs.where((j) => j.paused && !j.isLocked).length;
        final active = jobs.length - locked - paused;
        return (
          bars: <DashboardBar>[
            (label: l.adk_dashBarActive, count: active, color: Colors.green),
            (label: l.adk_dashBarPaused, count: paused, color: Colors.orange),
            (label: l.adk_dashBarLocked, count: locked, color: Colors.red),
          ],
          counters: <DashboardCounter>[
            (label: l.adk_dashJobs, value: jobs.length),
            (label: l.adk_dashLocked, value: locked),
          ],
        );
      },
    );
  }
}

/// Approvals tile: pending / approved / rejected queue.
class AdkApprovalsDashboardChartMini extends StatelessWidget {
  const AdkApprovalsDashboardChartMini({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AdkLocalizations.of(context)!;
    return DashboardMiniLoader(
      tileKey: const Key('adkApprovalsDashboardMini'),
      emptyMessage: l.adk_dashNoApprovals,
      load: (rest) async {
        final aps = (await rest.getAdkApprovals()).adkApprovals;
        final pending = aps.where((a) => a.status == 'pending').length;
        final approved = aps.where((a) => a.status == 'approved').length;
        final rejected = aps.where((a) => a.status == 'rejected').length;
        return (
          bars: <DashboardBar>[
            (
              label: l.adk_dashStagePending,
              count: pending,
              color: Colors.orange,
            ),
            (
              label: l.adk_dashStageApproved,
              count: approved,
              color: Colors.green,
            ),
            (
              label: l.adk_dashStageRejected,
              count: rejected,
              color: Colors.red,
            ),
          ],
          counters: <DashboardCounter>[
            (label: l.adk_dashTotal, value: aps.length),
            (label: l.adk_dashPending, value: pending),
          ],
        );
      },
    );
  }
}

/// Agent-actions audit tile: decision breakdown + token spend.
class AdkActionsDashboardChartMini extends StatelessWidget {
  const AdkActionsDashboardChartMini({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AdkLocalizations.of(context)!;
    return DashboardMiniLoader(
      tileKey: const Key('adkActionsDashboardMini'),
      emptyMessage: l.adk_dashNoActions,
      load: (rest) async {
        final actions = (await rest.getAdkActions(limit: 200)).adkActions;
        int allowed = 0, blocked = 0, pending = 0, tokens = 0;
        for (final a in actions) {
          tokens += a.tokensTotal ?? 0;
          switch (a.decision) {
            case 'approved':
            case 'allowed':
            case 'delegated':
              allowed++;
            case 'blocked':
            case 'rejected':
              blocked++;
            case 'pending':
              pending++;
          }
        }
        return (
          bars: <DashboardBar>[
            (label: l.adk_dashBarAllowed, count: allowed, color: Colors.green),
            (label: l.adk_dashBarBlocked, count: blocked, color: Colors.red),
            (
              label: l.adk_dashStagePending,
              count: pending,
              color: Colors.orange,
            ),
          ],
          counters: <DashboardCounter>[
            (label: l.adk_dashActions, value: actions.length),
            (label: l.adk_dashTokens, value: tokens),
          ],
        );
      },
    );
  }
}

/// Tools & integrations tile: enabled / disabled MCP servers.
class AdkMcpServersDashboardChartMini extends StatelessWidget {
  const AdkMcpServersDashboardChartMini({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AdkLocalizations.of(context)!;
    return DashboardMiniLoader(
      tileKey: const Key('adkMcpServersDashboardMini'),
      emptyMessage: l.adk_dashNoServers,
      load: (rest) async {
        final servers = (await rest.getAdkMcpServers()).adkMcpServers;
        final enabled = servers.where((s) => s.enabled).length;
        final disabled = servers.length - enabled;
        return (
          bars: <DashboardBar>[
            (label: l.adk_dashEnabled, count: enabled, color: Colors.green),
            (label: l.adk_dashBarDisabled, count: disabled, color: Colors.grey),
          ],
          counters: <DashboardCounter>[
            (label: l.adk_dashServers, value: servers.length),
            (label: l.adk_dashEnabled, value: enabled),
          ],
        );
      },
    );
  }
}

/// Knowledge-base tile: documents grouped by source type + chunk total.
class AdkKnowledgeDashboardChartMini extends StatelessWidget {
  const AdkKnowledgeDashboardChartMini({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AdkLocalizations.of(context)!;
    return DashboardMiniLoader(
      tileKey: const Key('adkKnowledgeDashboardMini'),
      emptyMessage: l.adk_dashNoDocuments,
      load: (rest) async {
        final docs = (await rest.getAdkKnowledge()).adkKnowledgeDocs;
        final chunks = docs.fold<int>(0, (s, d) => s + (d.chunkCount ?? 0));
        final byType = <String, int>{};
        for (final d in docs) {
          final t = (d.sourceType?.isNotEmpty ?? false)
              ? d.sourceType!
              : 'other';
          byType[t] = (byType[t] ?? 0) + 1;
        }
        final sorted = byType.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        return (
          bars: <DashboardBar>[
            for (final e in sorted.take(3))
              (label: e.key, count: e.value, color: null),
          ],
          counters: <DashboardCounter>[
            (label: l.adk_dashDocs, value: docs.length),
            (label: l.adk_dashChunks, value: chunks),
          ],
        );
      },
    );
  }
}
