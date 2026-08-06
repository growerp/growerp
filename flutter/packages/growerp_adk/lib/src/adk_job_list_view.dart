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
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_core/growerp_core.dart';
import 'adk_job_service.dart';
import 'package:growerp_adk/l10n/generated/adk_localizations.dart';

class AdkJobListView extends StatefulWidget {
  const AdkJobListView({super.key});

  @override
  State<AdkJobListView> createState() => _AdkJobListViewState();
}

class _AdkJobListViewState extends State<AdkJobListView> {
  List<AdkJob> _jobs = [];
  bool _loading = true;
  String? _error;
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final svc = await AdkJobService.create();
      final list = await svc.list(search: _search.isEmpty ? null : _search);
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
        title: Text(AdkLocalizations.of(context)!.adk_clearStaleLock),
        content: Text(
          'Force-clear the lock on "${job.agentName}"?\n'
          'The locked run (${job.lockRunId}) will be marked as completed.',
        ),
        actions: [
          TextButton(
            key: Key('cancelClearLock'),
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('Cancel'),
          ),
          FilledButton(
            key: Key('confirmClearLock'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(AdkLocalizations.of(context)!.adk_clearLock),
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
          SnackBar(content: Text(AdkLocalizations.of(context)!.adk_failedE(e.toString())), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showError(AdkJob job) {
    if (job.latestErrors == null || job.latestErrors!.isEmpty) return;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AdkLocalizations.of(context)!.adk_errorJobagentname(job.agentName.toString())),
        content: SingleChildScrollView(
          child: SelectableText(
            job.latestErrors!,
            key: Key('jobErrorText'),
          ),
        ),
        actions: [
          TextButton(
            key: Key('closeJobError'),
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Close'),
          ),
        ],
      ),
    );
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
          SnackBar(content: Text(AdkLocalizations.of(context)!.adk_failedE(e.toString())), backgroundColor: Colors.red),
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
      child: Column(
        children: [
          ListFilterBar(
            searchHint: 'Search jobs...',
            searchController: _searchController,
            focusNode: _searchFocusNode,
            onSearchChanged: (value) {
              _search = value;
              _load();
            },
            actions: [
              IconButton(
                key: Key('refreshAdkJobs'),
                icon: Icon(Icons.refresh),
                tooltip: 'Refresh',
                onPressed: _load,
              ),
            ],
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: TextStyle(color: Colors.red)),
            SizedBox(height: 8),
            ElevatedButton(onPressed: _load, child: Text('Retry')),
          ],
        ),
      );
    }
    if (_jobs.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.schedule, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text(AdkLocalizations.of(context)!.adk_noScheduledAgentJobs,
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
    final jobs = _jobs;
    return ListView.separated(
      padding: EdgeInsets.all(12),
      itemCount: jobs.length,
      separatorBuilder: (_, _) => SizedBox(height: 8),
      itemBuilder: (ctx, i) => _JobCard(
        index: i,
        job: jobs[i],
        onClearLock: () => _clearLock(jobs[i]),
        onTogglePause: () => _togglePause(jobs[i]),
      ),
    );
  }

  Widget _buildTable() {
    final cs = Theme.of(context).colorScheme;
    final columns = [
      StyledColumn(header: '', flex: 1),
      StyledColumn(header: 'Agent', flex: 3),
      StyledColumn(header: 'Schedule', flex: 2),
      StyledColumn(header: 'Last Run', flex: 2),
      StyledColumn(header: 'Status', flex: 2),
      StyledColumn(header: 'Lock', flex: 3),
      StyledColumn(header: '', flex: 2),
    ];

    final rows = _jobs.asMap().entries.map((entry) {
      final i = entry.key;
      final job = entry.value;
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
              label: Text('Paused'),
              backgroundColor: Colors.orange.withValues(alpha: 0.15),
              labelStyle: TextStyle(color: Colors.orange, fontSize: 11),
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            )
          : Chip(
              label: Text('Active'),
              backgroundColor: Colors.green.withValues(alpha: 0.15),
              labelStyle: TextStyle(color: Colors.green, fontSize: 11),
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            );

      final lockCell = job.isLocked
          ? Tooltip(
              message: 'Run ${job.lockRunId} • ${job.lockAgeMin} min ago',
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: cs.errorContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock, size: 12, color: cs.onErrorContainer),
                    SizedBox(width: 4),
                    Text(AdkLocalizations.of(context)!.adk_joblockageminMAgo(job.lockAgeMin.toString()),
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
          : SizedBox.shrink();

      final lastRun = job.latestStart.toLocalizedDateTime(context);
      final lastRunText = lastRun.isEmpty ? '—' : lastRun;

      final actions = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (job.isLocked)
            IconButton(
              key: Key('clearLockJob$i'),
              icon: Icon(Icons.lock_open, size: 18, color: cs.error),
              tooltip: 'Clear Lock',
              onPressed: () => _clearLock(job),
            ),
          IconButton(
            key: Key('toggleJob$i'),
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
          key: Key('name$i'),
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        Text(
          job.cronExpression ?? '—',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        Text(lastRunText, style: TextStyle(fontSize: 12)),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(statusIcon, size: 14, color: statusColor),
            SizedBox(width: 4),
            Text(
              job.latestStatus,
              style: TextStyle(fontSize: 12, color: statusColor),
            ),
            if (job.latestErrors != null && job.latestErrors!.isNotEmpty) ...[
              SizedBox(width: 4),
              Icon(Icons.info_outline, size: 14, color: statusColor),
            ],
          ],
        ),
        lockCell,
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [statusChip, SizedBox(width: 4), actions],
        ),
      ];
    }).toList();

