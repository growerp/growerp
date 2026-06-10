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
import 'package:growerp_models/growerp_models.dart';
import 'adk_governance_service.dart';

/// Pending agent write-approvals for the logged-in company. Approving runs the
/// stored service; rejecting discards it. Owner-scoped by the backend.
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

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
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
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              const Text('Show: '),
              DropdownButton<String>(
                key: const Key('approvalStatusFilter'),
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
              const Spacer(),
              IconButton(
                key: const Key('refreshApprovals'),
                icon: const Icon(Icons.refresh),
                onPressed: _load,
              ),
            ],
          ),
        ),
        Expanded(
          child: _approvals.isEmpty
              ? const Center(child: Text('No approvals'))
              : ListView.builder(
                  itemCount: _approvals.length,
                  itemBuilder: (context, index) {
                    final a = _approvals[index];
                    final pending = a.status == 'pending';
                    return Card(
                      key: Key('approval$index'),
                      child: ListTile(
                        title: Text(a.serviceName ?? '?'),
                        subtitle: Text(
                          '${a.argsJson ?? ''}\nstatus: ${a.status}',
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                        isThreeLine: true,
                        trailing: pending
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    key: Key('approve$index'),
                                    icon: const Icon(Icons.check,
                                        color: Colors.green),
                                    tooltip: 'Approve',
                                    onPressed: () => _decide(a, true),
                                  ),
                                  IconButton(
                                    key: Key('reject$index'),
                                    icon: const Icon(Icons.close,
                                        color: Colors.red),
                                    tooltip: 'Reject',
                                    onPressed: () => _decide(a, false),
                                  ),
                                ],
                              )
                            : null,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
