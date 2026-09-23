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
import 'adk_config_service.dart';

/// Support App View: the catalog-promotion review queue — tenant agents opted
/// in via "Suggest for shared catalog" (AdkAgentConfigDialog), across every
/// tenant. Restricted server-side to GrowERP support (GROWERP_M_SYSTEM).
///
/// This is the human-curated half of catalog promotion: a tenant nominating
/// an agent never makes it visible here on its own logic alone — support
/// reviews the actual instruction/serviceAllowlist before promoting it into
/// the shared "_NA_" catalog that every tenant's function-catalog picker
/// (AdkFunctionCatalogView) reads from.
class AdkCatalogPromotionView extends StatefulWidget {
  const AdkCatalogPromotionView({super.key});

  @override
  State<AdkCatalogPromotionView> createState() =>
      _AdkCatalogPromotionViewState();
}

class _AdkCatalogPromotionViewState extends State<AdkCatalogPromotionView> {
  List<AdkAgentConfig> _agents = [];
  bool _loading = true;
  String? _error;
  final Set<String> _promoting = {};

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
      final svc = await AdkConfigService.create();
      final list = await svc.nominatedAgents();
      if (mounted) setState(() => _agents = list);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showDetail(AdkAgentConfig a) async {
    final phone = isAPhone(context);
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
        key: const Key('AdkCatalogPromotionDetail'),
        insetPadding: const EdgeInsets.all(10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: popUp(
          context: dctx,
          title: 'Review before promoting',
          width: phone ? 400 : 700,
          height: phone ? 600 : 560,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                line('Agent name', a.agentName),
                line('Tenant (owner)', a.ownerPartyId),
                line('Team', a.teamName),
                line('Description', a.description),
                line('Tool mode', a.toolMode),
                line('Write policy', a.writePolicy),
                line('Service allowlist', a.serviceAllowlist),
                line('Instruction', a.instruction),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(dctx),
                      child: const Text('Close'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      key: const Key('confirmPromote'),
                      onPressed: () {
                        Navigator.pop(dctx);
                        _promote(a);
                      },
                      child: const Text('Promote to shared catalog'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _promote(AdkAgentConfig a) async {
    final id = a.adkAgentConfigId;
    if (id == null) return;
    setState(() => _promoting.add(id));
    try {
      final svc = await AdkConfigService.create();
      await svc.promoteToCatalog(id);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${a.agentName} promoted to the shared catalog'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Promote failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _promoting.remove(id));
    }
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
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Catalog promotion queue',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  key: const Key('refreshCatalogPromotion'),
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh',
                  onPressed: _load,
                ),
              ],
            ),
          ),
          if (_loading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_agents.isEmpty)
            const Expanded(
              child: Center(child: Text('No agents nominated for the catalog.')),
            )
          else
            Expanded(
              child: ListView.builder(
                key: const Key('catalogPromotionList'),
                itemCount: _agents.length,
                itemBuilder: (context, index) {
                  final a = _agents[index];
                  final id = a.adkAgentConfigId ?? '';
                  return ListTile(
                    key: Key('nominated_$id'),
                    title: Text(a.agentName ?? ''),
                    subtitle: Text(
                      '${a.ownerPartyId ?? ''} · ${a.teamName ?? 'No team'}\n'
                      '${a.description ?? ''}',
                    ),
                    isThreeLine: true,
                    onTap: () => _showDetail(a),
                    trailing: FilledButton(
                      key: Key('promote_$id'),
                      onPressed: _promoting.contains(id)
                          ? null
                          : () => _showDetail(a),
                      child: _promoting.contains(id)
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Review'),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
