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
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:url_launcher/url_launcher.dart';

import '../bloc/outreach_campaign_bloc.dart';
import '../bloc/outreach_message_bloc.dart';
import '../bloc/outreach_message_event.dart';
import '../bloc/outreach_message_state.dart';

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
      return Uri.parse(
        'https://www.linkedin.com/messaging/compose/?recipient=$slug',
      );
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

  Future<void> _copyAndOpen(OutreachMessage m) async {
    await Clipboard.setData(ClipboardData(text: _bodyController.text));
    final uri = _linkedInUri(m);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    if (mounted) {
      HelperFunctions.showMessage(
        context,
        'Message copied — paste it in LinkedIn',
        Colors.green,
      );
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
          return const Center(child: LoadingIndicator());
        }

        final queue = _queue(state.messages);
        if (_index >= queue.length) _index = queue.isEmpty ? 0 : queue.length - 1;
        final current = queue.isEmpty ? null : queue[_index];

        // Sync the editable body when the current message changes.
        if (current?.messageId != _loadedMessageId) {
          _loadedMessageId = current?.messageId;
          _bodyController.text = current?.messageContent ?? '';
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _header(queue.length),
            const Divider(height: 1),
            Expanded(
              child: current == null
                  ? const Center(
                      key: Key('queueEmpty'),
                      child: Text('No pending LinkedIn messages 🎉'),
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
                  hint: const Text('All campaigns'),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('All campaigns'),
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
                label: const Text('Copy & Open LinkedIn'),
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
                label: const Text('Sent → Next'),
              ),
              OutlinedButton(
                key: const Key('skipMessage'),
                onPressed: () => setState(() => _index++),
                child: const Text('Skip'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
