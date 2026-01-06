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
import '../services/adapters/linkedin_automation_adapter.dart';
import '../services/adapters/x_automation_adapter.dart';
import '../services/adapters/substack_automation_adapter.dart';
import '../services/adapters/email_automation_adapter.dart';
import '../services/platform_automation_adapter.dart';

/// Dialog for executing campaign actions on specific platforms
///
/// Shows tabs for each platform the campaign targets:
/// - LinkedIn: Connection search, 1st-level messaging, connection requests
/// - Twitter/X: Profile search, follow, tweet/DM
/// - Substack: Search publications, subscribe, post notes
/// - Email: Send email campaigns
class CampaignExecutionDialog extends StatefulWidget {
  final OutreachCampaign campaign;

  const CampaignExecutionDialog({
    super.key,
    required this.campaign,
  });

  @override
  State<CampaignExecutionDialog> createState() =>
      _CampaignExecutionDialogState();
}

class _CampaignExecutionDialogState extends State<CampaignExecutionDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late List<String> _platforms;
  late PlatformSettings _platformSettings;

  @override
  void initState() {
    super.initState();
    _platforms = _parsePlatforms(widget.campaign.platforms);
    _tabController = TabController(length: _platforms.length, vsync: this);
    _platformSettings =
        PlatformSettings.fromJson(widget.campaign.platformSettings);
  }

  /// Auto-save platform settings when they change
  void _savePlatformSettings(String platform, PlatformConfig config) {
    _platformSettings = _platformSettings.updatePlatform(platform, config);
    final campaignId = widget.campaign.campaignId;
    if (campaignId != null) {
      context.read<OutreachCampaignBloc>().add(
            OutreachCampaignUpdate(
              campaignId: campaignId,
              platformSettings: _platformSettings.toJson(),
            ),
          );
    }
  }

  /// Get current settings for a platform
  PlatformConfig? _getSettingsForPlatform(String platform) {
    return _platformSettings.getForPlatform(platform);
  }

  List<String> _parsePlatforms(String platformsStr) {
    try {
      return platformsStr
          .replaceAll('[', '')
          .replaceAll(']', '')
          .replaceAll('"', '')
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  IconData _getPlatformIcon(String platform) {
    switch (platform.toUpperCase()) {
      case 'LINKEDIN':
        return Icons.business;
      case 'TWITTER':
        return Icons.flutter_dash;
      case 'SUBSTACK':
        return Icons.article;
      case 'EMAIL':
        return Icons.email;
      case 'FACEBOOK':
        return Icons.facebook;
      case 'MEDIUM':
        return Icons.edit_note;
      default:
        return Icons.public;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPhone = ResponsiveBreakpoints.of(context).isMobile;

    if (_platforms.isEmpty) {
      return Dialog(
        child: popUp(
          context: context,
          title: 'Execute Campaign',
          width: 400,
          height: 200,
          child: const Center(
            child: Text('No platforms configured for this campaign'),
          ),
        ),
      );
    }

    return Dialog(
      key: Key('CampaignExecution${widget.campaign.pseudoId}'),
      insetPadding: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: popUp(
        context: context,
        title: 'Execute: ${widget.campaign.name}',
        width: isPhone ? 400 : 700,
        height: isPhone ? 600 : 550,
        child: Column(
          children: [
            TabBar(
              controller: _tabController,
              isScrollable: _platforms.length > 3,
              tabs: _platforms.map((platform) {
                return Tab(
                  icon: Icon(_getPlatformIcon(platform)),
                  text: _formatPlatformName(platform),
                );
              }).toList(),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: _platforms.map((platform) {
                  return _buildPlatformTab(platform);
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatPlatformName(String platform) {
    switch (platform.toUpperCase()) {
      case 'TWITTER':
        return 'X (Twitter)';
      case 'LINKEDIN':
        return 'LinkedIn';
      case 'SUBSTACK':
        return 'Substack';
      case 'EMAIL':
        return 'Email';
      case 'FACEBOOK':
        return 'Facebook';
      case 'MEDIUM':
        return 'Medium';
      default:
        return platform;
    }
  }

  Widget _buildPlatformTab(String platform) {
    final settings = _getSettingsForPlatform(platform);
    switch (platform.toUpperCase()) {
      case 'LINKEDIN':
        return _LinkedInTab(
          campaign: widget.campaign,
          settings: settings,
          onSettingsChanged: (config) =>
              _savePlatformSettings('linkedin', config),
        );
      case 'TWITTER':
        return _TwitterTab(
          campaign: widget.campaign,
          settings: settings,
          onSettingsChanged: (config) =>
              _savePlatformSettings('twitter', config),
        );
      case 'SUBSTACK':
        return _SubstackTab(
          campaign: widget.campaign,
          settings: settings,
          onSettingsChanged: (config) =>
              _savePlatformSettings('substack', config),
        );
      case 'EMAIL':
        return _EmailTab(campaign: widget.campaign);
      default:
        return Center(
          child: Text('$platform automation not yet implemented'),
        );
    }
  }
}

/// LinkedIn platform tab with available actions
class _LinkedInTab extends StatefulWidget {
  final OutreachCampaign campaign;
  final PlatformConfig? settings;
  final void Function(PlatformConfig) onSettingsChanged;

  const _LinkedInTab({
    required this.campaign,
    this.settings,
    required this.onSettingsChanged,
  });

  @override
  State<_LinkedInTab> createState() => _LinkedInTabState();
}

class _LinkedInTabState extends State<_LinkedInTab> {
  final _searchController = TextEditingController();
  final _messageController = TextEditingController();
  final _maxConnectionsController = TextEditingController(text: '20');

  LinkedInAutomationAdapter? _adapter;
  List<ProfileData> _profiles = [];
  Set<int> _selectedIndices = {};
  List<MessageResult> _results = [];

  bool _isInitializing = false;
  bool _isLoggedIn = false;
  bool _isFetchingConnections = false;
  bool _isSearching = false;
  bool _isProcessing = false;
  String? _statusMessage;
  String? _errorMessage;

  // Action selection
  String _selectedAction = 'message_connections';

  @override
  void initState() {
    super.initState();
    // Load from platform settings if available, fallback to campaign template
    final settings = widget.settings;
    if (settings != null) {
      _selectedAction = settings.actionType ?? 'message_connections';
      _searchController.text = settings.searchKeywords ?? '';
      final platformTemplate = settings.messageTemplate;
      _messageController.text =
          (platformTemplate != null && platformTemplate.isNotEmpty)
              ? platformTemplate
              : (widget.campaign.messageTemplate ?? '');
    } else {
      _messageController.text = widget.campaign.messageTemplate ?? '';
    }
    // Load max connections from campaign daily limit
    _maxConnectionsController.text =
        widget.campaign.dailyLimitPerPlatform.toString();
  }

  /// Save current settings
  void _saveSettings() {
    widget.onSettingsChanged(PlatformConfig(
      actionType: _selectedAction,
      searchKeywords: _searchController.text,
      messageTemplate: _messageController.text,
    ));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _messageController.dispose();
    _maxConnectionsController.dispose();
    _adapter?.cleanup();
    super.dispose();
  }

  Future<void> _initializeAdapter() async {
    setState(() {
      _isInitializing = true;
      _errorMessage = null;
      _statusMessage = 'Initializing browser...';
    });

    try {
      _adapter = LinkedInAutomationAdapter();
      await _adapter!.initialize();

      final loggedIn = await _adapter!.isLoggedIn();
      setState(() {
        _isLoggedIn = loggedIn;
        _isInitializing = false;
        _statusMessage =
            loggedIn ? 'Connected to LinkedIn' : 'Please login to LinkedIn';
      });
    } catch (e) {
      setState(() {
        _isInitializing = false;
        _errorMessage = 'Failed to initialize: $e';
        _statusMessage = null;
      });
    }
  }

  Future<void> _fetchConnections() async {
    if (_adapter == null) return;

    setState(() {
      _isFetchingConnections = true;
      _errorMessage = null;
      _statusMessage = 'Fetching connections...';
      _profiles = [];
      _selectedIndices = {};
    });

    try {
      final maxResults = int.tryParse(_maxConnectionsController.text) ?? 20;
      final connections = await _adapter!.getFirstLevelConnections(
        maxResults: maxResults,
        scrollCount: (maxResults / 10).ceil(),
      );

      setState(() {
        _profiles = connections;
        _isFetchingConnections = false;
        _statusMessage = 'Found ${connections.length} connections';
      });
    } catch (e) {
      setState(() {
        _isFetchingConnections = false;
        _errorMessage = 'Failed to fetch connections: $e';
        _statusMessage = null;
      });
    }
  }

  Future<void> _searchProfiles() async {
    if (_adapter == null || _searchController.text.isEmpty) return;

    setState(() {
      _isSearching = true;
      _errorMessage = null;
      _statusMessage = 'Searching profiles...';
      _profiles = [];
      _selectedIndices = {};
    });

    try {
      final profiles = await _adapter!.searchProfiles(_searchController.text);
      setState(() {
        _profiles = profiles;
        _isSearching = false;
        _statusMessage = 'Found ${profiles.length} profiles';
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
        _errorMessage = 'Failed to search: $e';
        _statusMessage = null;
      });
    }
  }

  Future<void> _executeAction() async {
    if (_adapter == null || _selectedIndices.isEmpty) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
      _results = [];
    });

    try {
      final selectedProfiles =
          _selectedIndices.map((i) => _profiles[i]).toList();

      if (_selectedAction == 'message_connections') {
        _results = await _adapter!.sendBatchMessages(
          connections: selectedProfiles,
          messageTemplate: _messageController.text,
        );
        setState(() {
          _statusMessage =
              'Sent ${_results.where((r) => r.success).length}/${_results.length} messages';
        });
      } else if (_selectedAction == 'send_connection_requests') {
        for (final profile in selectedProfiles) {
          try {
            await _adapter!.sendConnectionRequest(
              profile,
              _messageController.text,
            );
            _results.add(MessageResult(
              profile: profile,
              success: true,
              timestamp: DateTime.now(),
            ));
          } catch (e) {
            _results.add(MessageResult(
              profile: profile,
              success: false,
              error: e.toString(),
              timestamp: DateTime.now(),
            ));
          }
        }
        setState(() {
          _statusMessage =
              'Sent ${_results.where((r) => r.success).length}/${_results.length} connection requests';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Action selection
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Action', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedAction,
                    items: const [
                      DropdownMenuItem(
                        value: 'message_connections',
                        child: Text('Message 1st-Level Connections'),
                      ),
                      DropdownMenuItem(
                        value: 'search_and_connect',
                        child: Text('Search & Send Connection Requests'),
                      ),
                      DropdownMenuItem(
                        value: 'send_connection_requests',
                        child: Text('Send Connection Requests'),
                      ),
                    ],
                    onChanged: (v) {
                      setState(() => _selectedAction = v!);
                      _saveSettings();
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Initialize button
          if (_adapter == null)
            ElevatedButton.icon(
              onPressed: _isInitializing ? null : _initializeAdapter,
              icon: _isInitializing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.play_arrow),
              label: Text(_isInitializing ? 'Starting...' : 'Start Browser'),
            ),

          // Status/Error messages
          if (_statusMessage != null || _errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                _errorMessage ?? _statusMessage ?? '',
                style: TextStyle(
                  color: _errorMessage != null ? Colors.red : Colors.green,
                ),
              ),
            ),

          const SizedBox(height: 12),

          // Message template (always visible)
          TextField(
            controller: _messageController,
            decoration: InputDecoration(
              labelText: 'Message Template',
              hintText: widget.campaign.messageTemplate?.isNotEmpty == true
                  ? 'Campaign: ${widget.campaign.messageTemplate}'
                  : 'Use {name} for personalization',
            ),
            maxLines: 3,
            onChanged: (_) => _saveSettings(),
          ),
          if (_messageController.text.isEmpty &&
              widget.campaign.messageTemplate?.isNotEmpty == true)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    _messageController.text =
                        widget.campaign.messageTemplate ?? '';
                  });
                  _saveSettings();
                },
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('Use Campaign Template'),
              ),
            ),

          // Action-specific controls (require login)
          if (_isLoggedIn) ...[
            const SizedBox(height: 12),

            if (_selectedAction == 'message_connections') ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _maxConnectionsController,
                      decoration: const InputDecoration(
                        labelText: 'Max Connections',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed:
                        _isFetchingConnections ? null : _fetchConnections,
                    child: Text(_isFetchingConnections
                        ? 'Loading...'
                        : 'Fetch Connections'),
                  ),
                ],
              ),
            ],

            if (_selectedAction == 'search_and_connect') ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        labelText:
                            'Search Keywords (e.g., "Flutter Developer")',
                      ),
                      onChanged: (_) => _saveSettings(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isSearching ? null : _searchProfiles,
                    child: Text(_isSearching ? 'Searching...' : 'Search'),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 12),

            // Profiles list
            if (_profiles.isNotEmpty) ...[
              Text(
                'Select recipients (${_selectedIndices.length}/${_profiles.length})',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              Row(
                children: [
                  TextButton(
                    onPressed: () => setState(
                      () => _selectedIndices =
                          Set.from(List.generate(_profiles.length, (i) => i)),
                    ),
                    child: const Text('Select All'),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _selectedIndices = {}),
                    child: const Text('Clear'),
                  ),
                ],
              ),
              SizedBox(
                height: 150,
                child: ListView.builder(
                  itemCount: _profiles.length,
                  itemBuilder: (context, index) {
                    final profile = _profiles[index];
                    return CheckboxListTile(
                      value: _selectedIndices.contains(index),
                      onChanged: (selected) {
                        setState(() {
                          if (selected == true) {
                            _selectedIndices.add(index);
                          } else {
                            _selectedIndices.remove(index);
                          }
                        });
                      },
                      title: Text(profile.name),
                      subtitle: Text(profile.title ?? profile.handle ?? ''),
                      dense: true,
                    );
                  },
                ),
              ),
            ],

            // Execute button
            if (_profiles.isNotEmpty && _selectedIndices.isNotEmpty) ...[
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _isProcessing ? null : _executeAction,
                icon: _isProcessing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                label: Text(_isProcessing
                    ? 'Processing...'
                    : 'Execute (${_selectedIndices.length} selected)'),
              ),
            ],

            // Results
            if (_results.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Results',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
                    final result = _results[index];
                    return ListTile(
                      leading: Icon(
                        result.success ? Icons.check_circle : Icons.error,
                        color: result.success ? Colors.green : Colors.red,
                        size: 20,
                      ),
                      title: Text(result.profile.name),
                      subtitle: result.error != null
                          ? Text(result.error!,
                              style: const TextStyle(color: Colors.red))
                          : null,
                      dense: true,
                    );
                  },
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

/// Twitter/X platform tab with available actions
class _TwitterTab extends StatefulWidget {
  final OutreachCampaign campaign;
  final PlatformConfig? settings;
  final void Function(PlatformConfig) onSettingsChanged;

  const _TwitterTab({
    required this.campaign,
    this.settings,
    required this.onSettingsChanged,
  });

  @override
  State<_TwitterTab> createState() => _TwitterTabState();
}

class _TwitterTabState extends State<_TwitterTab> {
  final _searchController = TextEditingController();
  final _messageController = TextEditingController();

  XAutomationAdapter? _adapter;
  List<ProfileData> _profiles = [];
  Set<int> _selectedIndices = {};

  bool _isInitializing = false;
  bool _isLoggedIn = false;
  bool _isSearching = false;
  bool _isProcessing = false;
  String? _statusMessage;
  String? _errorMessage;

  String _selectedAction = 'post_tweet';

  @override
  void initState() {
    super.initState();
    // Load from platform settings if available, fallback to campaign template
    final settings = widget.settings;
    if (settings != null) {
      _selectedAction = settings.actionType ?? 'post_tweet';
      _searchController.text = settings.searchKeywords ?? '';
      final platformTemplate = settings.messageTemplate;
      _messageController.text =
          (platformTemplate != null && platformTemplate.isNotEmpty)
              ? platformTemplate
              : (widget.campaign.messageTemplate ?? '');
    } else {
      _messageController.text = widget.campaign.messageTemplate ?? '';
    }
  }

  /// Save current settings
  void _saveSettings() {
    widget.onSettingsChanged(PlatformConfig(
      actionType: _selectedAction,
      searchKeywords: _searchController.text,
      messageTemplate: _messageController.text,
    ));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _messageController.dispose();
    _adapter?.cleanup();
    super.dispose();
  }

  Future<void> _initializeAdapter() async {
    setState(() {
      _isInitializing = true;
      _errorMessage = null;
      _statusMessage = 'Starting browser...';
    });

    try {
      _adapter = XAutomationAdapter();
      await _adapter!.initialize();

      final loggedIn = await _adapter!.isLoggedIn();
      setState(() {
        _isLoggedIn = loggedIn;
        _isInitializing = false;
        _statusMessage =
            loggedIn ? 'Connected to X' : 'Please login to X in the browser';
      });
    } catch (e) {
      setState(() {
        _isInitializing = false;
        _errorMessage = 'Failed to initialize: $e';
        _statusMessage = null;
      });
    }
  }

  Future<void> _searchProfiles() async {
    if (_adapter == null || _searchController.text.isEmpty) return;

    setState(() {
      _isSearching = true;
      _errorMessage = null;
      _statusMessage = 'Searching...';
      _profiles = [];
      _selectedIndices = {};
    });

    try {
      final profiles = await _adapter!.searchProfiles(_searchController.text);
      setState(() {
        _profiles = profiles;
        _isSearching = false;
        _statusMessage = 'Found ${profiles.length} profiles';
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
        _errorMessage = 'Search failed: $e';
        _statusMessage = null;
      });
    }
  }

  Future<void> _executeAction() async {
    if (_adapter == null) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      if (_selectedAction == 'post_tweet') {
        // Post a tweet - direct posting not yet implemented
        // Would need custom tweet compose flow
        setState(() {
          _statusMessage = 'Tweet posting requires custom implementation';
        });
      } else if (_selectedAction == 'follow_profiles') {
        final selectedProfiles =
            _selectedIndices.map((i) => _profiles[i]).toList();
        int successCount = 0;
        for (final profile in selectedProfiles) {
          try {
            await _adapter!.sendConnectionRequest(profile, '');
            successCount++;
          } catch (e) {
            // Continue with next
          }
        }
        setState(() {
          _statusMessage =
              'Followed $successCount/${selectedProfiles.length} profiles';
        });
      } else if (_selectedAction == 'send_dms') {
        final selectedProfiles =
            _selectedIndices.map((i) => _profiles[i]).toList();
        int successCount = 0;
        for (final profile in selectedProfiles) {
          try {
            await _adapter!.sendDirectMessage(
              profile,
              _messageController.text,
            );
            successCount++;
          } catch (e) {
            // Continue with next
          }
        }
        setState(() {
          _statusMessage = 'Sent $successCount/${selectedProfiles.length} DMs';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Action', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedAction,
                    items: const [
                      DropdownMenuItem(
                        value: 'post_tweet',
                        child: Text('Post Tweet'),
                      ),
                      DropdownMenuItem(
                        value: 'follow_profiles',
                        child: Text('Search & Follow Profiles'),
                      ),
                      DropdownMenuItem(
                        value: 'send_dms',
                        child: Text('Send Direct Messages'),
                      ),
                    ],
                    onChanged: (v) {
                      setState(() => _selectedAction = v!);
                      _saveSettings();
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_adapter == null)
            ElevatedButton.icon(
              onPressed: _isInitializing ? null : _initializeAdapter,
              icon: _isInitializing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.play_arrow),
              label: Text(_isInitializing ? 'Starting...' : 'Start Browser'),
            ),
          if (_statusMessage != null || _errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                _errorMessage ?? _statusMessage ?? '',
                style: TextStyle(
                  color: _errorMessage != null ? Colors.red : Colors.green,
                ),
              ),
            ),

          const SizedBox(height: 12),

          // Message/Tweet content (always visible)
          TextField(
            controller: _messageController,
            decoration: InputDecoration(
              labelText: _selectedAction == 'post_tweet'
                  ? 'Tweet Content'
                  : 'Message Template',
              hintText: widget.campaign.messageTemplate?.isNotEmpty == true
                  ? 'Campaign: ${widget.campaign.messageTemplate}'
                  : null,
            ),
            maxLines: 3,
            onChanged: (_) => _saveSettings(),
          ),
          if (_messageController.text.isEmpty &&
              widget.campaign.messageTemplate?.isNotEmpty == true)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    _messageController.text =
                        widget.campaign.messageTemplate ?? '';
                  });
                  _saveSettings();
                },
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('Use Campaign Template'),
              ),
            ),

          // Controls that require login
          if (_isLoggedIn) ...[
            if (_selectedAction != 'post_tweet') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        labelText: 'Search Profiles',
                      ),
                      onChanged: (_) => _saveSettings(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isSearching ? null : _searchProfiles,
                    child: Text(_isSearching ? 'Searching...' : 'Search'),
                  ),
                ],
              ),
            ],
            if (_profiles.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Select profiles (${_selectedIndices.length}/${_profiles.length})',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              SizedBox(
                height: 150,
                child: ListView.builder(
                  itemCount: _profiles.length,
                  itemBuilder: (context, index) {
                    final profile = _profiles[index];
                    return CheckboxListTile(
                      value: _selectedIndices.contains(index),
                      onChanged: (selected) {
                        setState(() {
                          if (selected == true) {
                            _selectedIndices.add(index);
                          } else {
                            _selectedIndices.remove(index);
                          }
                        });
                      },
                      title: Text(profile.name),
                      subtitle: Text(profile.handle ?? ''),
                      dense: true,
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _isProcessing ? null : _executeAction,
              icon: _isProcessing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
              label: Text(_isProcessing ? 'Processing...' : 'Execute'),
            ),
          ],
        ],
      ),
    );
  }
}

