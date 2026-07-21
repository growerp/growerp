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
import 'package:growerp_core/growerp_core.dart';

/// Agent-jobs tile: active / paused / locked breakdown.
class AdkJobsDashboardChartMini extends StatelessWidget {
  const AdkJobsDashboardChartMini({super.key});

  @override
  Widget build(BuildContext context) => DashboardMiniLoader(
    tileKey: const Key('adkJobsDashboardMini'),
    emptyMessage: 'No jobs',
    load: (rest) async {
      final jobs = (await rest.getAdkJobs()).adkJobs;
      final locked = jobs.where((j) => j.isLocked).length;
      final paused = jobs.where((j) => j.paused && !j.isLocked).length;
      final active = jobs.length - locked - paused;
      return (
        bars: <DashboardBar>[
          (label: 'Active', count: active, color: Colors.green),
          (label: 'Paused', count: paused, color: Colors.orange),
          (label: 'Locked', count: locked, color: Colors.red),
        ],
        counters: <DashboardCounter>[
          (label: 'jobs', value: jobs.length),
          (label: 'locked', value: locked),
        ],
      );
    },
  );
}

/// Approvals tile: pending / approved / rejected queue.
class AdkApprovalsDashboardChartMini extends StatelessWidget {
  const AdkApprovalsDashboardChartMini({super.key});

  @override
  Widget build(BuildContext context) => DashboardMiniLoader(
    tileKey: const Key('adkApprovalsDashboardMini'),
    emptyMessage: 'No approvals',
    load: (rest) async {
      final aps = (await rest.getAdkApprovals()).adkApprovals;
      final pending = aps.where((a) => a.status == 'pending').length;
      final approved = aps.where((a) => a.status == 'approved').length;
      final rejected = aps.where((a) => a.status == 'rejected').length;
      return (
        bars: <DashboardBar>[
          (label: 'Pending', count: pending, color: Colors.orange),
          (label: 'Approved', count: approved, color: Colors.green),
          (label: 'Rejected', count: rejected, color: Colors.red),
        ],
        counters: <DashboardCounter>[
          (label: 'total', value: aps.length),
          (label: 'pending', value: pending),
        ],
      );
    },
  );
}

/// Agent-actions audit tile: decision breakdown + token spend.
class AdkActionsDashboardChartMini extends StatelessWidget {
  const AdkActionsDashboardChartMini({super.key});

  @override
  Widget build(BuildContext context) => DashboardMiniLoader(
    tileKey: const Key('adkActionsDashboardMini'),
    emptyMessage: 'No actions',
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
          (label: 'Allowed', count: allowed, color: Colors.green),
          (label: 'Blocked', count: blocked, color: Colors.red),
          (label: 'Pending', count: pending, color: Colors.orange),
        ],
        counters: <DashboardCounter>[
          (label: 'actions', value: actions.length),
          (label: 'tokens', value: tokens),
        ],
      );
    },
  );
}

/// Tools & integrations tile: enabled / disabled MCP servers.
class AdkMcpServersDashboardChartMini extends StatelessWidget {
  const AdkMcpServersDashboardChartMini({super.key});

  @override
  Widget build(BuildContext context) => DashboardMiniLoader(
    tileKey: const Key('adkMcpServersDashboardMini'),
    emptyMessage: 'No servers',
    load: (rest) async {
      final servers = (await rest.getAdkMcpServers()).adkMcpServers;
      final enabled = servers.where((s) => s.enabled).length;
      final disabled = servers.length - enabled;
      return (
        bars: <DashboardBar>[
          (label: 'Enabled', count: enabled, color: Colors.green),
          (label: 'Disabled', count: disabled, color: Colors.grey),
        ],
        counters: <DashboardCounter>[
          (label: 'servers', value: servers.length),
          (label: 'enabled', value: enabled),
        ],
      );
    },
  );
}

/// Knowledge-base tile: documents grouped by source type + chunk total.
class AdkKnowledgeDashboardChartMini extends StatelessWidget {
  const AdkKnowledgeDashboardChartMini({super.key});

  @override
  Widget build(BuildContext context) => DashboardMiniLoader(
    tileKey: const Key('adkKnowledgeDashboardMini'),
    emptyMessage: 'No documents',
    load: (rest) async {
      final docs = (await rest.getAdkKnowledge()).adkKnowledgeDocs;
      final chunks = docs.fold<int>(0, (s, d) => s + (d.chunkCount ?? 0));
      final byType = <String, int>{};
      for (final d in docs) {
        final t = (d.sourceType?.isNotEmpty ?? false) ? d.sourceType! : 'other';
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
          (label: 'docs', value: docs.length),
          (label: 'chunks', value: chunks),
        ],
      );
    },
  );
}
