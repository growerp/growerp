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

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../../growerp_insurance.dart';

/// The renewal cockpit: the customers due for renewal, best first, each
/// with an explainable lead score and the next best step, above the funnel
/// of the renewal journey. Reminders go out on the channel the customer
/// consented to and reacts on.
class RenewalCockpit extends StatefulWidget {
  const RenewalCockpit({super.key});

  @override
  State<RenewalCockpit> createState() => _RenewalCockpitState();
}

class _RenewalCockpitState extends State<RenewalCockpit> {
  List<RenewalCandidate> _candidates = [];
  Map<String, dynamic> _funnel = {};
  String? _band;
  String _search = '';
  bool _loading = true;
  int _request = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final request = ++_request;
    setState(() => _loading = true);
    final rest = context.read<RestClient>();
    try {
      final result = await rest.getRenewalCandidates(
        band: _band,
        search: _search.isEmpty ? null : _search,
        limit: 300,
      );
      var funnel = await rest.getRenewalFunnel();
      if (funnel is String) funnel = jsonDecode(funnel);
      if (!mounted || request != _request) return;
      setState(() {
        _candidates = result.candidates;
        _funnel = Map<String, dynamic>.from(funnel['funnel'] ?? {});
        _loading = false;
      });
    } catch (e) {
      final message = await getDioError(e);
      if (!mounted) return;
      setState(() => _loading = false);
      HelperFunctions.showMessage(context, message, Colors.red);
    }
  }

  Future<void> _sendDue(InsuranceLocalizations l) async {
    final ids = _candidates
        .where((c) => c.nextAction == 'Send reminder')
        .map((c) => c.policyId)
        .toList();
    if (ids.isEmpty) return;
    try {
      var result = await context.read<RestClient>().sendRenewalReminders(
        policyIds: ids,
      );
      if (result is String) result = jsonDecode(result);
      if (!mounted) return;
      HelperFunctions.showMessage(
        context,
        l.sentResult(
          result['sentCount'] ?? 0,
          (result['skipped'] as List?)?.length ?? 0,
        ),
        Colors.green,
      );
      _load();
    } catch (e) {
      final message = await getDioError(e);
      if (mounted) HelperFunctions.showMessage(context, message, Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = InsuranceLocalizations.of(context)!;
    final isPhone = ResponsiveBreakpoints.of(context).isMobile;
    return Column(
      key: const Key('RenewalCockpit'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _funnelStrip(l),
        ListFilterBar(
          searchHint: l.searchHint,
          onSearchChanged: (value) {
            _search = value;
            _load();
          },
          filters: [
            for (final band in [null, 'High', 'Medium', 'Low', 'Done', 'Stop'])
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: ChoiceChip(
                  key: Key('band${band ?? 'All'}'),
                  label: Text(bandLabel(l, band)),
                  selected: _band == band,
                  onSelected: (_) {
                    _band = band;
                    _load();
                  },
                ),
              ),
          ],
          actions: [
            FilledButton.icon(
              key: const Key('sendDue'),
              icon: const Icon(Icons.send),
              label: Text(l.sendDue),
              onPressed: _loading ? null : () => _sendDue(l),
            ),
          ],
        ),
        Expanded(
          child: StyledDataTable(
            key: const Key('renewalList'),
            isLoading: _loading && _candidates.isEmpty,
            rowHeight: isPhone ? 76 : 60,
            columns: [
              StyledColumn(header: l.colCustomer, flex: 3),
              if (!isPhone) StyledColumn(header: l.colEnds, flex: 1),
              StyledColumn(header: l.colScore, flex: 2),
              StyledColumn(header: l.colNext, flex: 3),
              if (!isPhone) StyledColumn(header: l.colStage, flex: 2),
            ],
            rows: [
              for (final (i, c) in _candidates.indexed)
                [
                  Column(
                    key: Key('item$i'),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        c.insuredName ?? '',
                        key: Key('name$i'),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${c.vehiclePlate ?? ''}'
                        '${isPhone ? ' · ${l.daysLeft(c.daysToExpiry ?? 0)}' : ''}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  if (!isPhone) Text(l.daysLeft(c.daysToExpiry ?? 0)),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ScoreBadge(
                      key: Key('score$i'),
                      score: c.score,
                      band: c.band,
                    ),
                  ),
                  Text(
                    '${actionLabel(l, c.nextAction)}'
                    '${c.nextChannelEnumId == null ? '' : ' · ${channelLabel(l, c.nextChannelEnumId)}'}',
                    key: Key('next$i'),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                  if (!isPhone)
                    Text(
                      eventLabel(l, c.stage),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
            ],
            onRowTap: (index) async {
              await showDialog(
                context: context,
                barrierDismissible: true,
                builder: (_) => RenewalCandidateDialog(_candidates[index]),
              );
              _load();
            },
          ),
        ),
      ],
    );
  }

  Widget _funnelStrip(InsuranceLocalizations l) {
    final stages = Map<String, dynamic>.from(_funnel['stages'] ?? {});
    final total = (stages['total'] ?? 0) as int;
    final steps = [
      ('total', l.funnelDue),
      ('InevSent', l.funnelSent),
      ('InevOpened', l.funnelOpened),
      ('InevVisited', l.funnelVisited),
      ('InevConfirmed', l.funnelConfirmed),
      ('InevRenewRequested', l.funnelRequested),
      ('InevRenewed', l.funnelRenewed),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Wrap(
        key: const Key('funnel'),
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final (key, label) in steps)
            Container(
              key: Key('funnel_$key'),
              width: 132,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.bodySmall),
                  Text(
                    '${stages[key] ?? 0}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (key != 'total' && total > 0)
                    Text(
                      '${((stages[key] ?? 0) * 100 / total).round()}%',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