/// Substack platform tab with available actions
class _SubstackTab extends StatefulWidget {
  final OutreachCampaign campaign;
  final PlatformConfig? settings;
  final void Function(PlatformConfig) onSettingsChanged;

  const _SubstackTab({
    required this.campaign,
    this.settings,
    required this.onSettingsChanged,
  });

  @override
  State<_SubstackTab> createState() => _SubstackTabState();
}

class _SubstackTabState extends State<_SubstackTab> {
  final _searchController = TextEditingController();
  final _messageController = TextEditingController();

  SubstackAutomationAdapter? _adapter;
  List<ProfileData> _profiles = [];
  Set<int> _selectedIndices = {};

  bool _isInitializing = false;
  bool _isLoggedIn = false;
  bool _isSearching = false;
  bool _isProcessing = false;
  String? _statusMessage;
  String? _errorMessage;

  String _selectedAction = 'post_note';

  @override
  void initState() {
    super.initState();
    // Load from platform settings if available, fallback to campaign template
    final settings = widget.settings;
    if (settings != null) {
      _selectedAction = settings.actionType ?? 'post_note';
      _searchController.text = settings.searchKeywords ?? '';
      final platformTemplate = settings.messageTemplate;
      _messageController.text =
          (platformTemplate != null && platformTemplate.isNotEmpty)
              ? platformTemplate
              : (widget.campaign.messageTemplate ?? '');
    } else {
      _messageController.text = widget.campaign.messageTemplate ?? '';
    }
  }

