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

import '../../../growerp_insurance.dart';

/// One customer due for renewal: why the score, how complete the profile
/// is and what the customer allowed, the AI-drafted reminder for a
/// consented channel (editable before it goes), links to the renewal page
/// and the AI call, and the journey so far.
class RenewalCandidateDialog extends StatefulWidget {
  const RenewalCandidateDialog(this.candidate, {super.key});
  final RenewalCandidate candidate;

  @override
  State<RenewalCandidateDialog> createState() => _RenewalCandidateDialogState();
}

class _RenewalCandidateDialogState extends State<RenewalCandidateDialog> {
  final _message = TextEditingController();
  List<RenewalTouch> _touches = [];
  String? _channel;
  bool _drafting = false;
  String? _previewUrl;

  static const _messageChannels = [
    'InchZalo',
    'InchVetc',
    'InchSms',
    'InchEmail',
  ];

  @override
  void initState() {
    super.initState();
    final consented = (widget.candidate.consentChannels ?? [])
        .where(_messageChannels.contains)
        .toList();
    _channel = consented.contains(widget.candidate.nextChannelEnumId)
        ? widget.candidate.nextChannelEnumId
        : (consented.isEmpty ? null : consented.first);
    _loadTouches();
  }

  Future<void> _loadTouches() async {
    try {
      final result = await context.read<RestClient>().getRenewalTouches(
        policyId: widget.candidate.policyId,
      );
      if (mounted) setState(() => _touches = result.touches);
    } catch (_) {}
  }

  Future<void> _draft() async {
    setState(() => _drafting = true);
    try {
      var result = await context.read<RestClient>().composeRenewalMessage(
        policyId: widget.candidate.policyId,
        channelEnumId: _channel,
        language: Localizations.localeOf(context).languageCode == 'en'
            ? 'en'
            : 'vi',
      );
      if (result is String) result = jsonDecode(result);
      _message.text = result['messageText'] ?? '';
    } catch (e) {
      final message = await getDioError(e);
      if (mounted) HelperFunctions.showMessage(context, message, Colors.red);
    } finally {
      if (mounted) setState(() => _drafting = false);
    }
  }

  Future<void> _send(InsuranceLocalizations l) async {
    try {
      var result = await context.read<RestClient>().sendRenewalReminders(
        policyIds: [widget.candidate.policyId],
        channelEnumId: _channel,
        messages: _message.text.trim().isEmpty
            ? null
            : {widget.candidate.policyId: _message.text},
      );
      if (result is String) result = jsonDecode(result);
      final sent = (result['sent'] as List?) ?? [];
      if (!mounted) return;
      if (sent.isEmpty) {
        final skipped = (result['skipped'] as List?) ?? [];
        HelperFunctions.showMessage(
          context,
          skipped.isEmpty ? '' : '${skipped.first['reason']}',
          Colors.red,
        );
        return;
      }
      setState(() => _previewUrl = sent.first['previewUrl']);
      HelperFunctions.showMessage(context, l.reminderSent, Colors.green);
      _loadTouches();
    } catch (e) {
      final message = await getDioError(e);
      if (mounted) HelperFunctions.showMessage(context, message, Colors.red);
    }
  }

