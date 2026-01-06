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

import '../bloc/outreach_campaign_bloc.dart';
import '../models/platform_settings.dart';

/// Formats backend status for display
/// 'MKTG_CAMP_PLANNED' -> 'Planned'
String _formatStatus(String status) {
  final cleaned = status.replaceFirst('MKTG_CAMP_', '');
  if (cleaned.isEmpty) return status;
  return cleaned[0].toUpperCase() + cleaned.substring(1).toLowerCase();
}

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
    'MKTG_CAMP_PLANNED',
    'MKTG_CAMP_APPROVED',
    'MKTG_CAMP_INPROGRESS',
    'MKTG_CAMP_COMPLETED',
    'MKTG_CAMP_FAILED',
    'MKTG_CAMP_CANCELLED',
  ];
  late String _selectedStatus;

  // Platform settings for storing action types
  late PlatformSettings _platformSettings;

  /// Get default action type for a platform
  String _getDefaultAction(String platform) {
    switch (platform.toUpperCase()) {
      case 'EMAIL':
        return 'send_email';
      case 'LINKEDIN':
        return 'message_connections';
      case 'TWITTER':
        return 'post_tweet';
      case 'SUBSTACK':
        return 'post_note';
      case 'MEDIUM':
        return 'post_article';
      case 'FACEBOOK':
        return 'post_update';
      default:
        return 'send_message';
    }
  }

  late OutreachCampaignBloc _campaignBloc;

  @override
  void initState() {
    super.initState();
    _campaignBloc = context.read<OutreachCampaignBloc>();

    _pseudoIdController =
        TextEditingController(text: widget.campaign.pseudoId ?? '');
    _nameController = TextEditingController(text: widget.campaign.name);
    _selectedStatus = widget.campaign.status.isNotEmpty
        ? widget.campaign.status
        : 'MKTG_CAMP_PLANNED';
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

    // Parse existing platform settings
    _platformSettings =
        PlatformSettings.fromJson(widget.campaign.platformSettings);
  }

  @override
  void dispose() {
    _pseudoIdController.dispose();
    _nameController.dispose();
    _targetAudienceController.dispose();
    _messageTemplateController.dispose();
    _emailSubjectController.dispose();
    _dailyLimitController.dispose();
    super.dispose();
  }

  /// Show platform configuration dialog for editing platform-specific settings
  Future<void> _showPlatformConfigDialog() async {
    final restClient =
        RepositoryProvider.of<RestClient>(context, listen: false);
    final result = await showDialog<PlatformSettings>(
      barrierDismissible: true,
      context: context,
      builder: (dialogContext) => _PlatformConfigDialog(
        platforms: _selectedPlatforms.toList(),
        settings: _platformSettings,
        campaignTemplate: _messageTemplateController.text,
        restClient: restClient,
      ),
    );
    if (result != null) {
      setState(() {
        _platformSettings = result;
      });
    }
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
        height: isPhone ? 700 : 600,
        child: ScaffoldMessenger(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: BlocListener<OutreachCampaignBloc, OutreachCampaignState>(
              listenWhen: (previous, current) =>
                  previous.status == OutreachCampaignStatus.loading &&
                  (current.status == OutreachCampaignStatus.success ||
                      current.status == OutreachCampaignStatus.failure),
              listener: (context, state) {
                if (state.status == OutreachCampaignStatus.success) {
                  Navigator.of(context).pop();
                }
                if (state.status == OutreachCampaignStatus.failure) {
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
                              decoration:
                                  const InputDecoration(labelText: 'Status'),
                              initialValue: _selectedStatus,
                              items: _statusOptions.map((status) {
                                return DropdownMenuItem<String>(
                                  value: status,
                                  child: Text(_formatStatus(status)),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  _selectedStatus =
                                      newValue ?? 'MKTG_CAMP_PLANNED';
                                });
                              },
                              isExpanded: true,
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Active status indicator
                          if (widget.campaign.campaignId != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: widget.campaign.isActive == 'Y'
                                    ? Colors.green.withValues(alpha: 0.2)
                                    : Colors.grey.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: widget.campaign.isActive == 'Y'
                                      ? Colors.green
                                      : Colors.grey,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    widget.campaign.isActive == 'Y'
                                        ? Icons.play_circle
                                        : Icons.pause_circle,
                                    size: 16,
                                    color: widget.campaign.isActive == 'Y'
                                        ? Colors.green
                                        : Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    widget.campaign.isActive == 'Y'
                                        ? 'Active'
                                        : 'Paused',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: widget.campaign.isActive == 'Y'
                                          ? Colors.green
                                          : Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
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
                      Row(
                        children: [
                          Text('Platforms',
                              style: Theme.of(context).textTheme.titleMedium),
                          const Spacer(),
                          ElevatedButton.icon(
                            key: const Key('configure'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _selectedPlatforms.isNotEmpty
                                  ? Colors.green
                                  : Colors.grey,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: _selectedPlatforms.isNotEmpty
                                ? () => _showPlatformConfigDialog()
                                : null,
                            icon: const Icon(Icons.settings, size: 18),
                            label: const Text('Configure'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
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
                                  // Initialize default action for this platform
                                  if (_platformSettings
                                          .getForPlatform(platform) ==
                                      null) {
                                    _platformSettings =
                                        _platformSettings.updatePlatform(
                                      platform.toLowerCase(),
                                      PlatformConfig(
                                        actionType: _getDefaultAction(platform),
                                      ),
                                    );
                                  }
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
                        decoration:
                            const InputDecoration(labelText: 'Target Audience'),
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
                        decoration:
                            const InputDecoration(labelText: 'Email Subject'),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
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
                      const SizedBox(height: 30),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              key: const Key('cancel'),
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              key: const Key('update'),
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  final platforms =
                                      _selectedPlatforms.toList().toString();
                                  if (widget.campaign.campaignId == null) {
                                    _campaignBloc.add(OutreachCampaignCreate(
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
                                      platformSettings:
                                          _platformSettings.toJson(),
                                    ));
                                  } else {
                                    _campaignBloc.add(OutreachCampaignUpdate(
                                      campaignId: widget.campaign.campaignId!,
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
                                      platformSettings:
                                          _platformSettings.toJson(),
                                    ));
                                  }
                                }
                              },
                              child: Text(widget.campaign.campaignId == null
                                  ? 'Create'
                                  : 'Update'),
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
        ),
      ),
    );
  }
}

/// Dialog for configuring platform-specific settings
class _PlatformConfigDialog extends StatefulWidget {
  final List<String> platforms;
  final PlatformSettings settings;
  final String campaignTemplate;
  final RestClient? restClient;

  const _PlatformConfigDialog({
    required this.platforms,
    required this.settings,
    required this.campaignTemplate,
    this.restClient,
  });

  @override
  State<_PlatformConfigDialog> createState() => _PlatformConfigDialogState();
}

class _PlatformConfigDialogState extends State<_PlatformConfigDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late PlatformSettings _settings;
  final Map<String, TextEditingController> _messageControllers = {};
  final Map<String, TextEditingController> _keywordsControllers = {};
  final Map<String, String> _selectedActions = {};
  final Map<String, List<Map<String, String>>> _messageLists = {};
  final Map<String, bool> _isGenerating = {};
  final Map<String, bool?> _loginStatus =
      {}; // null=unknown, true=logged in, false=not logged in
  final Map<String, bool> _isCheckingLogin = {};

  static const Map<String, String> _platformLoginUrls = {
    'TWITTER': 'https://twitter.com/login',
    'LINKEDIN': 'https://www.linkedin.com/login',
    'EMAIL': '', // Email uses SMTP, no browser login needed
    'SUBSTACK': 'https://substack.com/sign-in',
    'MEDIUM': 'https://medium.com/m/signin',
    'FACEBOOK': 'https://www.facebook.com/login',
  };

  static const Map<String, List<Map<String, String>>> _platformActions = {
    'EMAIL': [
      {'value': 'send_email', 'label': 'Send Email'},
    ],
    'LINKEDIN': [
      {'value': 'message_connections', 'label': 'Message Connections'},
      {'value': 'search_and_connect', 'label': 'Search & Connect'},
    ],
    'TWITTER': [
      {'value': 'post_tweet', 'label': 'Post Tweet'},
      {'value': 'follow_profiles', 'label': 'Follow Profiles'},
      {'value': 'send_dms', 'label': 'Send DMs'},
    ],
    'SUBSTACK': [
      {'value': 'post_note', 'label': 'Post Note'},
      {'value': 'subscribe', 'label': 'Subscribe'},
      {'value': 'comment', 'label': 'Comment'},
    ],
    'MEDIUM': [
      {'value': 'post_article', 'label': 'Post Article'},
    ],
    'FACEBOOK': [
      {'value': 'post_update', 'label': 'Post Update'},
    ],
  };

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: widget.platforms.length, vsync: this);
    _settings = widget.settings;

    // Initialize controllers for each platform
    for (final platform in widget.platforms) {
      final config = _settings.getForPlatform(platform);
      _messageControllers[platform] = TextEditingController(
        text: config?.messageTemplate ?? '',
      );
      _keywordsControllers[platform] = TextEditingController(
        text: config?.searchKeywords ?? '',
      );
      _selectedActions[platform] = config?.actionType ??
          (_platformActions[platform.toUpperCase()]?.first['value'] ??
              'send_message');
      _messageLists[platform] = List<Map<String, String>>.from(
        config?.messageList ?? [],
      );
      _isGenerating[platform] = false;
      _loginStatus[platform] = null; // Unknown
      _isCheckingLogin[platform] = false;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (final controller in _messageControllers.values) {
      controller.dispose();
    }
    for (final controller in _keywordsControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _saveAndClose() {
    // Build updated settings
    var updatedSettings = _settings;
    for (final platform in widget.platforms) {
      updatedSettings = updatedSettings.updatePlatform(
        platform.toLowerCase(),
        PlatformConfig(
          actionType: _selectedActions[platform],
          messageTemplate: _messageControllers[platform]?.text,
          searchKeywords: _keywordsControllers[platform]?.text,
          messageList: _messageLists[platform],
        ),
      );
    }
    Navigator.of(context).pop(updatedSettings);
  }

  Future<void> _generateWithAI(String platform) async {
    if (widget.restClient == null || widget.campaignTemplate.isEmpty) return;

    setState(() => _isGenerating[platform] = true);
    try {
      final result = await widget.restClient!.generatePlatformMessage(
        campaignTemplate: widget.campaignTemplate,
        platform: platform,
        actionType: _selectedActions[platform] ?? 'send_message',
      );
      if (result['platformMessage'] != null) {
        setState(() {
          _messageControllers[platform]?.text = result['platformMessage'] ?? '';
        });
      }
    } catch (e) {
      // Show error if needed
    } finally {
      setState(() => _isGenerating[platform] = false);
    }
  }

  void _openMessageListEditor(String platform) async {
    final result = await showDialog<List<Map<String, String>>>(
      context: context,
      builder: (ctx) => _MessageListEditor(
        messages: _messageLists[platform] ?? [],
      ),
    );
    if (result != null) {
      setState(() {
        _messageLists[platform] = result;
      });
    }
  }

  String _getLoginUrl(String platform) {
    return _platformLoginUrls[platform.toUpperCase()] ?? '';
  }

  Future<void> _launchLogin(String platform) async {
    final url = _getLoginUrl(platform);
    if (url.isEmpty) return;
    // Show a dialog prompting user to log in via browser
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Login to $platform'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Please log in to this platform in your browser:'),
            const SizedBox(height: 8),
            SelectableText(url, style: const TextStyle(color: Colors.blue)),
            const SizedBox(height: 16),
            const Text('After logging in, return here and click "Done".'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: popUp(
        context: context,
        title: 'Platform Configuration',
        width: 500,
        height: 500,
        child: Column(
          children: [
            TabBar(
              controller: _tabController,
              tabs: widget.platforms.map((p) => Tab(text: p)).toList(),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children:
                    widget.platforms.map((p) => _buildPlatformTab(p)).toList(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _saveAndClose,
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlatformTab(String platform) {
    final actions = _platformActions[platform.toUpperCase()] ?? [];
    final selectedAction = _selectedActions[platform] ?? '';

    // Determine which fields to show based on action
    final showMessage = _isMessageAction(selectedAction);
    final showKeywords = _isSearchAction(selectedAction);
    final showMessageList = _isDmAction(selectedAction);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Action dropdown
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Action',
            ),
            initialValue: _selectedActions[platform],
            items: actions.map((a) {
              return DropdownMenuItem<String>(
                value: a['value'],
                child: Text(a['label']!),
              );
            }).toList(),
            onChanged: (v) {
              setState(() => _selectedActions[platform] = v!);
            },
          ),
          const SizedBox(height: 20),

          // Login status indicator for browser-based platforms
          if (_getLoginUrl(platform).isNotEmpty) ...[
            Card(
              color: _loginStatus[platform] == true
                  ? Colors.green.shade50
                  : _loginStatus[platform] == false
                      ? Colors.orange.shade50
                      : Colors.grey.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(
                      _loginStatus[platform] == true
                          ? Icons.check_circle
                          : _loginStatus[platform] == false
                              ? Icons.warning
                              : Icons.help_outline,
                      color: _loginStatus[platform] == true
                          ? Colors.green
                          : _loginStatus[platform] == false
                              ? Colors.orange
                              : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _loginStatus[platform] == true
                            ? 'Ready to automate'
                            : 'Login required for browser automation',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _launchLogin(platform),
                      icon: const Icon(Icons.open_in_browser, size: 16),
                      label: Text(_loginStatus[platform] == true
                          ? 'Re-login'
                          : 'Login'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Conditional: Search keywords (for follow/search actions)
          if (showKeywords) ...[
            TextFormField(
              controller: _keywordsControllers[platform],
              decoration: const InputDecoration(
                labelText: 'Search Keywords',
                hintText: 'e.g., "Flutter Developer Thailand"',
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Conditional: Message template (for post/message actions)
          if (showMessage) ...[
            TextFormField(
              controller: _messageControllers[platform],
              decoration: InputDecoration(
                labelText: selectedAction == 'post_tweet'
                    ? 'Tweet Content'
                    : 'Message Template',
                hintText: widget.campaignTemplate.isNotEmpty
                    ? 'Leave empty to use campaign template'
                    : 'Enter your message',
                suffixIcon: widget.restClient != null &&
                        widget.campaignTemplate.isNotEmpty
                    ? IconButton(
                        onPressed: _isGenerating[platform] == true
                            ? null
                            : () => _generateWithAI(platform),
                        icon: _isGenerating[platform] == true
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.auto_awesome),
                        tooltip: 'Generate with AI',
                      )
                    : null,
              ),
              maxLines: 5,
            ),
            if (widget.campaignTemplate.isNotEmpty &&
                (_messageControllers[platform]?.text.isEmpty ?? true))
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Using campaign template',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.green,
                        fontStyle: FontStyle.italic,
                      ),
                ),
              ),
          ],

          if (showMessageList) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.list_alt, size: 20),
                        const SizedBox(width: 8),
                        Text(
                            'Message List (${_messageLists[platform]?.length ?? 0})',
                            style: Theme.of(context).textTheme.titleSmall),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () => _openMessageListEditor(platform),
                          icon: const Icon(Icons.edit, size: 16),
                          label: const Text('Edit'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if ((_messageLists[platform]?.isEmpty ?? true))
                      Text(
                        'Add recipients with personalized messages for DMs.',
                        style: Theme.of(context).textTheme.bodySmall,
                      )
                    else
                      Text(
                        '${_messageLists[platform]!.length} recipients configured',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.green,
                            ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  bool _isMessageAction(String action) {
    return [
      'post_tweet',
      'post_note',
      'post_article',
      'post_update',
      'message_connections',
      'send_email',
      'comment'
    ].contains(action);
  }

  bool _isSearchAction(String action) {
    return ['follow_profiles', 'search_and_connect', 'subscribe']
        .contains(action);
  }

  bool _isDmAction(String action) {
    return ['send_dms'].contains(action);
  }
}

/// Dialog for editing message list (recipients with personalized messages)
class _MessageListEditor extends StatefulWidget {
  final List<Map<String, String>> messages;

  const _MessageListEditor({required this.messages});

  @override
  State<_MessageListEditor> createState() => _MessageListEditorState();
}

class _MessageListEditorState extends State<_MessageListEditor> {
  late List<Map<String, String>> _messages;
  final _nameController = TextEditingController();
  final _handleController = TextEditingController();
  final _messageController = TextEditingController();
  int? _editingIndex;

  @override
  void initState() {
    super.initState();
    _messages = List<Map<String, String>>.from(widget.messages);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _handleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _addOrUpdateMessage() {
    if (_handleController.text.isEmpty) return;

    final newMessage = {
      'name': _nameController.text,
      'handle': _handleController.text,
      'message': _messageController.text,
    };

    setState(() {
      if (_editingIndex != null) {
        _messages[_editingIndex!] = newMessage;
        _editingIndex = null;
      } else {
        _messages.add(newMessage);
      }
      _nameController.clear();
      _handleController.clear();
      _messageController.clear();
    });
  }

  void _editMessage(int index) {
    setState(() {
      _editingIndex = index;
      _nameController.text = _messages[index]['name'] ?? '';
      _handleController.text = _messages[index]['handle'] ?? '';
      _messageController.text = _messages[index]['message'] ?? '';
    });
  }

  void _deleteMessage(int index) {
    setState(() {
      _messages.removeAt(index);
      if (_editingIndex == index) {
        _editingIndex = null;
        _nameController.clear();
        _handleController.clear();
        _messageController.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: popUp(
        context: context,
        title: 'Message List',
        width: 550,
        height: 550,
        child: Column(
          children: [
            // Input form
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Name',
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _handleController,
                            decoration: const InputDecoration(
                              labelText: 'Handle *',
                              hintText: '@username',
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        labelText: 'Message',
                        hintText: 'Personalized message (optional)',
                        isDense: true,
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _addOrUpdateMessage,
                      icon:
                          Icon(_editingIndex != null ? Icons.save : Icons.add),
                      label: Text(_editingIndex != null ? 'Update' : 'Add'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            // List of messages
            Expanded(
              child: _messages.isEmpty
                  ? Center(
                      child: Text(
                        'No recipients added yet',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey,
                            ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final msg = _messages[index];
                        return ListTile(
                          dense: true,
                          title: Text(
                            '${msg['name']?.isNotEmpty == true ? msg['name'] : 'No name'} (${msg['handle']})',
                          ),
                          subtitle: msg['message']?.isNotEmpty == true
                              ? Text(
                                  msg['message']!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                )
                              : null,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, size: 18),
                                onPressed: () => _editMessage(index),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 18),
                                onPressed: () => _deleteMessage(index),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${_messages.length} recipients'),
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(_messages),
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