  /// Save current settings
  void _saveSettings() {
    widget.onSettingsChanged(PlatformConfig(
      actionType: _selectedAction,
      searchKeywords: _searchController.text,
      messageTemplate: _messageController.text,
    ));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _messageController.dispose();
    _adapter?.cleanup();
    super.dispose();
  }

  Future<void> _initializeAdapter() async {
    setState(() {
      _isInitializing = true;
      _errorMessage = null;
      _statusMessage = 'Starting browser...';
    });

    try {
      _adapter = SubstackAutomationAdapter();
      await _adapter!.initialize();

      final loggedIn = await _adapter!.isLoggedIn();
      setState(() {
        _isLoggedIn = loggedIn;
        _isInitializing = false;
        _statusMessage = loggedIn
            ? 'Connected to Substack'
            : 'Please login to Substack in the browser';
      });
    } catch (e) {
      setState(() {
        _isInitializing = false;
        _errorMessage = 'Failed to initialize: $e';
        _statusMessage = null;
      });
    }
  }

  Future<void> _searchPublications() async {
    if (_adapter == null || _searchController.text.isEmpty) return;

    setState(() {
      _isSearching = true;
      _errorMessage = null;
      _statusMessage = 'Searching publications...';
      _profiles = [];
      _selectedIndices = {};
    });

    try {
      final profiles = await _adapter!.searchProfiles(_searchController.text);
      setState(() {
        _profiles = profiles;
        _isSearching = false;
        _statusMessage = 'Found ${profiles.length} publications';
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
        _errorMessage = 'Search failed: $e';
        _statusMessage = null;
      });
    }
  }

