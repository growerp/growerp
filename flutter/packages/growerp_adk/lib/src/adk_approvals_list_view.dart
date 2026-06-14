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

/// Pending agent write-approvals for the logged-in company. Approving runs the
/// stored service; rejecting discards it. Owner-scoped by the backend.
/// Same design/function as the user list: ListFilterBar (search + status filter) +
/// StyledDataTable + row-tap detail.
class AdkApprovalsListView extends StatefulWidget {
  const AdkApprovalsListView({super.key});

  @override
  State<AdkApprovalsListView> createState() => _AdkApprovalsListViewState();
}

class _AdkApprovalsListViewState extends State<AdkApprovalsListView> {
  List<AdkApproval> _approvals = [];
  bool _loading = true;
  String? _error;
  String _status = 'pending';
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

  /// Client-side filter by service/args (the status filter is server-side).
  List<AdkApproval> get _visible {
    if (_search.isEmpty) return _approvals;
    final q = _search.toLowerCase();
    return _approvals
        .where((a) => [a.serviceName, a.argsJson]
            .any((v) => (v ?? '').toLowerCase().contains(q)))
        .toList();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final svc = await AdkGovernanceService.create();
      final list = await svc.approvals(status: _status);
      if (mounted) setState(() => _approvals = list);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _decide(AdkApproval a, bool approve) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(approve ? 'Approve action?' : 'Reject action?'),
        content: Text(
          '${approve ? 'Run' : 'Discard'} "${a.serviceName}"?\n\n${a.argsJson ?? ''}',
        ),
        actions: [
          TextButton(
            key: const Key('cancelDecision'),
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: Key(approve ? 'confirmApprove' : 'confirmReject'),
            style: approve
                ? null
                : FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(approve ? 'Approve' : 'Reject'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      final svc = await AdkGovernanceService.create();
      if (approve) {
        await svc.approve(a.adkApprovalId!);
      } else {
        await svc.reject(a.adkApprovalId!);
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

  /// Read-only detail (Dialog + popUp), with approve/reject for pending rows.
  Future<void> _openApproval(AdkApproval a) async {
    final phone = isAPhone(context);
    final pending = a.status == 'pending';
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
        key: const Key('AdkApprovalDialog'),
        insetPadding: const EdgeInsets.all(10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: popUp(
          context: dctx,
          title: 'Approval',
          width: phone ? 400 : 700,
          height: phone ? 600 : 520,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      line('Service', a.serviceName),
                      line('Status', a.status),
                      line('Requested', a.requestTime.toLocalizedDateTime(context)),
                      line('Decided', a.decisionTime.toLocalizedDateTime(context)),
                      line('Arguments', a.argsJson),
                    ],
                  ),
                ),
              ),
              if (pending)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(dctx);
                        _decide(a, false);
                      },
                      icon: const Icon(Icons.close, color: Colors.red),
                      label: const Text('Reject'),
                    ),
                    const SizedBox(width: 10),
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(dctx);
                        _decide(a, true);
                      },
                      icon: const Icon(Icons.check),
                      label: const Text('Approve'),
                    ),
                  ],
                ),
            ],
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
          searchHint: 'Search approvals...',
          searchController: _searchController,
          focusNode: _searchFocusNode,
          onSearchChanged: (value) => setState(() => _search = value),
          filters: [
            FilterDropdown<String>(
              label: 'Status',
              value: _status,
              items: const [
                DropdownMenuItem(value: 'pending', child: Text('Pending')),
                DropdownMenuItem(value: 'approved', child: Text('Approved')),
                DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
              ],
              onChanged: (v) {
                if (v != null) {
                  setState(() => _status = v);
                  _load();
                }
              },
            ),
          ],
          actions: [
            IconButton(
              key: const Key('refreshApprovals'),
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
            isLoading: _loading && _approvals.isEmpty,
            scrollController: _scrollController,
            rowHeight: isAPhone(context) ? 72 : 56,
            onRowTap: (index) => _openApproval(_visible[index]),
          ),
        ),
      ],
    );
  }

  List<StyledColumn> _columns(BuildContext context) {
    if (isAPhone(context)) {
      return const [
        StyledColumn(header: 'Service', flex: 5),
        StyledColumn(header: '', flex: 2),
      ];
    }
    return const [
      StyledColumn(header: 'Service', flex: 4),
      StyledColumn(header: 'Requested', flex: 2),
      StyledColumn(header: 'Status', flex: 2),
      StyledColumn(header: '', flex: 2),
    ];
  }

  List<Widget> _rowFor(AdkApproval a) {
    final pending = a.status == 'pending';
    final decide = pending
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                key: Key('approve_${a.adkApprovalId}'),
                icon: const Icon(Icons.check, color: Colors.green, size: 20),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                tooltip: 'Approve',
                onPressed: () => _decide(a, true),
              ),
              IconButton(
                key: Key('reject_${a.adkApprovalId}'),
                icon: const Icon(Icons.close, color: Colors.red, size: 20),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                tooltip: 'Reject',
                onPressed: () => _decide(a, false),
              ),
            ],
          )
        : Text(a.status ?? '', style: const TextStyle(fontSize: 12));
    if (isAPhone(context)) {
      return [Text(a.serviceName ?? '?'), decide];
    }
    return [
      Text(a.serviceName ?? '?'),
      Text(a.requestTime.toLocalizedDateTime(context),
          style: const TextStyle(fontSize: 12)),
      Text(a.status ?? '', style: const TextStyle(fontSize: 12)),
      decide,
    ];
  }
}
