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
import 'package:growerp_models/growerp_models.dart';
import 'adk_governance_service.dart';
import 'package:growerp_adk/l10n/generated/adk_localizations.dart';

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

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final svc = await AdkGovernanceService.create();
      final list = await svc.approvals(
        status: _status,
        search: _search.isEmpty ? null : _search,
      );
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
          SnackBar(
            content: Text(
              AdkLocalizations.of(context)!.adk_failedE(e.toString()),
            ),
            backgroundColor: Colors.red,
          ),
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
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
                      line(
                        'Requested',
                        a.requestTime.toLocalizedDateTime(context),
                      ),
                      line(
                        'Decided',
                        a.decisionTime.toLocalizedDateTime(context),
                      ),
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
            Text(
              AdkLocalizations.of(context)!.adk_errorError(_error.toString()),
            ),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }
    return Column(
      children: [
        ListFilterBar(
          searchHint: AdkLocalizations.of(context)!.adk_searchHintApprovals,
          searchController: _searchController,
          focusNode: _searchFocusNode,
          onSearchChanged: (value) {
            _search = value;
            _load();
          },
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
            rows: _approvals.map(_rowFor).toList(),
            isLoading: _loading && _approvals.isEmpty,
            scrollController: _scrollController,
            rowHeight: isAPhone(context) ? 72 : 56,
            onRowTap: (index) => _openApproval(_approvals[index]),
          ),
        ),
      ],
    );
  }

  List<StyledColumn> _columns(BuildContext context) {
    final localizations = AdkLocalizations.of(context)!;
    if (isAPhone(context)) {
      return [
        StyledColumn(header: localizations.adk_tableHdrService, flex: 5),
        StyledColumn(header: '', flex: 2),
      ];
    }
    return [
      StyledColumn(header: localizations.adk_tableHdrService, flex: 4),
      StyledColumn(header: localizations.adk_tableHdrRequested, flex: 2),
      StyledColumn(header: localizations.adk_tableHdrStatus, flex: 2),
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
      Text(
        a.requestTime.toLocalizedDateTime(context),
        style: const TextStyle(fontSize: 12),
      ),
      Text(a.status ?? '', style: const TextStyle(fontSize: 12)),
      decide,
    ];
  }
}