  Future<void> _executeAction() async {
    if (_adapter == null) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      if (_selectedAction == 'post_note') {
        // Post a note
        const profile = ProfileData(name: 'Self');
        await _adapter!.sendDirectMessage(
          profile,
          _messageController.text,
        );
        setState(() {
          _statusMessage = 'Note posted successfully';
        });
      } else if (_selectedAction == 'subscribe') {
        final selectedProfiles =
            _selectedIndices.map((i) => _profiles[i]).toList();
        int successCount = 0;
        for (final profile in selectedProfiles) {
          try {
            await _adapter!.sendConnectionRequest(profile, '');
            successCount++;
          } catch (e) {
            // Continue with next
          }
        }
        setState(() {
          _statusMessage =
              'Subscribed to $successCount/${selectedProfiles.length} publications';
        });
      } else if (_selectedAction == 'comment') {
        final selectedProfiles =
            _selectedIndices.map((i) => _profiles[i]).toList();
        int successCount = 0;
        for (final profile in selectedProfiles) {
          try {
            await _adapter!.commentOnLatestPost(
              profile,
              _messageController.text,
            );
            successCount++;
          } catch (e) {
            // Continue with next
          }
        }
        setState(() {
          _statusMessage =
              'Commented on $successCount/${selectedProfiles.length} publications';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Action', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedAction,
                    items: const [
                      DropdownMenuItem(
                        value: 'post_note',
                        child: Text('Post Note'),
                      ),
                      DropdownMenuItem(
                        value: 'subscribe',
                        child: Text('Search & Subscribe to Publications'),
                      ),
                      DropdownMenuItem(
                        value: 'comment',
                        child: Text('Comment on Latest Posts'),
                      ),
                    ],
                    onChanged: (v) {
                      setState(() => _selectedAction = v!);
                      _saveSettings();
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_adapter == null)
            ElevatedButton.icon(
              onPressed: _isInitializing ? null : _initializeAdapter,
              icon: _isInitializing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.play_arrow),
              label: Text(_isInitializing ? 'Starting...' : 'Start Browser'),
            ),
          if (_statusMessage != null || _errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                _errorMessage ?? _statusMessage ?? '',
                style: TextStyle(
                  color: _errorMessage != null ? Colors.red : Colors.green,
                ),
              ),
            ),

          const SizedBox(height: 12),

          // Show different fields based on action
          if (_selectedAction == 'post_note') ...[
            // Note content with campaign template fallback
            TextField(
              controller: _messageController,
              decoration: InputDecoration(
                labelText: 'Note Content',
                hintText: widget.campaign.messageTemplate?.isNotEmpty == true
                    ? 'Campaign: ${widget.campaign.messageTemplate}'
                    : null,
              ),
              maxLines: 3,
              onChanged: (_) => _saveSettings(),
            ),
            if (_messageController.text.isEmpty &&
                widget.campaign.messageTemplate?.isNotEmpty == true)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _messageController.text =
                          widget.campaign.messageTemplate ?? '';
                    });
                    _saveSettings();
                  },
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Use Campaign Template'),
                ),
              ),
          ],

          if (_selectedAction == 'subscribe') ...[
            // Search field for finding publications
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: 'Search Publications',
                    ),
                    onChanged: (_) => _saveSettings(),
                  ),
                ),
                if (_isLoggedIn) ...[
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isSearching ? null : _searchPublications,
                    child: Text(_isSearching ? 'Searching...' : 'Search'),
                  ),
                ],
              ],
            ),
          ],

          if (_selectedAction == 'comment') ...[
            // Comment field only
            TextField(
              controller: _messageController,
              decoration: InputDecoration(
                labelText: 'Comment',
                hintText: widget.campaign.messageTemplate?.isNotEmpty == true
                    ? 'Campaign: ${widget.campaign.messageTemplate}'
                    : 'Enter your comment',
              ),
              maxLines: 3,
              onChanged: (_) => _saveSettings(),
            ),
            if (_messageController.text.isEmpty &&
                widget.campaign.messageTemplate?.isNotEmpty == true)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _messageController.text =
                          widget.campaign.messageTemplate ?? '';
                    });
                    _saveSettings();
                  },
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Use Campaign Template'),
                ),
              ),
          ],

          // Controls that require login
          if (_isLoggedIn) ...[
            if (_profiles.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Select publications (${_selectedIndices.length}/${_profiles.length})',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              SizedBox(
                height: 150,
                child: ListView.builder(
                  itemCount: _profiles.length,
                  itemBuilder: (context, index) {
                    final profile = _profiles[index];
                    return CheckboxListTile(
                      value: _selectedIndices.contains(index),
                      onChanged: (selected) {
                        setState(() {
                          if (selected == true) {
                            _selectedIndices.add(index);
                          } else {
                            _selectedIndices.remove(index);
                          }
                        });
                      },
                      title: Text(profile.name),
                      subtitle: Text(profile.handle ?? ''),
                      dense: true,
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _isProcessing ? null : _executeAction,
              icon: _isProcessing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
              label: Text(_isProcessing ? 'Processing...' : 'Execute'),
            ),
          ],
        ],
      ),
    );
  }
}

