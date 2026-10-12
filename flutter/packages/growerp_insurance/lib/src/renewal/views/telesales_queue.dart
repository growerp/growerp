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
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../../growerp_insurance.dart';

/// The telesales queue: customers who asked for a call, whom the AI call
/// handed over, or who asked to renew; with the AI summary so the colleague
/// starts where the AI stopped. The colleague records a CRM outcome code;
/// "Renewed" renews the policy.
class TelesalesQueue extends StatefulWidget {
  const TelesalesQueue({super.key});

  @override
  State<TelesalesQueue> createState() => _TelesalesQueueState();
}

class _TelesalesQueueState extends State<TelesalesQueue> {
  List<RenewalCandidate> _queue = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final result = await context.read<RestClient>().getTelesalesQueue();
      if (mounted) {
        setState(() {
          _queue = result.queue;
          _loading = false;
        });
      }
    } catch (e) {
      final message = await getDioError(e);
      if (!mounted) return;
      setState(() => _loading = false);
      HelperFunctions.showMessage(context, message, Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = InsuranceLocalizations.of(context)!;
    final isPhone = ResponsiveBreakpoints.of(context).isMobile;
    if (!_loading && _queue.isEmpty) {
      return Center(child: Text(l.queueEmpty, key: const Key('queueEmpty')));
    }
    return Column(
      key: const Key('TelesalesQueue'),
      children: [
        Expanded(
          child: StyledDataTable(
            key: const Key('telesalesList'),
            isLoading: _loading && _queue.isEmpty,
            rowHeight: isPhone ? 84 : 64,
            columns: [
              StyledColumn(header: l.colCustomer, flex: 3),
              StyledColumn(header: l.colNext, flex: 2),
              StyledColumn(header: l.colScore, flex: 2),
              if (!isPhone) StyledColumn(header: l.aiSummary, flex: 5),
            ],
            rows: [
              for (final (i, c) in _queue.indexed)
                [
                  Column(
                    key: Key('item$i'),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(c.insuredName ?? '', key: Key('qname$i')),
                      Text(
                        '${c.vehiclePlate ?? ''} · ${l.daysLeft(c.daysToExpiry ?? 0)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  Text(
                    eventLabel(l, c.reason),
                    key: Key('qreason$i'),
                    maxLines: 2,
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ScoreBadge(score: c.score, band: c.band),
                  ),
                  if (!isPhone)
                    Text(
                      c.aiSummary ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
            ],
            onRowTap: (index) async {
              final saved = await showDialog<bool>(
                context: context,
                barrierDismissible: true,
                builder: (_) => _OutcomeDialog(_queue[index]),
              );
              if (saved == true) _load();
            },
          ),
        ),
      ],
    );
  }
}

class _OutcomeDialog extends StatefulWidget {
  const _OutcomeDialog(this.candidate);
  final RenewalCandidate candidate;

  @override
  State<_OutcomeDialog> createState() => _OutcomeDialogState();
}

class _OutcomeDialogState extends State<_OutcomeDialog> {
  final _notes = TextEditingController();
  String _outcome = 'InocRenewed';
  List<RenewalTouch> _touches = [];

  @override
  void initState() {
    super.initState();
    context
        .read<RestClient>()
        .getRenewalTouches(policyId: widget.candidate.policyId)
        .then((r) {
          if (mounted) setState(() => _touches = r.touches);
        })
        .catchError((_) {});
  }

  Future<void> _save(InsuranceLocalizations l) async {
    try {
      await context.read<RestClient>().recordCallOutcome(
        policyId: widget.candidate.policyId,
        outcomeEnumId: _outcome,
        notes: _notes.text,
      );
      if (!mounted) return;
      HelperFunctions.showMessage(context, l.outcomeSaved, Colors.green);
      Navigator.of(context).pop(true);
    } catch (e) {
      final message = await getDioError(e);
      if (mounted) HelperFunctions.showMessage(context, message, Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = InsuranceLocalizations.of(context)!;
    final c = widget.candidate;
    final transcript = _touches
        .firstWhere(
          (t) => (t.transcript ?? '').isNotEmpty,
          orElse: () => RenewalTouch(),
        )
        .transcript;
    return Dialog(
      key: const Key('TelesalesDialog'),
      insetPadding: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: popUp(
        context: context,
        title: '${c.insuredName ?? ''} · ${c.vehiclePlate ?? ''}',
        height: 640,
        width: 520,
        child: ListView(
          key: const Key('listView'),
          children: [
            Row(
              children: [
                ScoreBadge(score: c.score, band: c.band),
                const SizedBox(width: 8),
                Expanded(child: Text(eventLabel(l, c.reason))),
              ],
            ),
            const SizedBox(height: 12),
            if ((c.aiSummary ?? '').isNotEmpty) ...[
              Text(l.aiSummary, style: Theme.of(context).textTheme.titleSmall),
              Card(
                color: Theme.of(context).colorScheme.secondaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Text(c.aiSummary!, key: const Key('aiSummary')),
                ),
              ),
            ],
            if ((transcript ?? '').isNotEmpty)
              ExpansionTile(
                key: const Key('transcript'),
                tilePadding: EdgeInsets.zero,
                title: Text(l.transcript),
                children: [Text(transcript!)],
              ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: const Key('outcome'),
              isExpanded: true,
              initialValue: _outcome,
              decoration: InputDecoration(labelText: l.callOutcome),
              items: outcomeIds
                  .map(
                    (id) => DropdownMenuItem(
                      value: id,
                      child: Text(outcomeLabel(l, id)),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _outcome = v ?? _outcome),
            ),
            const SizedBox(height: 8),
            TextField(
              key: const Key('callNotes'),
              controller: _notes,
              maxLines: 2,
              decoration: InputDecoration(labelText: l.notes),
            ),
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('recordOutcome'),
              onPressed: () => _save(l),
              child: Text(l.save),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }
}
