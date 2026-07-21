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
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

/// One labelled proportional bar in an ADK dashboard-mini funnel.
typedef AdkBar = ({String label, int count, Color? color});

/// One headline number in the bottom counter row of an ADK dashboard mini.
typedef AdkCounter = ({String label, int value});

/// Bars + counters produced by a mini's data loader.
typedef AdkMiniData = ({List<AdkBar> bars, List<AdkCounter> counters});

/// Shared layout for the half-height ADK dashboard tiles (used via
/// DashboardGrid.compactGraphicRoutes): keeps the top-left corner clear for
/// the DashboardCard icon+title, renders [bars] as a funnel with the
/// [counters] in a row along the bottom. Mirrors AgentControlDashboardChartMini
/// so every agent tile reads as one system.
class AdkDashboardMini extends StatelessWidget {
  const AdkDashboardMini({
    super.key,
    required this.tileKey,
    required this.bars,
    required this.counters,
    this.emptyMessage = 'No data',
  });

  final Key tileKey;
  final List<AdkBar> bars;
  final List<AdkCounter> counters;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    final isPhone = isAPhone(context);
    Widget counter(AdkCounter c) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${c.value}', style: Theme.of(context).textTheme.titleMedium),
          Text(c.label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
    final counterWidgets = [for (final c in counters) counter(c)];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Column(
        key: tileKey,
        children: [
          // Keep the top-left corner clear: DashboardCard overlays the
          // icon+title there for compact graphic tiles.
          Expanded(
            child: Padding(
              padding: isPhone
                  ? const EdgeInsets.only(top: 36)
                  : const EdgeInsets.only(left: compactGraphicLogoInset),
              child: _bars(context),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 38,
            child: isPhone
                ? Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: counterWidgets,
                      ),
                    ),
                  )
                : Row(
                    children: [
                      for (final c in counterWidgets)
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

  Widget _bars(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (bars.isEmpty) {
      return Center(child: Text(emptyMessage));
    }
    int maxCount = 1;
    for (final b in bars) {
      if (b.count > maxCount) maxCount = b.count;
    }
    // Rows share the available height evenly so all bars always fit without
    // scaling, however small the tile gets.
    return LayoutBuilder(
      builder: (context, constraints) {
        final rowHeight = constraints.maxHeight / bars.length;
        final barHeight = (rowHeight - 4).clamp(4.0, 12.0);
        final labelStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          fontSize: (rowHeight - 4).clamp(8.0, 12.0),
        );
        return Column(
          children: bars.asMap().entries.map((entry) {
            final index = entry.key;
            final b = entry.value;
            final barColor =
                b.color ??
                colorScheme.primary.withValues(
                  alpha: 1.0 - (index * 0.6 / bars.length),
                );
            return SizedBox(
              height: rowHeight,
              child: Row(
                children: [
                  SizedBox(
                    width: 86,
                    child: Text(
                      b.label,
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
                          widthFactor: b.count / maxCount,
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
                    child: Text('${b.count}', style: labelStyle),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

/// Fetches one ADK list endpoint and renders it as an [AdkDashboardMini].
/// Every agent-tile mini below is a thin wrapper around this loader.
class _AdkMiniLoader extends StatefulWidget {
  const _AdkMiniLoader({
    required this.tileKey,
    required this.load,
    this.emptyMessage = 'No data',
  });

  final Key tileKey;
  final Future<AdkMiniData> Function(RestClient) load;
  final String emptyMessage;

  @override
  State<_AdkMiniLoader> createState() => _AdkMiniLoaderState();
}

class _AdkMiniLoaderState extends State<_AdkMiniLoader> {
  AdkMiniData? data;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final d = await widget.load(context.read<RestClient>());
      if (mounted) setState(() => data = d);
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
    if (data == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return AdkDashboardMini(
      tileKey: widget.tileKey,
      bars: data!.bars,
      counters: data!.counters,
      emptyMessage: widget.emptyMessage,
    );
  }
}

/// Agent-jobs tile: active / paused / locked breakdown.
class AdkJobsDashboardChartMini extends StatelessWidget {
  const AdkJobsDashboardChartMini({super.key});

  @override
  Widget build(BuildContext context) => _AdkMiniLoader(
    tileKey: const Key('adkJobsDashboardMini'),
    emptyMessage: 'No jobs',
    load: (rest) async {
      final jobs = (await rest.getAdkJobs()).adkJobs;
      final locked = jobs.where((j) => j.isLocked).length;
      final paused = jobs.where((j) => j.paused && !j.isLocked).length;
      final active = jobs.length - locked - paused;
      return (
        bars: <AdkBar>[
          (label: 'Active', count: active, color: Colors.green),
          (label: 'Paused', count: paused, color: Colors.orange),
          (label: 'Locked', count: locked, color: Colors.red),
        ],
        counters: <AdkCounter>[
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
  Widget build(BuildContext context) => _AdkMiniLoader(
    tileKey: const Key('adkApprovalsDashboardMini'),
    emptyMessage: 'No approvals',
    load: (rest) async {
      final aps = (await rest.getAdkApprovals()).adkApprovals;
      final pending = aps.where((a) => a.status == 'pending').length;
      final approved = aps.where((a) => a.status == 'approved').length;
      final rejected = aps.where((a) => a.status == 'rejected').length;
      return (
        bars: <AdkBar>[
          (label: 'Pending', count: pending, color: Colors.orange),
          (label: 'Approved', count: approved, color: Colors.green),
          (label: 'Rejected', count: rejected, color: Colors.red),
        ],
        counters: <AdkCounter>[
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
  Widget build(BuildContext context) => _AdkMiniLoader(
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
        bars: <AdkBar>[
          (label: 'Allowed', count: allowed, color: Colors.green),
          (label: 'Blocked', count: blocked, color: Colors.red),
          (label: 'Pending', count: pending, color: Colors.orange),
        ],
        counters: <AdkCounter>[
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
  Widget build(BuildContext context) => _AdkMiniLoader(
    tileKey: const Key('adkMcpServersDashboardMini'),
    emptyMessage: 'No servers',
    load: (rest) async {
      final servers = (await rest.getAdkMcpServers()).adkMcpServers;
      final enabled = servers.where((s) => s.enabled).length;
      final disabled = servers.length - enabled;
      return (
        bars: <AdkBar>[
          (label: 'Enabled', count: enabled, color: Colors.green),
          (label: 'Disabled', count: disabled, color: Colors.grey),
        ],
        counters: <AdkCounter>[
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
  Widget build(BuildContext context) => _AdkMiniLoader(
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
        bars: <AdkBar>[
          for (final e in sorted.take(3))
            (label: e.key, count: e.value, color: null),
        ],
        counters: <AdkCounter>[
          (label: 'docs', value: docs.length),
          (label: 'chunks', value: chunks),
        ],
      );
    },
  );
}
