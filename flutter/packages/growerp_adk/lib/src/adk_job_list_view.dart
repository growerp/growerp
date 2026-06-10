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
import 'package:growerp_core/growerp_core.dart';
import 'adk_job_service.dart';

class AdkJobListView extends StatefulWidget {
  const AdkJobListView({super.key});

  @override
  State<AdkJobListView> createState() => _AdkJobListViewState();
}

class _AdkJobListViewState extends State<AdkJobListView> {
  List<AdkJob> _jobs = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final svc = await AdkJobService.create();
      final list = await svc.list();
      if (mounted) setState(() => _jobs = list);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _clearLock(AdkJob job) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear stale lock?'),
        content: Text(
          'Force-clear the lock on "${job.agentName}"?\n'
          'The locked run (${job.lockRunId}) will be marked as completed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Clear Lock'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      final svc = await AdkJobService.create();
      await svc.clearLock(job.jobName);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _togglePause(AdkJob job) async {
    try {
      final svc = await AdkJobService.create();
      if (job.paused) {
        await svc.resume(job.jobName);
      } else {
        await svc.pause(job.jobName);
      }
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<NotificationBloc, NotificationState>(
      listenWhen: (previous, current) =>
          current.notificationSeq != previous.notificationSeq &&
          current.notifications.any((n) => n.topic == 'adkJobUpdate'),
      listener: (context, state) => _load(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Agent Jobs'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
              onPressed: _load,
            ),
          ],
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_jobs.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.schedule, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              'No scheduled agent jobs.\nEnable scheduling in AI Agents.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (isAPhone(context)) {
      return _buildCardList();
    }
    return _buildTable();
  }

  Widget _buildCardList() {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _jobs.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (ctx, i) => _JobCard(
        job: _jobs[i],
        onClearLock: () => _clearLock(_jobs[i]),
        onTogglePause: () => _togglePause(_jobs[i]),
      ),
    );
  }

  Widget _buildTable() {
    final cs = Theme.of(context).colorScheme;

    const columns = [
      StyledColumn(header: '', flex: 1),
      StyledColumn(header: 'Agent', flex: 3),
      StyledColumn(header: 'Schedule', flex: 2),
      StyledColumn(header: 'Last Run', flex: 2),
      StyledColumn(header: 'Status', flex: 2),
      StyledColumn(header: 'Lock', flex: 3),
      StyledColumn(header: '', flex: 2),
    ];

    final rows = _jobs.map((job) {
      Color statusColor;
      IconData statusIcon;
      switch (job.latestStatus) {
        case 'error':
          statusColor = cs.error;
          statusIcon = Icons.error_outline;
        case 'running':
          statusColor = Colors.blue;
          statusIcon = Icons.pending;
        case 'complete':
          statusColor = Colors.green;
          statusIcon = Icons.check_circle_outline;
        default:
          statusColor = Colors.grey;
          statusIcon = Icons.schedule;
      }

      final avatar = CircleAvatar(
        backgroundColor: cs.secondaryContainer,
        child: Icon(Icons.smart_toy, color: cs.onSecondaryContainer, size: 18),
      );

      final statusChip = job.paused
          ? Chip(
              label: const Text('Paused'),
              backgroundColor: Colors.orange.withValues(alpha: 0.15),
              labelStyle: const TextStyle(color: Colors.orange, fontSize: 11),
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            )
          : Chip(
              label: const Text('Active'),
              backgroundColor: Colors.green.withValues(alpha: 0.15),
              labelStyle: const TextStyle(color: Colors.green, fontSize: 11),
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            );

      final lockCell = job.isLocked
          ? Tooltip(
              message: 'Run ${job.lockRunId} • ${job.lockAgeMin} min ago',
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: cs.errorContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock, size: 12, color: cs.onErrorContainer),
                    const SizedBox(width: 4),
                    Text(
                      '${job.lockAgeMin}m ago',
                      style: TextStyle(
                        fontSize: 11,
                        color: cs.onErrorContainer,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : const SizedBox.shrink();

      final lastRun = job.latestStart.toLocalizedDateTime(context);
      final lastRunText = lastRun.isEmpty ? '—' : lastRun;

      final actions = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (job.isLocked)
            IconButton(
              icon: Icon(Icons.lock_open, size: 18, color: cs.error),
              tooltip: 'Clear Lock',
              onPressed: () => _clearLock(job),
            ),
          IconButton(
            icon: Icon(
              job.paused ? Icons.play_arrow : Icons.pause,
              size: 18,
            ),
            tooltip: job.paused ? 'Resume' : 'Pause',
            onPressed: () => _togglePause(job),
          ),
        ],
      );

      return [
        avatar,
        Text(
          job.agentName,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        Text(
          job.cronExpression ?? '—',
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        Text(lastRunText, style: const TextStyle(fontSize: 12)),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(statusIcon, size: 14, color: statusColor),
            const SizedBox(width: 4),
            Text(
              job.latestStatus,
              style: TextStyle(fontSize: 12, color: statusColor),
            ),
          ],
        ),
        lockCell,
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [statusChip, const SizedBox(width: 4), actions],
        ),
      ];
    }).toList();

