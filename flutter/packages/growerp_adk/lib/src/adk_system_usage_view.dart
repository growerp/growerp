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
import 'package:growerp_adk/growerp_adk.dart';

/// Support App View: Audit trail of agent tool/service actions for tenants using the system LLM.
class AdkSystemUsageView extends StatefulWidget {
  const AdkSystemUsageView({super.key});

  @override
  State<AdkSystemUsageView> createState() => _AdkSystemUsageViewState();
}

class _AdkSystemUsageViewState extends State<AdkSystemUsageView> {
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

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final svc = await AdkGovernanceService.create();
      final list = await svc.systemUsage(
          search: _search.isEmpty ? null : _search);
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
        key: const Key('AdkSystemUsageDialog'),
        insetPadding: const EdgeInsets.all(10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: popUp(
          context: dctx,
          title: 'System LLM Usage Detail',
          width: phone ? 400 : 700,
          height: phone ? 600 : 520,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                line('Tenant', a.tenantName ?? a.ownerPartyId),
                line('Tenant ID', a.ownerPartyId),
                line('Agent Party ID', a.agentPartyId),
                line('Service', a.serviceName),
                line('Tool', a.toolName),
                line('Type', a.verbClass),
                line('Decision', a.decision),
                line('Reason', a.reason),
                line('When', a.actionTime.toLocalizedDateTime(context)),
                if ((a.tokensTotal ?? 0) > 0)
                  line('Tokens', '${a.tokensTotal}'),
                line('Tokens In', a.tokensIn != null ? '${a.tokensIn}' : null),
                line('Tokens Out', a.tokensOut != null ? '${a.tokensOut}' : null),
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
    return Scaffold(
      body: Column(
        children: [
          ListFilterBar(
            searchHint: 'Search usage logs...',
            searchController: _searchController,
            focusNode: _searchFocusNode,
            onSearchChanged: (value) {
              _search = value;
              _load();
            },
            actions: [
              IconButton(
                key: const Key('refreshAdkSystemUsage'),
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh',
                onPressed: _load,
              ),
            ],
          ),
          Expanded(
            child: StyledDataTable(
              columns: _columns(context),
              rows: _actions.map(_rowFor).toList(),
              isLoading: _loading && _actions.isEmpty,
              scrollController: _scrollController,
              rowHeight: isAPhone(context) ? 72 : 56,
              onRowTap: (index) => _openAction(_actions[index]),
            ),
          ),
        ],
      ),
    );
  }

  List<StyledColumn> _columns(BuildContext context) {
    if (isAPhone(context)) {
      return const [
        StyledColumn(header: '', flex: 1),
        StyledColumn(header: 'Action', flex: 3),
        StyledColumn(header: 'Tenant', flex: 2),
        StyledColumn(header: 'Tokens', flex: 2),
      ];
    }
    return const [
      StyledColumn(header: '', flex: 1),
      StyledColumn(header: 'Service / tool', flex: 3),
      StyledColumn(header: 'Tenant', flex: 2),
      StyledColumn(header: 'When', flex: 2),
      StyledColumn(header: 'In', flex: 1),
      StyledColumn(header: 'Out', flex: 1),
      StyledColumn(header: 'Decision', flex: 1),
    ];
  }

  String _tok(int? n) => (n != null && n > 0) ? '$n' : '–';

  List<Widget> _rowFor(AdkActionLog a) {
    final icon = Icon(
      a.verbClass == 'write'
          ? Icons.edit
          : a.verbClass == 'delegate'
              ? Icons.share
              : a.verbClass == 'chat'
                  ? Icons.chat_bubble_outline
                  : Icons.visibility,
      color: _decisionColor(a.decision),
    );
    final title = a.serviceName ?? a.toolName ?? '?';
    final tenant = Text(
      a.tenantName ?? a.ownerPartyId ?? '',
      style: const TextStyle(fontSize: 12),
      overflow: TextOverflow.ellipsis,
    );
    final tokStyle = const TextStyle(fontWeight: FontWeight.bold, fontSize: 12);
    if (isAPhone(context)) {
      final total = _tok(a.tokensTotal);
      return [icon, Text(title), tenant, Text(total, style: tokStyle)];
    }
    return [
      icon,
      Text(title),
      tenant,
      Text(a.actionTime.toLocalizedDateTime(context),
          style: const TextStyle(fontSize: 12)),
      Text(_tok(a.tokensIn), style: tokStyle),
      Text(_tok(a.tokensOut), style: tokStyle),
      Text(
        a.decision ?? '',
        style: TextStyle(color: _decisionColor(a.decision), fontSize: 12),
      ),
    ];
  }
}
