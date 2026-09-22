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

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_models/growerp_models.dart';

import '../l10n/generated/support_localizations.dart';

/// Read-only view of Moqui-native metrics for this backend instance: JVM
/// heap/load/disk and Postgres connection/size numbers, read directly from
/// the JVM and the database (the same way Moqui's own built-in system
/// dashboard does it) - no external monitoring stack involved. Since this
/// only ever sees the instance answering the request, the JVM section shows
/// one entry, not every instance in the stack.
class InfrastructureView extends StatefulWidget {
  const InfrastructureView({super.key});

  @override
  State<InfrastructureView> createState() => _InfrastructureViewState();
}

class _InfrastructureViewState extends State<InfrastructureView> {
  // Prometheus scrapes at 30s, so refreshing faster than that only adds REST
  // traffic to the very statistics this app also reports on.
  static const _refreshInterval = Duration(seconds: 60);

  late RestClient _restClient;
  Timer? _timer;
  InfraMetrics? _metrics;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _restClient = context.read<RestClient>();
    _fetch();
    _timer = Timer.periodic(_refreshInterval, (_) => _fetch());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetch() async {
    try {
      final metrics = await _restClient.getInfraMetrics();
      if (!mounted) return;
      setState(() {
        _metrics = metrics;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  // ---- formatting ---------------------------------------------------------

  String _bytes(double value) {
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    var v = value;
    var unit = 0;
    while (v >= 1024 && unit < units.length - 1) {
      v /= 1024;
      unit++;
    }
    return '${v.toStringAsFixed(v >= 100 || unit == 0 ? 0 : 1)} ${units[unit]}';
  }

  String _duration(double seconds) {
    final d = Duration(seconds: seconds.round());
    if (d.inDays > 0) return '${d.inDays}d ${d.inHours % 24}h';
    if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes % 60}m';
    return '${d.inMinutes}m';
  }

  String _num(double value, [int decimals = 1]) =>
      value.toStringAsFixed(decimals);

  // ---- building blocks ----------------------------------------------------

  /// A label with a value, and optionally a proportion bar underneath. The bar
  /// turns amber past 75% and red past 90% so a section can be read at a glance.
  Widget _metric(String label, String value, {double? fraction, Key? key}) {
    final theme = Theme.of(context);
    Color? barColor;
    if (fraction != null) {
      barColor = fraction >= 0.9
          ? theme.colorScheme.error
          : fraction >= 0.75
              ? Colors.amber.shade700
              : theme.colorScheme.primary;
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: theme.textTheme.bodySmall),
          const SizedBox(height: 2),
          Text(value,
              key: key,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
          if (fraction != null) ...[
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: fraction.clamp(0.0, 1.0),
                minHeight: 6,
                color: barColor,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _section(String title, Key key, List<Widget> children) {
    return Card(
      key: key,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }

  /// Metrics laid out as a wrap so the same widget tree works at 412px and
  /// 1280px without branching on width — the CI runs both, and layout-dependent
  /// widget trees make keys unfindable in one of them.
  Widget _metricWrap(List<Widget> metrics) =>
      Wrap(spacing: 16, runSpacing: 4, children: metrics);

  // ---- sections -----------------------------------------------------------

  Widget _hostSection(SupportLocalizations l10n, InfraHost host) {
    final memFraction =
        host.memTotalBytes > 0 ? host.memUsedBytes / host.memTotalBytes : null;
    final diskFraction = host.diskTotalBytes > 0
        ? host.diskUsedBytes / host.diskTotalBytes
        : null;
    return _section(l10n.infraHost, const Key('infraHost'), [
      _metricWrap([
        _metric(l10n.infraCpu, '${_num(host.cpuPercent)}%',
            fraction: host.cpuPercent / 100, key: const Key('hostCpu')),
        _metric(l10n.infraLoad, _num(host.load1, 2),
            key: const Key('hostLoad')),
        _metric(l10n.infraMemory,
            '${_bytes(host.memUsedBytes)} / ${_bytes(host.memTotalBytes)}',
            fraction: memFraction, key: const Key('hostMemory')),
        _metric(l10n.infraDisk,
            '${_bytes(host.diskUsedBytes)} / ${_bytes(host.diskTotalBytes)}',
            fraction: diskFraction, key: const Key('hostDisk')),
        _metric(l10n.infraUptime, _duration(host.uptimeSeconds),
            key: const Key('hostUptime')),
      ]),
    ]);
  }

  Widget _jvmSection(SupportLocalizations l10n, List<InfraJvm> jvms) {
    return _section(l10n.infraBackendJvms, const Key('infraJvms'), [
      if (jvms.isEmpty)
        Text(l10n.infraNoData, style: Theme.of(context).textTheme.bodySmall)
      else
        for (var i = 0; i < jvms.length; i++) ...[
          if (i > 0) const Divider(height: 16),
          Text(jvms[i].instance,
              key: Key('jvmInstance$i'),
              style: Theme.of(context).textTheme.labelLarge),
          _metricWrap([
            _metric(
                l10n.infraHeap,
                '${_bytes(jvms[i].heapUsedBytes)} / '
                    '${_bytes(jvms[i].heapMaxBytes)}',
                fraction: jvms[i].heapMaxBytes > 0
                    ? jvms[i].heapUsedBytes / jvms[i].heapMaxBytes
                    : null,
                key: Key('jvmHeap$i')),
            _metric(l10n.infraCommitted, _bytes(jvms[i].heapCommittedBytes)),
            _metric(l10n.infraNonHeap, _bytes(jvms[i].nonHeapUsedBytes)),
            _metric(l10n.infraThreads, jvms[i].threadCount.toStringAsFixed(0)),
            _metric(l10n.infraGcTime, '${_num(jvms[i].gcTimeSeconds, 2)}s'),
          ]),
        ],
    ]);
  }

  Widget _databaseSection(SupportLocalizations l10n, InfraDatabase database) {
    final fraction = database.maxConnections > 0
        ? database.connections / database.maxConnections
        : null;
    return _section(l10n.infraDatabase, const Key('infraDatabase'), [
      _metricWrap([
        _metric(
            l10n.infraConnections,
            '${database.connections.toStringAsFixed(0)} / '
                '${database.maxConnections.toStringAsFixed(0)}',
            fraction: fraction,
            key: const Key('dbConnections')),
      ]),
      if (database.databases.isNotEmpty) ...[
        const SizedBox(height: 8),
        _table(
          [l10n.infraDatabase, l10n.infraConnections, l10n.infraSize],
          [
            for (var i = 0; i < database.databases.length; i++)
              [
                Text(database.databases[i].name, key: Key('dbName$i')),
                Text(database.databases[i].connections.toStringAsFixed(0)),
                Text(_bytes(database.databases[i].sizeBytes)),
              ],
          ],
        ),
      ],
    ]);
  }

  /// Wide tables must scroll inside themselves rather than overflow the page.
  Widget _table(List<String> headers, List<List<Widget>> rows) {
    final headerStyle = Theme.of(context)
        .textTheme
        .bodySmall
        ?.copyWith(fontWeight: FontWeight.w600);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 24,
        headingRowHeight: 32,
        dataRowMinHeight: 28,
        dataRowMaxHeight: 36,
        columns: [
          for (final h in headers)
            DataColumn(label: Text(h, style: headerStyle)),
        ],
        rows: [
          for (final row in rows)
            DataRow(cells: [for (final cell in row) DataCell(cell)]),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = SupportLocalizations.of(context)!;
    final metrics = _metrics;
    return Scaffold(
      key: const Key('InfrastructureView'),
      floatingActionButton: FloatingActionButton.small(
        key: const Key('infraRefresh'),
        tooltip: l10n.infraTitle,
        onPressed: _fetch,
        child: const Icon(Icons.refresh),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : metrics == null || !metrics.available
                  ? Center(
                      key: const Key('infraUnavailable'),
                      child: Text(metrics?.message.isNotEmpty == true
                          ? metrics!.message
                          : l10n.infraUnavailable),
                    )
                  : ListView(
                      key: const Key('listView'),
                      padding: const EdgeInsets.all(10),
                      children: [
                        _hostSection(l10n, metrics.host ?? InfraHost()),
                        _jvmSection(l10n, metrics.jvms),
                        _databaseSection(
                            l10n, metrics.database ?? InfraDatabase()),
                      ],
                    ),
    );
  }
}