    return StyledDataTable(
      columns: columns,
      rows: rows,
      rowHeight: 56,
    );
  }
}

class _JobCard extends StatelessWidget {
  final AdkJob job;
  final VoidCallback onClearLock;
  final VoidCallback onTogglePause;

  const _JobCard({
    required this.job,
    required this.onClearLock,
    required this.onTogglePause,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Color statusColor;
    IconData statusIcon;
    switch (job.latestStatus) {
      case 'error':
        statusColor = cs.error;
        statusIcon = Icons.error_outline;
      case 'running':
        statusColor = Colors.blue;
        statusIcon = Icons.pending;
      case 'complete':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_outline;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.schedule;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.smart_toy, color: cs.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    job.agentName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
                if (job.paused)
                  Chip(
                    label: const Text('Paused'),
                    backgroundColor: Colors.orange.withValues(alpha: 0.15),
                    labelStyle: const TextStyle(
                      color: Colors.orange,
                      fontSize: 11,
                    ),
                    padding: EdgeInsets.zero,
                  )
                else
                  Chip(
                    label: const Text('Active'),
                    backgroundColor: Colors.green.withValues(alpha: 0.15),
                    labelStyle: const TextStyle(
                      color: Colors.green,
                      fontSize: 11,
                    ),
                    padding: EdgeInsets.zero,
                  ),
              ],
            ),
            if (job.cronExpression != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 13, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    job.cronExpression!,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(statusIcon, size: 14, color: statusColor),
                const SizedBox(width: 4),
                Text(
                  'Last run: ${job.latestStatus}',
                  style: TextStyle(fontSize: 12, color: statusColor),
                ),
                if (job.latestStart != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    job.latestStart.toLocalizedDateTime(context),
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ],
            ),
            if (job.isLocked) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: cs.errorContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock, size: 13, color: cs.onErrorContainer),
                    const SizedBox(width: 4),
                    Text(
                      'Locked — run ${job.lockRunId} '
                      '(${job.lockAgeMin} min ago)',
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onErrorContainer,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (job.latestErrors != null && job.latestErrors!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                job.latestErrors!,
                style: TextStyle(fontSize: 11, color: cs.error),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (job.isLocked)
                  TextButton.icon(
                    onPressed: onClearLock,
                    icon: const Icon(Icons.lock_open, size: 16),
                    label: const Text('Clear Lock'),
                    style: TextButton.styleFrom(foregroundColor: cs.error),
                  ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: onTogglePause,
                  icon: Icon(
                    job.paused ? Icons.play_arrow : Icons.pause,
                    size: 16,
                  ),
                  label: Text(job.paused ? 'Resume' : 'Pause'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
