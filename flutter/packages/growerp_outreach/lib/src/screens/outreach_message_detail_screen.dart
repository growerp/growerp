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
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:intl/intl.dart';

import '../bloc/outreach_message_bloc.dart';
import '../bloc/outreach_message_event.dart';
import '../bloc/outreach_message_state.dart';
import '../bloc/outreach_campaign_bloc.dart';

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
  late TextEditingController _campaignIdController;

  final List<String> _availablePlatforms = [
    'EMAIL',
    'LINKEDIN',
    'TWITTER',
    'MEDIUM',
    'SUBSTACK',
    'FACEBOOK',
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
  List<OutreachCampaign> _availableCampaigns = [];
  bool _loadingCampaigns = false;

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
    _campaignIdController =
        TextEditingController(text: widget.message.campaignId ?? '');
    _selectedCampaignId = widget.message.campaignId;

    _selectedPlatform =
        widget.message.platform.isNotEmpty ? widget.message.platform : 'EMAIL';
    _selectedStatus =
        widget.message.status.isNotEmpty ? widget.message.status : 'PENDING';

    // Load available campaigns for dropdown
    _loadCampaigns();
  }

  Future<void> _loadCampaigns() async {
    setState(() => _loadingCampaigns = true);
    try {
      final bloc = context.read<OutreachCampaignBloc>();
      // Trigger fetch if not already loaded
      if (bloc.state.campaigns.isEmpty) {
        bloc.add(const OutreachCampaignFetch(start: 0));
      }
      // Wait a bit for the campaigns to load
      await Future.delayed(const Duration(milliseconds: 500));
      setState(() {
        _availableCampaigns = bloc.state.campaigns;
        _loadingCampaigns = false;
      });
    } catch (e) {
      setState(() => _loadingCampaigns = false);
    }
  }

  @override
  void dispose() {
    _recipientNameController.dispose();
    _recipientEmailController.dispose();
    _recipientProfileUrlController.dispose();
    _recipientHandleController.dispose();
    _messageContentController.dispose();
    _campaignIdController.dispose();
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
                        Expanded(
                          child: Autocomplete<OutreachCampaign>(
                            key: const Key('campaignId'),
                            initialValue: _selectedCampaignId != null
                                ? TextEditingValue(
                                    text: _availableCampaigns
                                        .firstWhere(
                                          (c) =>
                                              c.campaignId ==
                                              _selectedCampaignId,
                                          orElse: () => const OutreachCampaign(
                                            name: '',
                                            platforms: '',
                                            status: '',
                                          ),
                                        )
                                        .name)
                                : TextEditingValue.empty,
                            optionsBuilder:
                                (TextEditingValue textEditingValue) {
                              if (textEditingValue.text.isEmpty) {
                                return _availableCampaigns;
                              }
                              return _availableCampaigns.where((campaign) {
                                return campaign.name.toLowerCase().contains(
                                        textEditingValue.text.toLowerCase()) ||
                                    (campaign.pseudoId ?? '')
                                        .toLowerCase()
                                        .contains(textEditingValue.text
                                            .toLowerCase());
                              });
                            },
                            displayStringForOption:
                                (OutreachCampaign campaign) =>
                                    '${campaign.name} (${campaign.pseudoId})',
                            fieldViewBuilder: (context, controller, focusNode,
                                onEditingComplete) {
                              return TextFormField(
                                controller: controller,
                                focusNode: focusNode,
                                decoration: InputDecoration(
                                  labelText: 'Campaign *',
                                  helperText: 'Type to search campaigns',
                                  suffixIcon: _loadingCampaigns
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: Center(
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2),
                                          ),
                                        )
                                      : const Icon(Icons.search),
                                ),
                                validator: (value) {
                                  if (_selectedCampaignId == null ||
                                      _selectedCampaignId!.isEmpty) {
                                    return 'Please select a campaign';
                                  }
                                  return null;
                                },
                              );
                            },
                            onSelected: (OutreachCampaign campaign) {
                              setState(() {
                                _selectedCampaignId = campaign.campaignId;
                                _campaignIdController.text =
                                    campaign.campaignId ?? '';
                              });
                            },
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

                  // For mobile: Campaign ID separate
                  if (isPhone && isNewMessage)
                    Autocomplete<OutreachCampaign>(
                      key: const Key('campaignId'),
                      initialValue: _selectedCampaignId != null
                          ? TextEditingValue(
                              text: _availableCampaigns
                                  .firstWhere(
                                    (c) => c.campaignId == _selectedCampaignId,
                                    orElse: () => const OutreachCampaign(
                                      name: '',
                                      platforms: '',
                                      status: '',
                                    ),
                                  )
                                  .name)
                          : TextEditingValue.empty,
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        if (textEditingValue.text.isEmpty) {
                          return _availableCampaigns;
                        }
                        return _availableCampaigns.where((campaign) {
                          return campaign.name.toLowerCase().contains(
                                  textEditingValue.text.toLowerCase()) ||
                              (campaign.pseudoId ?? '').toLowerCase().contains(
                                  textEditingValue.text.toLowerCase());
                        });
                      },
                      displayStringForOption: (OutreachCampaign campaign) =>
                          '${campaign.name} (${campaign.pseudoId})',
                      fieldViewBuilder:
                          (context, controller, focusNode, onEditingComplete) {
                        return TextFormField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: InputDecoration(
                            labelText: 'Campaign *',
                            helperText: 'Type to search campaigns',
                            suffixIcon: _loadingCampaigns
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: Center(
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    ),
                                  )
                                : const Icon(Icons.search),
                          ),
                          validator: (value) {
                            if (_selectedCampaignId == null ||
                                _selectedCampaignId!.isEmpty) {
                              return 'Please select a campaign';
                            }
                            return null;
                          },
                        );
                      },
                      onSelected: (OutreachCampaign campaign) {
                        setState(() {
                          _selectedCampaignId = campaign.campaignId;
                          _campaignIdController.text =
                              campaign.campaignId ?? '';
                        });
                      },
                    ),
                  if (isNewMessage) const SizedBox(height: 20),

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

                  // Message Content
                  TextFormField(
                    key: const Key('messageContent'),
                    controller: _messageContentController,
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
                        'Sent: ${DateFormat('MMM dd, yyyy HH:mm').format(widget.message.sentDate!)}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    if (widget.message.responseDate != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Response: ${DateFormat('MMM dd, yyyy HH:mm').format(widget.message.responseDate!)}',
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
                      Expanded(
                        child: ElevatedButton(
                          key: const Key('saveMessage'),
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              if (isNewMessage) {
                                // Create new message
                                messageBloc.add(OutreachMessageCreate(
                                  campaignId: _campaignIdController.text.isEmpty
                                      ? null
                                      : _campaignIdController.text,
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
                                ));
                              } else {
                                // Update status
                                messageBloc.add(OutreachMessageUpdateStatus(
                                  messageId: widget.message.messageId!,
                                  status: _selectedStatus,
                                ));
                              }
                            }
                          },
                          child:
                              Text(isNewMessage ? 'Create' : 'Update Status'),
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