  Future<void> _openLink(bool voice) async {
    try {
      var result = await context.read<RestClient>().getRenewalLink(
        policyId: widget.candidate.policyId,
      );
      if (result is String) result = jsonDecode(result);
      final url = voice ? result['voiceCallUrl'] : result['renewalUrl'];
      if (url != null) await openExternalUrl(Uri.parse(url));
    } catch (e) {
      final message = await getDioError(e);
      if (mounted) HelperFunctions.showMessage(context, message, Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = InsuranceLocalizations.of(context)!;
    final c = widget.candidate;
    final theme = Theme.of(context);
    final consented = (c.consentChannels ?? []);
    return Dialog(
      key: const Key('RenewalCandidateDialog'),
      insetPadding: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: popUp(
        context: context,
        title: '${c.insuredName ?? ''} · ${c.vehiclePlate ?? ''}',
        height: 760,
        width: 560,
        child: ListView(
          key: const Key('listView'),
          children: [
            Row(
              children: [
                ScoreBadge(score: c.score, band: c.band),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${c.vehicleDescription ?? ''} · '
                    '${c.expirationDate?.toLocalizedDateOnly(context) ?? ''}'
                    ' (${l.daysLeft(c.daysToExpiry ?? 0)})',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(l.whyScore, style: theme.textTheme.titleSmall),
            for (final (i, reason) in (c.reasons ?? <String>[]).indexed)
              Text('• $reason', key: Key('reason$i')),
            const SizedBox(height: 8),
            Text(
              '${l.profileComplete(c.completeness ?? 0)}'
              '${(c.missing ?? []).isEmpty ? '' : ' · ${l.missingFields((c.missing ?? []).join(', '))}'}',
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('${l.consents}:'),
                if (consented.isEmpty) Text(l.noConsent),
                for (final ch in consented)
                  Chip(
                    label: Text(channelLabel(l, ch)),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${l.colNext}: ${actionLabel(l, c.nextAction)}'
              '${c.nextChannelEnumId == null ? '' : ' · ${channelLabel(l, c.nextChannelEnumId)}'}'
              '${c.nextTime == null ? '' : ', ${l.aroundTime(c.nextTime!)}'}',
              key: const Key('nextStep'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const Divider(height: 24),
            Text(l.reminder, style: theme.textTheme.titleSmall),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    key: const Key('reminderChannel'),
                    isExpanded: true,
                    initialValue: _channel,
                    decoration: InputDecoration(labelText: l.channel),
                    items: consented
                        .where(_messageChannels.contains)
                        .map(
                          (ch) => DropdownMenuItem(
                            value: ch,
                            child: Text(channelLabel(l, ch)),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _channel = v),
                  ),
                ),
                const SizedBox(width: 8),
                _drafting
                    ? const SizedBox(width: 120, child: LoadingIndicator())
                    : OutlinedButton.icon(
                        key: const Key('aiDraft'),
                        icon: const Icon(Icons.auto_awesome),
                        label: Text(l.aiDraft),
                        onPressed: _channel == null ? null : _draft,
                      ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              key: const Key('messageText'),
              controller: _message,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: '{link}',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  key: const Key('sendMessage'),
                  icon: const Icon(Icons.send),
                  label: Text(l.send),
                  onPressed: _channel == null ? null : () => _send(l),
                ),
                if (_previewUrl != null)
                  OutlinedButton.icon(
                    key: const Key('openPreview'),
                    icon: const Icon(Icons.phone_android),
                    label: Text(l.openPreview),
                    onPressed: () => openExternalUrl(Uri.parse(_previewUrl!)),
                  ),
                OutlinedButton.icon(
                  key: const Key('renewalPage'),
                  icon: const Icon(Icons.open_in_new),
                  label: Text(l.openRenewalPage),
                  onPressed: () => _openLink(false),
                ),
                OutlinedButton.icon(
                  key: const Key('aiCall'),
                  icon: const Icon(Icons.support_agent),
                  label: Text(l.aiCall),
                  onPressed: () => _openLink(true),
                ),
              ],
            ),
            const Divider(height: 24),
            Text(l.journey, style: theme.textTheme.titleSmall),
            for (final (i, t) in _touches.indexed)
              ListTile(
                key: Key('touch$i'),
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(
                  '${eventLabel(l, t.eventEnumId)} · ${channelLabel(l, t.channelEnumId)}'
                  '${t.outcomeEnumId == null ? '' : ' · ${outcomeLabel(l, t.outcomeEnumId)}'}',
                ),
                subtitle: Text(
                  '${t.touchDate?.toLocalizedDateOnly(context) ?? ''}'
                  '${t.summary == null ? '' : ' · ${t.summary}'}',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }
}
