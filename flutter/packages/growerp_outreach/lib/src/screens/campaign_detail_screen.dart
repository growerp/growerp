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

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../bloc/outreach_campaign_bloc.dart';

class CampaignDetailScreen extends StatefulWidget {
  final OutreachCampaign campaign;

  const CampaignDetailScreen({
    super.key,
    required this.campaign,
  });

  @override
  CampaignDetailScreenState createState() => CampaignDetailScreenState();
}

class CampaignDetailScreenState extends State<CampaignDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _pseudoIdController;
  late TextEditingController _nameController;
  late TextEditingController _targetAudienceController;
  late TextEditingController _messageTemplateController;
  late TextEditingController _emailSubjectController;
  late TextEditingController _dailyLimitController;

  final Set<String> _selectedPlatforms = {};
  final List<String> _availablePlatforms = [
    'EMAIL',
    'LINKEDIN',
    'TWITTER',
    'MEDIUM',
    'SUBSTACK',
    'FACEBOOK',
  ];
  final List<String> _statusOptions = [
    'DRAFT',
    'ACTIVE',
    'PAUSED',
    'COMPLETED'
  ];
  late String _selectedStatus;

  late OutreachCampaignBloc _campaignBloc;

  @override
  void initState() {
    super.initState();
    _campaignBloc = context.read<OutreachCampaignBloc>();

    _pseudoIdController =
        TextEditingController(text: widget.campaign.pseudoId ?? '');
    _nameController = TextEditingController(text: widget.campaign.name);
    _selectedStatus =
        widget.campaign.status.isNotEmpty ? widget.campaign.status : 'DRAFT';
    _targetAudienceController = TextEditingController(
      text: widget.campaign.targetAudience,
    );
    _messageTemplateController = TextEditingController(
      text: widget.campaign.messageTemplate,
    );
    _emailSubjectController = TextEditingController(
      text: widget.campaign.emailSubject,
    );
    _dailyLimitController = TextEditingController(
      text: widget.campaign.dailyLimitPerPlatform.toString(),
    );

    // Parse existing platforms
    try {
      final platforms = widget.campaign.platforms
          .replaceAll('[', '')
          .replaceAll(']', '')
          .replaceAll('"', '')
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty);
      _selectedPlatforms.addAll(platforms);
    } catch (e) {
      // Ignore parsing errors
    }
  }

  Timer? _pollingTimer;

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (widget.campaign.campaignId != null) {
        _campaignBloc.add(OutreachCampaignDetailFetch(
          campaignId: widget.campaign.campaignId!,
        ));
      }
    });
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  @override
  void dispose() {
    _stopPolling();
    _pseudoIdController.dispose();
    _nameController.dispose();
    _targetAudienceController.dispose();
    _messageTemplateController.dispose();
    _emailSubjectController.dispose();
    _dailyLimitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPhone = ResponsiveBreakpoints.of(context).isMobile;
    return Dialog(
      key: Key('CampaignDetail${widget.campaign.pseudoId}'),
      insetPadding: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: popUp(
        context: context,
        title: widget.campaign.campaignId == null
            ? 'New Campaign'
            : 'Campaign #${widget.campaign.pseudoId}',
        width: isPhone ? 400 : 900,
        height: isPhone ? 700 : 700,
        child: ScaffoldMessenger(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: BlocListener<OutreachCampaignBloc, OutreachCampaignState>(
              listener: (context, state) {
                if (state.status == OutreachCampaignStatus.success) {
                  // Update local state if campaign updated
                  if (state.selectedCampaign != null) {
                    setState(() {
                      _selectedStatus = state.selectedCampaign!.status;
                    });

                    // Manage polling based on status
                    if (state.selectedCampaign!.status == 'ACTIVE') {
                      _startPolling();
                    } else {
                      _stopPolling();
                    }
                  } else if (state.message != null &&
                      state.message!.isNotEmpty) {
                    // If success message (create/update/delete), pop
                    Navigator.of(context).pop();
                  }
                }
                if (state.status == OutreachCampaignStatus.failure) {
                  HelperFunctions.showMessage(
                    context,
                    state.message ?? 'An error occurred',
                    Colors.red,
                  );
                }
              },
              child: BlocBuilder<OutreachCampaignBloc, OutreachCampaignState>(
                builder: (context, state) {
                  // Use campaign from state if available (for live updates), else widget
                  final campaign = state.selectedCampaign != null &&
                          state.selectedCampaign!.campaignId ==
                              widget.campaign.campaignId
                      ? state.selectedCampaign!
                      : widget.campaign;

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  key: const Key('id'),
                                  controller: _pseudoIdController,
                                  decoration:
                                      const InputDecoration(labelText: 'ID'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  key: const Key('status'),
                                  decoration: const InputDecoration(
                                      labelText: 'Status'),
                                  initialValue: _selectedStatus,
                                  items: _statusOptions.map((status) {
                                    return DropdownMenuItem<String>(
                                      value: status,
                                      child: Text(status),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      _selectedStatus = newValue ?? 'DRAFT';
                                    });
                                  },
                                  isExpanded: true,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextFormField(
                                  key: const Key('dailyLimit'),
                                  controller: _dailyLimitController,
                                  decoration: const InputDecoration(
                                      labelText: 'Daily Limit per Platform'),
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value != null && value.isNotEmpty) {
                                      if (int.tryParse(value) == null) {
                                        return 'Please enter a valid number';
                                      }
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          if (campaign.campaignId != null && isPhone)
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  _buildMetricCard(
                                      'Sent', campaign.messagesSent),
                                  const SizedBox(width: 10),
                                  _buildMetricCard(
                                      'Responses', campaign.responsesReceived),
                                  const SizedBox(width: 10),
                                  _buildMetricCard(
                                      'Leads', campaign.leadsGenerated),
                                  // Add more metrics if available in state.metrics
                                  if (state.metrics != null) ...[
                                    const SizedBox(width: 10),
                                    _buildMetricCard('Pending',
                                        state.metrics!.messagesPending),
                                    const SizedBox(width: 10),
                                    _buildMetricCard(
                                        'Failed', state.metrics!.messagesFailed,
                                        color: Colors.red),
                                  ]
                                ],
                              ),
                            ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  key: const Key('name'),
                                  controller: _nameController,
                                  decoration: const InputDecoration(
                                      labelText: 'Campaign Name *'),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter a name';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Text('Platforms',
                              style: Theme.of(context).textTheme.titleMedium),
                          Wrap(
                            spacing: 8.0,
                            children: _availablePlatforms.map((platform) {
                              return FilterChip(
                                label: Text(platform),
                                selected: _selectedPlatforms.contains(platform),
                                onSelected: (bool selected) {
                                  setState(() {
                                    if (selected) {
                                      _selectedPlatforms.add(platform);
                                    } else {
                                      _selectedPlatforms.remove(platform);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            key: const Key('targetAudience'),
                            controller: _targetAudienceController,
                            decoration: const InputDecoration(
                                labelText: 'Target Audience'),
                            maxLines: 3,
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            key: const Key('messageTemplate'),
                            controller: _messageTemplateController,
                            decoration: const InputDecoration(
                                labelText: 'Message Template'),
                            maxLines: 5,
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            key: const Key('emailSubject'),
                            controller: _emailSubjectController,
                            decoration: const InputDecoration(
                                labelText: 'Email Subject'),
                          ),
                          const SizedBox(height: 30),
                          Row(
                            children: [
                              if (campaign.campaignId != null) ...[
                                Expanded(
                                  child: ElevatedButton.icon(
                                    key: const Key('automationButton'),
                                    icon: Icon(_selectedStatus == 'ACTIVE'
                                        ? Icons.pause
                                        : Icons.play_arrow),
                                    label: Text(_selectedStatus == 'ACTIVE'
                                        ? 'Pause Automation'
                                        : 'Start Automation'),
                                    style: ElevatedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      backgroundColor:
                                          _selectedStatus == 'ACTIVE'
                                              ? Colors.orange
                                              : Colors.green,
                                    ),
                                    onPressed: () {
                                      if (_selectedStatus == 'ACTIVE') {
                                        _campaignBloc.add(OutreachCampaignPause(
                                            campaign.campaignId!));
                                      } else {
                                        _campaignBloc.add(OutreachCampaignStart(
                                            campaign.campaignId!));
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),
                              ],
                              Expanded(
                                child: ElevatedButton(
                                  key: const Key('saveCampaign'),
                                  onPressed: () {
                                    if (_formKey.currentState!.validate()) {
                                      final platforms = _selectedPlatforms
                                          .toList()
                                          .toString();
                                      if (campaign.campaignId == null) {
                                        _campaignBloc
                                            .add(OutreachCampaignCreate(
                                          name: _nameController.text,
                                          platforms: platforms,
                                          targetAudience:
                                              _targetAudienceController.text,
                                          messageTemplate:
                                              _messageTemplateController.text,
                                          emailSubject:
                                              _emailSubjectController.text,
                                          dailyLimitPerPlatform: int.tryParse(
                                                  _dailyLimitController.text) ??
                                              50,
                                        ));
                                      } else {
                                        _campaignBloc
                                            .add(OutreachCampaignUpdate(
                                          campaignId: campaign.campaignId!,
                                          pseudoId: _pseudoIdController.text,
                                          name: _nameController.text,
                                          status: _selectedStatus,
                                          platforms: platforms,
                                          targetAudience:
                                              _targetAudienceController.text,
                                          messageTemplate:
                                              _messageTemplateController.text,
                                          emailSubject:
                                              _emailSubjectController.text,
                                          dailyLimitPerPlatform: int.tryParse(
                                                  _dailyLimitController.text) ??
                                              50,
                                        ));
                                      }
                                    }
                                  },
                                  child: Text(campaign.campaignId == null
                                      ? 'Create'
                                      : 'Update'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard(String label, int value, {Color? color}) {
    return Card(
      color: color?.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            Text(
              value.toString(),
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(color: color),
            ),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
