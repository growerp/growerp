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
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

import '../bloc/outreach_campaign_bloc.dart';
import '../bloc/outreach_message_bloc.dart';
import '../bloc/outreach_message_event.dart';
import '../bloc/outreach_message_state.dart';
import 'package:growerp_outreach/l10n/generated/outreach_localizations.dart';

/// Assisted 1-click LinkedIn send queue.
///
/// Shows PENDING LINKEDIN [OutreachMessage]s one at a time. Hans reviews the
/// AI-personalised body, taps "Copy & Open LinkedIn" (copies the text to the
/// clipboard and opens the prospect's LinkedIn message composer), pastes and
/// sends in LinkedIn, then taps "Sent" to mark it SENT and advance. No browser
/// automation, no copy-paste juggling, no LinkedIn-ban risk.
class LinkedInSendQueueScreen extends StatefulWidget {
  const LinkedInSendQueueScreen({super.key});

  @override
  State<LinkedInSendQueueScreen> createState() =>
      _LinkedInSendQueueScreenState();
}

class _LinkedInSendQueueScreenState extends State<LinkedInSendQueueScreen> {
  late OutreachMessageBloc _messageBloc;
  final _bodyController = TextEditingController();

  /// Pointer into the filtered LINKEDIN-PENDING queue. Sent messages leave the
  /// queue on their own (status flips to SENT), so we only advance on Skip.
  int _index = 0;

  /// Campaign filter — null = all campaigns.
  String? _campaignId;

  /// messageId whose body is currently loaded into [_bodyController].
  String? _loadedMessageId;

  bool _polishing = false;

  @override
  void initState() {
    super.initState();
    _messageBloc = context.read<OutreachMessageBloc>()
      ..add(const OutreachMessageLoad(start: 0, limit: 200, status: 'PENDING'));
    context.read<OutreachCampaignBloc>().add(
      const OutreachCampaignFetch(limit: 100),
    );
  }

  @override
  void dispose() {
    _bodyController.dispose();
    super.dispose();
  }

  List<OutreachMessage> _queue(List<OutreachMessage> all) => all
      .where(
        (m) =>
            m.platform == 'LINKEDIN' &&
            m.status == 'PENDING' &&
            (_campaignId == null || m.campaignId == _campaignId),
      )
      .toList();

  /// Build the LinkedIn URL to open: the message composer when the public slug
  /// is derivable, else the raw profile page.
  Uri? _linkedInUri(OutreachMessage m) {
    final slug = _slug(m);
    if (slug != null) {
      return Uri.https('www.linkedin.com', '/messaging/compose/', {
        'recipient': slug,
      });
    }
    final url = m.recipientProfileUrl;
    if (url != null && url.isNotEmpty) return Uri.tryParse(url);
    return null;
  }

  /// Derive the LinkedIn public identifier from the handle or the `/in/<slug>`
  /// segment of the profile URL.
  String? _slug(OutreachMessage m) {
    final handle = m.recipientHandle?.trim();
    if (handle != null && handle.isNotEmpty && !handle.contains('/')) {
      return handle;
    }
    final url = m.recipientProfileUrl ?? handle ?? '';
    final match = RegExp(r'/in/([^/?#]+)').firstMatch(url);
    return match?.group(1);
  }

  /// Fill any template placeholders still present in a stored message body
  /// (older imports only substituted {name}/{company}/{title}). LinkedIn is
  /// sent from here, not by the server, so this is the last chance to resolve
  /// a token: {landingPageUrl} comes from the message's campaign, which the
  /// campaign bloc already holds.
  String _substitute(OutreachMessage m, String text) {
    final name = (m.recipientName ?? '').trim();
    final firstName = name.isEmpty ? '' : name.split(RegExp(r'\s+')).first;
    final substituted = text
        .replaceAll('{name}', name)
        .replaceAll('{firstName}', firstName)
        .replaceAll('{company}', m.recipientCompany ?? '')
        .replaceAll('{companyName}', m.recipientCompany ?? '')
        .replaceAll('{title}', m.recipientTitle ?? '');
    final landingPageUrl = _landingPageUrl(m);
    // null = the campaigns are still loading; dropping the token now would
    // lose the link for good, so leave it and substitute on the rebuild
    return landingPageUrl == null
        ? substituted
        : substituted.replaceAll('{landingPageUrl}', landingPageUrl);
  }

  /// Public landing page url of the message's campaign: empty when the
  /// campaign has none, null while the campaign list has not arrived yet.
  String? _landingPageUrl(OutreachMessage m) {
    final campaigns = context.read<OutreachCampaignBloc>().state.campaigns;
    if (campaigns.isEmpty) return null;
    for (final campaign in campaigns) {
      if (campaign.campaignId == m.campaignId) {
        return campaign.landingPageUrl ?? '';
      }
    }
    return '';
  }

  Future<void> _copyAndOpen(OutreachMessage m) async {
    await Clipboard.setData(ClipboardData(text: _bodyController.text));
    final uri = _linkedInUri(m);
    if (uri == null) {
      if (mounted) {
        HelperFunctions.showMessage(
          context,
          'Message copied, however this contact has no LinkedIn '
          'handle or profile url',
          Colors.red,
        );
      }
      return;
    }
    final opened = await openExternalUrl(uri);
    if (mounted) {
      HelperFunctions.showMessage(
        context,
        opened
            ? 'Message copied — paste it in LinkedIn'
            : 'Message copied, however could not open a browser, use: $uri',
        opened ? Colors.green : Colors.red,
      );
    }
  }