/// Email platform tab with available actions
class _EmailTab extends StatefulWidget {
  final OutreachCampaign campaign;

  const _EmailTab({required this.campaign});

  @override
  State<_EmailTab> createState() => _EmailTabState();
}

class _EmailTabState extends State<_EmailTab> {
  final _emailController = TextEditingController();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();

  bool _isProcessing = false;
  String? _statusMessage;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _subjectController.text = widget.campaign.emailSubject ?? '';
    _messageController.text = widget.campaign.messageTemplate ?? '';
  }

  @override
  void dispose() {
    _emailController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendEmail() async {
    if (_emailController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter recipient email';
      });
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
      _statusMessage = 'Sending email...';
    });

    try {
      final restClient = context.read<RestClient>();
      final adapter = EmailAutomationAdapter(restClient);
      await adapter.initialize();

      await adapter.sendDirectMessage(
        ProfileData(
          name: _emailController.text.split('@').first,
          email: _emailController.text,
        ),
        _messageController.text,
        campaignId: widget.campaign.campaignId,
        subject: _subjectController.text,
      );

      setState(() {
        _statusMessage = 'Email sent successfully';
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to send: $e';
        _isProcessing = false;
        _statusMessage = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'Email is sent via Moqui backend.\n'
                'Configure SMTP in the backend settings.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Recipient Email',
              hintText: 'user@example.com',
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _subjectController,
            decoration: const InputDecoration(
              labelText: 'Subject',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _messageController,
            decoration: const InputDecoration(
              labelText: 'Message Body',
              hintText: 'Use {name} for personalization',
            ),
            maxLines: 5,
          ),
          if (_statusMessage != null || _errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                _errorMessage ?? _statusMessage ?? '',
                style: TextStyle(
                  color: _errorMessage != null ? Colors.red : Colors.green,
                ),
              ),
            ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _isProcessing ? null : _sendEmail,
            icon: _isProcessing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
            label: Text(_isProcessing ? 'Sending...' : 'Send Email'),
          ),
        ],
      ),
    );
  }
}