    return StyledDataTable(
      columns: columns,
      rows: rows,
      rowHeight: 56,
      onRowTap: (index) => _showError(_jobs[index]),
    );
  }
}

class _JobCard extends StatelessWidget {
  final int index;
  final AdkJob job;
  final VoidCallback onClearLock;
  final VoidCallback onTogglePause;

  const _JobCard({
    required this.index,
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
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.smart_toy, color: cs.primary, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    job.agentName,
                    key: Key('name$index'),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
                if (job.paused)
                  Chip(
                    label: Text('Paused'),
                    backgroundColor: Colors.orange.withValues(alpha: 0.15),
                    labelStyle: TextStyle(
                      color: Colors.orange,
                      fontSize: 11,
                    ),
                    padding: EdgeInsets.zero,
                  )
                else
                  Chip(
                    label: Text('Active'),
                    backgroundColor: Colors.green.withValues(alpha: 0.15),
                    labelStyle: TextStyle(
                      color: Colors.green,
                      fontSize: 11,
                    ),
                    padding: EdgeInsets.zero,
                  ),
              ],
            ),
            if (job.cronExpression != null) ...[
              SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.access_time, size: 13, color: Colors.grey),
                  SizedBox(width: 4),
                  Text(
                    job.cronExpression!,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
            SizedBox(height: 6),
            Row(
              children: [
                Icon(statusIcon, size: 14, color: statusColor),
                SizedBox(width: 4),
                Text(AdkLocalizations.of(context)!.adk_lastRunJoblateststatus(job.latestStatus.toString()),
                  style: TextStyle(fontSize: 12, color: statusColor),
                ),
                if (job.latestStart != null) ...[
                  SizedBox(width: 8),
                  Text(
                    job.latestStart.toLocalizedDateTime(context),
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ],
            ),
            if (job.isLocked) ...[
              SizedBox(height: 6),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: cs.errorContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock, size: 13, color: cs.onErrorContainer),
                    SizedBox(width: 4),
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
              SizedBox(height: 4),
              Text(
                job.latestErrors!,
                style: TextStyle(fontSize: 11, color: cs.error),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (job.isLocked)
                  TextButton.icon(
                    key: Key('clearLockJob$index'),
                    onPressed: onClearLock,
                    icon: Icon(Icons.lock_open, size: 16),
                    label: Text(AdkLocalizations.of(context)!.adk_clearLock),
                    style: TextButton.styleFrom(foregroundColor: cs.error),
                  ),
                SizedBox(width: 8),
                TextButton.icon(
                  key: Key('toggleJob$index'),
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
