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
import 'package:growerp_models/growerp_models.dart';
import 'adk_governance_service.dart';

/// Audit trail of agent tool/service actions for the logged-in company.
/// Owner-scoped by the backend — a tenant never sees another company's rows.
/// Same design/function as the user list: ListFilterBar search + StyledDataTable +
/// row-tap detail (a read-only log, so no add FAB).
class AdkActionsListView extends StatefulWidget {
  const AdkActionsListView({super.key, this.configId});

  /// Optionally filter to one agent config.
  final String? configId;

  @override
  State<AdkActionsListView> createState() => _AdkActionsListViewState();
}

class _AdkActionsListViewState extends State<AdkActionsListView> {
  List<AdkActionLog> _actions = [];
  bool _loading = true;
  String? _error;
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  final _scrollController = ScrollController();
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
    _scrollController.dispose();
    super.dispose();
  }

  /// Client-side filter by service/tool/decision/reason.
  List<AdkActionLog> get _visible {
    if (_search.isEmpty) return _actions;
    final q = _search.toLowerCase();
    return _actions.where((a) {
      return [a.serviceName, a.toolName, a.decision, a.verbClass, a.reason]
          .any((v) => (v ?? '').toLowerCase().contains(q));
    }).toList();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final svc = await AdkGovernanceService.create();
      final list = await svc.actions(configId: widget.configId);
      if (mounted) setState(() => _actions = list);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _decisionColor(String? decision) {
    switch (decision) {
      case 'blocked':
      case 'rejected':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      case 'approved':
      case 'allowed':
      case 'delegated':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  /// Read-only detail, using the standard Dialog + popUp frame (user-detail design).
  Future<void> _openAction(AdkActionLog a) async {
    final phone = isAPhone(context);
    Widget line(String label, String? value) => value == null || value.isEmpty
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.bold)),
                SelectableText(value),
              ],
            ),
          );
    await showDialog<void>(
      context: context,
      builder: (dctx) => Dialog(
        key: const Key('AdkActionDialog'),
        insetPadding: const EdgeInsets.all(10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: popUp(
          context: dctx,
          title: 'Agent action',
          width: phone ? 400 : 700,
          height: phone ? 600 : 520,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                line('Service', a.serviceName),
                line('Tool', a.toolName),
                line('Type', a.verbClass),
                line('Decision', a.decision),
                line('Reason', a.reason),
                line('When', a.actionTime.toLocalizedDateTime(context)),
                if ((a.tokensTotal ?? 0) > 0)
                  line('Tokens', '${a.tokensTotal}'),
                line('Result', a.resultSummary),
                line('Arguments', a.argsJson),
              ],
            ),
          ),
        ),
      ),
    );
    _searchFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $_error'),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }
    return Column(
      children: [
        ListFilterBar(
          searchHint: 'Search actions...',
          searchController: _searchController,
          focusNode: _searchFocusNode,
          onSearchChanged: (value) => setState(() => _search = value),
          actions: [
            IconButton(
              key: const Key('refreshAdkActions'),
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
              onPressed: _load,
            ),
          ],
        ),
        Expanded(
          child: StyledDataTable(
            columns: _columns(context),
            rows: _visible.map(_rowFor).toList(),
            isLoading: _loading && _actions.isEmpty,
            scrollController: _scrollController,
            rowHeight: isAPhone(context) ? 72 : 56,
            onRowTap: (index) => _openAction(_visible[index]),
          ),
        ),
      ],
    );
  }

  List<StyledColumn> _columns(BuildContext context) {
    if (isAPhone(context)) {
      return const [
        StyledColumn(header: '', flex: 1),
        StyledColumn(header: 'Action', flex: 5),
        StyledColumn(header: 'Decision', flex: 2),
      ];
    }
    return const [
      StyledColumn(header: '', flex: 1),
      StyledColumn(header: 'Service / tool', flex: 4),
      StyledColumn(header: 'Type', flex: 1),
      StyledColumn(header: 'When', flex: 2),
      StyledColumn(header: 'Decision', flex: 1),
    ];
  }

  List<Widget> _rowFor(AdkActionLog a) {
    final icon = Icon(
      a.verbClass == 'write'
          ? Icons.edit
          : a.verbClass == 'delegate'
              ? Icons.share
              : Icons.visibility,
      color: _decisionColor(a.decision),
    );
    final title = a.serviceName ?? a.toolName ?? '?';
    final decision = Text(
      a.decision ?? '',
      style: TextStyle(color: _decisionColor(a.decision), fontSize: 12),
    );
    if (isAPhone(context)) {
      final sub = a.reason != null && a.reason!.isNotEmpty ? '\n${a.reason}' : '';
      return [icon, Text('$title$sub'), decision];
    }
    return [
      icon,
      Text(a.reason != null && a.reason!.isNotEmpty ? '$title\n${a.reason}' : title),
      Text(a.verbClass ?? '', style: const TextStyle(fontSize: 12)),
      Text(a.actionTime.toLocalizedDateTime(context),
          style: const TextStyle(fontSize: 12)),
      decision,
    ];
  }
}