  Future<void> _polish(OutreachMessage m) async {
    if (m.messageId == null || _bodyController.text.isEmpty) return;
    setState(() => _polishing = true);
    try {
      final result = await _messageBloc.restClient.polishOutreachMessage(
        draftMessage: _bodyController.text,
        platform: m.platform,
        recipientName: m.recipientName,
        recipientCompany: m.recipientCompany,
        recipientTitle: m.recipientTitle,
      );
      final polished = result['polishedMessage'];
      if (polished != null && polished.isNotEmpty) {
        await _messageBloc.restClient.updateOutreachMessageContent(
          messageId: m.messageId!,
          messageContent: polished,
        );
        setState(() => _bodyController.text = polished);
      }
    } catch (e) {
      if (mounted) {
        HelperFunctions.showMessage(context, 'AI polish failed: $e', Colors.red);
      }
    } finally {
      if (mounted) setState(() => _polishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OutreachMessageBloc, OutreachMessageState>(
      listener: (context, state) {
        if (state.status == OutreachMessageStatus.failure) {
          HelperFunctions.showMessage(context, '${state.message}', Colors.red);
        }
      },
      builder: (context, state) {
        if (state.status == OutreachMessageStatus.loading &&
            state.messages.isEmpty) {
          return Center(child: LoadingIndicator());
        }

        final queue = _queue(state.messages);
        if (_index >= queue.length) _index = queue.isEmpty ? 0 : queue.length - 1;
        final current = queue.isEmpty ? null : queue[_index];

        // Sync the editable body when the current message changes, and once
        // more when a still-open {landingPageUrl} can finally be resolved
        // (the campaign list arrives after the first build).
        if (current?.messageId != _loadedMessageId ||
            (current != null &&
                _bodyController.text.contains('{landingPageUrl}') &&
                _landingPageUrl(current) != null)) {
          _loadedMessageId = current?.messageId;
          _bodyController.text = current == null
              ? ''
              : _substitute(current, current.messageContent);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _header(queue.length),
            const Divider(height: 1),
            Expanded(
              child: current == null
                  ? Center(
                      key: Key('queueEmpty'),
                      child: Text(OutreachLocalizations.of(context)!.noPendingLinkedinMessages),
                    )
                  : _card(current),
            ),
          ],
        );
      },
    );
  }

  Widget _header(int pending) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          const Text(
            'LinkedIn Send Queue',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: BlocBuilder<OutreachCampaignBloc, OutreachCampaignState>(
              builder: (context, cState) {
                return DropdownButton<String?>(
                  key: const Key('queueCampaign'),
                  isExpanded: true,
                  value: _campaignId,
                  hint: Text(OutreachLocalizations.of(context)!.allCampaigns),
                  items: [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text(OutreachLocalizations.of(context)!.allCampaigns),
                    ),
                    ...cState.campaigns.map(
                      (c) => DropdownMenuItem<String?>(
                        value: c.campaignId,
                        child: Text(
                          c.name.isEmpty ? (c.pseudoId ?? '?') : c.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                  onChanged: (v) => setState(() {
                    _campaignId = v;
                    _index = 0;
                  }),
                );
              },
            ),
          ),
          const SizedBox(width: 16),
          Chip(label: Text('$pending pending')),
        ],
      ),
    );
  }

  Widget _card(OutreachMessage m) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            m.recipientName ?? 'Unknown',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          if ((m.recipientCompany ?? '').isNotEmpty ||
              (m.recipientTitle ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                [
                  if ((m.recipientTitle ?? '').isNotEmpty) m.recipientTitle,
                  if ((m.recipientCompany ?? '').isNotEmpty)
                    'at ${m.recipientCompany}',
                ].join(' '),
                style: TextStyle(color: Theme.of(context).hintColor),
              ),
            ),
          if ((m.recipientProfileUrl ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                m.recipientProfileUrl!,
                style: TextStyle(color: Theme.of(context).hintColor),
              ),
            ),
          const SizedBox(height: 16),
          TextField(
            key: const Key('queueMessageBody'),
            controller: _bodyController,
            maxLines: 8,
            minLines: 4,
            decoration: const InputDecoration(
              labelText: 'Message (edit before sending)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ElevatedButton.icon(
                key: const Key('copyOpenLinkedIn'),
                onPressed: () => _copyAndOpen(m),
                icon: const Icon(Icons.open_in_new),
                label: Text(OutreachLocalizations.of(context)!.copyOpenLinkedin),
              ),
              ElevatedButton.icon(
                key: const Key('polishMessage'),
                onPressed: _polishing ? null : () => _polish(m),
                icon: _polishing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome),
                label: Text(OutreachLocalizations.of(context)!.aiPolish),
              ),
              ElevatedButton.icon(
                key: const Key('markSentNext'),
                onPressed: () => _messageBloc.add(
                  OutreachMessageUpdateStatus(
                    messageId: m.messageId!,
                    status: 'SENT',
                  ),
                ),
                icon: const Icon(Icons.check),
                label: Text(OutreachLocalizations.of(context)!.sentNext),
              ),
              OutlinedButton(
                key: const Key('skipMessage'),
                onPressed: () => setState(() => _index++),
                child: Text(OutreachLocalizations.of(context)!.skip),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
