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

import '../bloc/outreach_message_bloc.dart';
import '../bloc/outreach_message_event.dart';
import '../bloc/outreach_message_state.dart';

class OutreachMessageDetailScreen extends StatefulWidget {
  final OutreachMessage message;

  const OutreachMessageDetailScreen({
    super.key,
    required this.message,
  });

  @override
  OutreachMessageDetailScreenState createState() =>
      OutreachMessageDetailScreenState();
}

class OutreachMessageDetailScreenState
    extends State<OutreachMessageDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _recipientNameController;
  late TextEditingController _recipientEmailController;
  late TextEditingController _recipientProfileUrlController;
  late TextEditingController _recipientHandleController;
  late TextEditingController _messageContentController;
  late TextEditingController _emailSubjectController;

  /// Body and subject can only be changed while the message has not been sent:
  /// update#OutreachMessageContent refuses anything but PENDING
  bool get _isEditable =>
      widget.message.messageId == null || widget.message.status == 'PENDING';

  final List<String> _availablePlatforms = [
    'EMAIL',
    'LINKEDIN',
  ];

  final List<String> _statusOptions = [
    'PENDING',
    'SENT',
    'RESPONDED',
    'FAILED',
  ];

  late String _selectedPlatform;
  late String _selectedStatus;
  String? _selectedCampaignId;

  /// Name of the campaign an existing message belongs to, id until loaded
  String? _campaignLabel;

  @override
  void initState() {
    super.initState();
    _recipientNameController =
        TextEditingController(text: widget.message.recipientName ?? '');
    _recipientEmailController =
        TextEditingController(text: widget.message.recipientEmail ?? '');
    _recipientProfileUrlController =
        TextEditingController(text: widget.message.recipientProfileUrl ?? '');
    _recipientHandleController =
        TextEditingController(text: widget.message.recipientHandle ?? '');
    _messageContentController =
        TextEditingController(text: widget.message.messageContent);
    _emailSubjectController =
        TextEditingController(text: widget.message.emailSubject ?? '');
    _selectedCampaignId = widget.message.campaignId;

    _selectedPlatform = _availablePlatforms.contains(widget.message.platform)
        ? widget.message.platform
        : 'EMAIL';
    _selectedStatus =
        widget.message.status.isNotEmpty ? widget.message.status : 'PENDING';

    _loadCampaignLabel();
  }

  /// Resolve the campaign name of an existing message for the read-only display
  Future<void> _loadCampaignLabel() async {
    final id = widget.message.campaignId;
    if (id == null || id.isEmpty) return;
    try {
      final result = await RepositoryProvider.of<RestClient>(context)
          .getOutreachCampaigns(marketingCampaignId: id, limit: 1);
      if (!mounted || result.campaigns.isEmpty) return;
      final campaign = result.campaigns.first;
      setState(() {
        _campaignLabel = '${campaign.name} (${campaign.pseudoId ?? id})';
      });
    } catch (e) {
      // keep showing the raw id
    }
  }

  /// Campaign selection for a new message: a message without a campaign is
  /// never sent (the automation queries per campaign) and has no owner, so the
  /// campaign is required. Searches server-side on name/id, there can be many.
  Widget _campaignSelector() {
    return AutocompleteLabel<OutreachCampaign>(
      key: const Key('campaignId'),
      label: 'Campaign *',
      hintText: 'Type to search campaigns',
      optionsBuilder: (TextEditingValue textEditingValue) =>
          RepositoryProvider.of<RestClient>(context)
              .listOutreachCampaigns(
                searchString: textEditingValue.text,
                limit: 10,
              )
              .then((result) => result.campaigns),
      displayStringForOption: (OutreachCampaign campaign) =>
          '${campaign.name} (${campaign.pseudoId})',
      onSelected: (OutreachCampaign? campaign) {
        setState(() => _selectedCampaignId = campaign?.campaignId);
      },
      validator: (OutreachCampaign? campaign) =>
          _selectedCampaignId == null || _selectedCampaignId!.isEmpty
              ? 'Please select a campaign'
              : null,
    );
  }

  @override
  void dispose() {
    _recipientNameController.dispose();
    _recipientEmailController.dispose();
    _recipientProfileUrlController.dispose();
    _recipientHandleController.dispose();
    _messageContentController.dispose();
    _emailSubjectController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPhone = ResponsiveBreakpoints.of(context).isMobile;
    final messageBloc = context.read<OutreachMessageBloc>();
    final isNewMessage = widget.message.messageId == null;

    return Dialog(
      key: Key('MessageDetail${widget.message.messageId ?? 'New'}'),
      insetPadding: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: popUp(
        context: context,
        title: isNewMessage
            ? 'New Outreach Message'
            : 'Message #${widget.message.messageId}',
        width: isPhone ? 400 : 700,
        height: isPhone ? 700 : 650,
        child: BlocListener<OutreachMessageBloc, OutreachMessageState>(
          listener: (context, state) {
            if (state.status == OutreachMessageStatus.success) {
              if ((state.message ?? '').isNotEmpty) {
                Navigator.of(context).pop();
              }
            }
            if (state.status == OutreachMessageStatus.failure) {
              HelperFunctions.showMessage(
                context,
                state.message ?? 'An error occurred',
                Colors.red,
              );
            }
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // For desktop: ID, Status, Platform in one row
                  // For mobile: Campaign ID on its own, then Status and Platform
                  if (!isPhone && isNewMessage)
                    Row(
                      children: [
                        Expanded(child: _campaignSelector()),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            key: const Key('status'),
                            decoration:
                                const InputDecoration(labelText: 'Status'),
                            initialValue: _selectedStatus,
                            items: _statusOptions.map((status) {
                              return DropdownMenuItem<String>(
                                value: status,
                                child: Text(status),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedStatus = newValue ?? 'PENDING';
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            key: const Key('platform'),
                            decoration:
                                const InputDecoration(labelText: 'Platform *'),
                            initialValue: _selectedPlatform,
                            items: _availablePlatforms.map((platform) {
                              return DropdownMenuItem<String>(
                                value: platform,
                                child: Text(platform),
                              );
                            }).toList(),
                            onChanged: isNewMessage
                                ? (String? newValue) {
                                    setState(() {
                                      _selectedPlatform = newValue ?? 'EMAIL';
                                    });
                                  }
                                : null,
                          ),
                        ),
                      ],
                    ),

                  // For mobile: Campaign on its own line
                  if (isPhone && isNewMessage) _campaignSelector(),
                  if (isNewMessage) const SizedBox(height: 20),

                  // For existing messages: show the (read-only) campaign it belongs to
                  if (!isNewMessage)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: InputDecorator(
                        decoration:
                            const InputDecoration(labelText: 'Campaign'),
                        child: Text(
                          _campaignLabel ??
                              widget.message.campaignId ??
                              '(none)',
                          key: const Key('campaignDisplay'),
                        ),
                      ),
                    ),

                  // For desktop (existing message): Status and Platform in one row
                  if (!isPhone && !isNewMessage)
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            key: const Key('status'),
                            decoration:
                                const InputDecoration(labelText: 'Status'),
                            initialValue: _selectedStatus,
                            items: _statusOptions.map((status) {
                              return DropdownMenuItem<String>(
                                value: status,
                                child: Text(status),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedStatus = newValue ?? 'PENDING';
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            key: const Key('platform'),
                            decoration:
                                const InputDecoration(labelText: 'Platform'),
                            initialValue: _selectedPlatform,
                            items: _availablePlatforms.map((platform) {
                              return DropdownMenuItem<String>(
                                value: platform,
                                child: Text(platform),
                              );
                            }).toList(),
                            onChanged: null, // Read-only for existing messages
                          ),
                        ),
                      ],
                    ),

                  // For mobile: Platform and Status in one row
                  if (isPhone)
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            key: const Key('platform'),
                            decoration:
                                const InputDecoration(labelText: 'Platform *'),
                            initialValue: _selectedPlatform,
                            items: _availablePlatforms.map((platform) {
                              return DropdownMenuItem<String>(
                                value: platform,
                                child: Text(platform),
                              );
                            }).toList(),
                            onChanged: isNewMessage
                                ? (String? newValue) {
                                    setState(() {
                                      _selectedPlatform = newValue ?? 'EMAIL';
                                    });
                                  }
                                : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            key: const Key('status'),
                            decoration:
                                const InputDecoration(labelText: 'Status'),
                            initialValue: _selectedStatus,
                            items: _statusOptions.map((status) {
                              return DropdownMenuItem<String>(
                                value: status,
                                child: Text(status),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedStatus = newValue ?? 'PENDING';
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  if (!isNewMessage) const SizedBox(height: 20),

                  // Recipient Information
                  TextFormField(
                    key: const Key('recipientName'),
                    controller: _recipientNameController,
                    decoration:
                        const InputDecoration(labelText: 'Recipient Name'),
                  ),
                  const SizedBox(height: 20),

                  TextFormField(
                    key: const Key('recipientEmail'),
                    controller: _recipientEmailController,
                    decoration:
                        const InputDecoration(labelText: 'Recipient Email'),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 20),

                  TextFormField(
                    key: const Key('recipientHandle'),
                    controller: _recipientHandleController,
                    decoration: const InputDecoration(
                        labelText: 'Recipient Handle (e.g., @username)'),
                  ),
                  const SizedBox(height: 20),

                  TextFormField(
                    key: const Key('recipientProfileUrl'),
                    controller: _recipientProfileUrlController,
                    decoration: const InputDecoration(
                        labelText: 'Recipient Profile URL'),
                  ),
                  const SizedBox(height: 20),

                  // Subject: EMAIL only, empty falls back to the campaign's
                  if (_selectedPlatform == 'EMAIL') ...[
                    TextFormField(
                      key: const Key('emailSubject'),
                      controller: _emailSubjectController,
                      readOnly: !_isEditable,
                      decoration: const InputDecoration(
                        labelText: 'Email Subject',
                        helperText: 'Empty uses the campaign subject; '
                            '{name} etc. are substituted when sent',
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Message Content
                  TextFormField(
                    key: const Key('messageContent'),
                    controller: _messageContentController,
                    readOnly: !_isEditable,
                    decoration:
                        const InputDecoration(labelText: 'Message Content *'),
                    maxLines: 5,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter message content';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Display dates for existing messages
                  if (!isNewMessage) ...[
                    if (widget.message.sentDate != null)
                      Text(
                        'Sent: ${widget.message.sentDate.toLocalizedString(context, format: 'MMM dd, yyyy HH:mm')}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    if (widget.message.responseDate != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Response: ${widget.message.responseDate.toLocalizedString(context, format: 'MMM dd, yyyy HH:mm')}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                    if (widget.message.attemptCount > 0) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Attempts: ${widget.message.attemptCount}'
                        '${widget.message.lastAttemptDate != null ? ', last '
                            '${widget.message.lastAttemptDate.toLocalizedString(context, format: 'MMM dd, yyyy HH:mm')}' : ''}',
                        key: const Key('attemptCount'),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                    if (widget.message.errorMessage != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Error: ${widget.message.errorMessage}',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Colors.red),
                      ),
                    ],
                    const SizedBox(height: 20),
                  ],

                  // Action Buttons
                  Row(
                    children: [
                      // exhausted its send attempts: requeue it with the
                      // counter reset so the automation sends it again
                      if (widget.message.status == 'FAILED') ...[
                        Expanded(
                          child: OutlinedButton.icon(
                            key: const Key('retryMessage'),
                            onPressed: () => messageBloc.add(
                              OutreachMessageRetry(
                                messageId: widget.message.messageId,
                              ),
                            ),
                            icon: const Icon(Icons.refresh, size: 18),
                            label: const Text('Retry'),
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        child: ElevatedButton(
                          key: const Key('saveMessage'),
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              if (isNewMessage) {
                                // Create new message
                                messageBloc.add(OutreachMessageCreate(
                                  campaignId: _selectedCampaignId!,
                                  platform: _selectedPlatform,
                                  recipientName:
                                      _recipientNameController.text.isEmpty
                                          ? null
                                          : _recipientNameController.text,
                                  recipientEmail:
                                      _recipientEmailController.text.isEmpty
                                          ? null
                                          : _recipientEmailController.text,
                                  recipientHandle:
                                      _recipientHandleController.text.isEmpty
                                          ? null
                                          : _recipientHandleController.text,
                                  recipientProfileUrl:
                                      _recipientProfileUrlController
                                              .text.isEmpty
                                          ? null
                                          : _recipientProfileUrlController.text,
                                  messageContent:
                                      _messageContentController.text,
                                  emailSubject:
                                      _emailSubjectController.text.isEmpty
                                          ? null
                                          : _emailSubjectController.text,
                                ));
                              } else {
                                // body and subject only while still PENDING
                                messageBloc.add(OutreachMessageUpdateStatus(
                                  messageId: widget.message.messageId!,
                                  status: _selectedStatus,
                                  messageContent: _isEditable
                                      ? _messageContentController.text
                                      : null,
                                  emailSubject: _isEditable
                                      ? _emailSubjectController.text
                                      : null,
                                ));
                              }
                            }
                          },
                          child: Text(isNewMessage ? 'Create' : 'Update'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
