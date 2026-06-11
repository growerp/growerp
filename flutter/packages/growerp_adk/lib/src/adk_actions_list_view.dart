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

/// Audit trail of agent tool/service actions for the logged-in company.
/// Owner-scoped by the backend — a tenant never sees another company's rows.
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
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return _content(context);
  }

  Widget _content(BuildContext context) {
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
    return RefreshIndicator(
      onRefresh: _load,
      child: _actions.isEmpty
          ? ListView(
              children: const [
                SizedBox(height: 200),
                Center(child: Text('No agent actions recorded')),
              ],
            )
          : ListView.builder(
              itemCount: _actions.length,
              itemBuilder: (context, index) {
                final a = _actions[index];
                final tokens = a.tokensTotal != null && a.tokensTotal! > 0
                    ? ' • ${a.tokensTotal} tok'
                    : '';
                return Card(
                  key: Key('action$index'),
                  child: ListTile(
                    leading: Icon(
                      a.verbClass == 'write'
                          ? Icons.edit
                          : Icons.visibility,
                      color: _decisionColor(a.decision),
                    ),
                    title: Text(a.serviceName ?? a.toolName ?? '?'),
                    subtitle: Text(
                      '${a.decision ?? ''}${a.reason != null ? ' — ${a.reason}' : ''}$tokens',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Text(
                      a.decision ?? '',
                      style: TextStyle(color: _decisionColor(a.decision)),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
