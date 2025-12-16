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

import '../services/adapters/linkedin_automation_adapter.dart';
import '../services/platform_automation_adapter.dart';

/// Screen for sending messages to LinkedIn 1st-level connections
///
/// This screen allows users to:
/// 1. Connect to LinkedIn via browser automation
/// 2. Fetch their 1st-level connections
/// 3. Compose and send personalized messages
class LinkedInMessagingScreen extends StatefulWidget {
  const LinkedInMessagingScreen({super.key});

  @override
  State<LinkedInMessagingScreen> createState() =>
      _LinkedInMessagingScreenState();
}

class _LinkedInMessagingScreenState extends State<LinkedInMessagingScreen> {
  final _messageController = TextEditingController();
  final _maxConnectionsController = TextEditingController(text: '20');

  LinkedInAutomationAdapter? _adapter;
  List<ProfileData> _connections = [];
  Set<int> _selectedIndices = {};
  List<MessageResult> _results = [];

  bool _isInitializing = false;
  bool _isLoggedIn = false;
  bool _isFetchingConnections = false;
  bool _isSendingMessages = false;
  String? _statusMessage;
  String? _errorMessage;

  @override
  void dispose() {
    _messageController.dispose();
    _maxConnectionsController.dispose();
    _adapter?.cleanup();
    super.dispose();
  }

  Future<void> _initializeAdapter() async {
    setState(() {
      _isInitializing = true;
      _errorMessage = null;
      _statusMessage = 'Initializing browser automation...';
    });

    try {
      _adapter = LinkedInAutomationAdapter();
      await _adapter!.initialize();

      final loggedIn = await _adapter!.isLoggedIn();
      setState(() {
        _isLoggedIn = loggedIn;
        _isInitializing = false;
        _statusMessage = loggedIn
            ? 'Connected to LinkedIn'
            : 'Please login to LinkedIn in the browser window';
      });
    } catch (e) {
      setState(() {
        _isInitializing = false;
        _errorMessage = 'Failed to initialize: $e';
        _statusMessage = null;
      });
    }
  }

  Future<void> _checkLoginStatus() async {
    if (_adapter == null) return;

    setState(() {
      _statusMessage = 'Checking login status...';
    });

    try {
      final loggedIn = await _adapter!.isLoggedIn();
      setState(() {
        _isLoggedIn = loggedIn;
        _statusMessage =
            loggedIn ? 'Logged in to LinkedIn' : 'Not logged in yet';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error checking login: $e';
      });
    }
  }

  Future<void> _fetchConnections() async {
    if (_adapter == null || !_isLoggedIn) return;

    final maxResults = int.tryParse(_maxConnectionsController.text) ?? 20;

    setState(() {
      _isFetchingConnections = true;
      _errorMessage = null;
      _statusMessage = 'Fetching 1st-level connections...';
      _connections = [];
      _selectedIndices = {};
    });

    try {
      final connections = await _adapter!.getFirstLevelConnections(
        maxResults: maxResults,
        scrollCount: (maxResults / 10).ceil(),
      );

      setState(() {
        _connections = connections;
        _isFetchingConnections = false;
        _statusMessage = 'Found ${connections.length} connections';
        // Select all by default
        _selectedIndices =
            Set.from(List.generate(connections.length, (i) => i));
      });
    } catch (e) {
      setState(() {
        _isFetchingConnections = false;
        _errorMessage = 'Failed to fetch connections: $e';
        _statusMessage = null;
      });
    }
  }

  Future<void> _sendMessages() async {
    if (_adapter == null || _selectedIndices.isEmpty) return;

    final message = _messageController.text.trim();
    if (message.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a message';
      });
      return;
    }

    final selectedConnections =
        _selectedIndices.map((i) => _connections[i]).toList();

    setState(() {
      _isSendingMessages = true;
      _errorMessage = null;
      _results = [];
      _statusMessage =
          'Sending messages to ${selectedConnections.length} connections...';
    });

    try {
      final results = await _adapter!.sendBatchMessages(
        connections: selectedConnections,
        messageTemplate: message,
        delayBetweenMessages: const Duration(seconds: 15),
      );

      final successCount = results.where((r) => r.success).length;
      final failCount = results.where((r) => !r.success).length;

      setState(() {
        _results = results;
        _isSendingMessages = false;
        _statusMessage = 'Sent: $successCount successful, $failCount failed';
      });
    } catch (e) {
      setState(() {
        _isSendingMessages = false;
        _errorMessage = 'Error sending messages: $e';
        _statusMessage = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LinkedIn Messaging'),
        actions: [
          if (_adapter != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _checkLoginStatus,
              tooltip: 'Check Login Status',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status card
            _buildStatusCard(),
            const SizedBox(height: 16),

            // Step 1: Initialize
            _buildInitializeSection(),
            const SizedBox(height: 16),

            // Step 2: Fetch connections
            if (_isLoggedIn) ...[
              _buildFetchSection(),
              const SizedBox(height: 16),
            ],

            // Step 3: Connections list
            if (_connections.isNotEmpty) ...[
              _buildConnectionsList(),
              const SizedBox(height: 16),
            ],

            // Step 4: Message composer
            if (_connections.isNotEmpty && _selectedIndices.isNotEmpty) ...[
              _buildMessageComposer(),
              const SizedBox(height: 16),
            ],

            // Results
            if (_results.isNotEmpty) _buildResultsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    Color statusColor = Colors.grey;
    IconData statusIcon = Icons.info;

    if (_errorMessage != null) {
      statusColor = Colors.red;
      statusIcon = Icons.error;
    } else if (_isLoggedIn) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    } else if (_adapter != null) {
      statusColor = Colors.orange;
      statusIcon = Icons.warning;
    }

    return Card(
      color: statusColor.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(statusIcon, color: statusColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _errorMessage ?? _statusMessage ?? 'Not connected',
                style: TextStyle(color: statusColor),
              ),
            ),
            if (_isInitializing || _isFetchingConnections || _isSendingMessages)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitializeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Step 1: Connect to LinkedIn',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'This will open a browser window. Login to LinkedIn if prompted.',
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _isInitializing ? null : _initializeAdapter,
              icon: const Icon(Icons.launch),
              label: Text(_adapter == null ? 'Start Browser' : 'Reconnect'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFetchSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Step 2: Fetch 1st-Level Connections',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                SizedBox(
                  width: 100,
                  child: TextField(
                    controller: _maxConnectionsController,
                    decoration: const InputDecoration(
                      labelText: 'Max',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _isFetchingConnections ? null : _fetchConnections,
                  icon: const Icon(Icons.people),
                  label: const Text('Fetch Connections'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionsList() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Step 3: Select Connections (${_selectedIndices.length}/${_connections.length})',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => setState(() {
                        _selectedIndices = Set.from(
                          List.generate(_connections.length, (i) => i),
                        );
                      }),
                      child: const Text('Select All'),
                    ),
                    TextButton(
                      onPressed: () => setState(() {
                        _selectedIndices = {};
                      }),
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: ListView.builder(
                itemCount: _connections.length,
                itemBuilder: (context, index) {
                  final conn = _connections[index];
                  final isSelected = _selectedIndices.contains(index);

                  return CheckboxListTile(
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selectedIndices.add(index);
                        } else {
                          _selectedIndices.remove(index);
                        }
                      });
                    },
                    title: Text(conn.name),
                    subtitle: conn.title != null ? Text(conn.title!) : null,
                    dense: true,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageComposer() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Step 4: Compose Message',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Use {name} to personalize with contact name.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                labelText: 'Message',
                border: OutlineInputBorder(),
                hintText: 'Hi {name}, I wanted to reach out about...',
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _isSendingMessages ? null : _sendMessages,
              icon: const Icon(Icons.send),
              label: Text('Send to ${_selectedIndices.length} Connections'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '⚠️ Messages are sent with 10-20 second delays to avoid rate limits.',
              style: TextStyle(fontSize: 12, color: Colors.orange),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsSection() {
    final successCount = _results.where((r) => r.success).length;
    final failCount = _results.where((r) => !r.success).length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Results: $successCount sent, $failCount failed',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 150,
              child: ListView.builder(
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  final result = _results[index];
                  return ListTile(
                    leading: Icon(
                      result.success ? Icons.check_circle : Icons.error,
                      color: result.success ? Colors.green : Colors.red,
                    ),
                    title: Text(result.profile.name),
                    subtitle: result.error != null
                        ? Text(
                            result.error!,
                            style: const TextStyle(color: Colors.red),
                          )
                        : Text(
                            'Sent at ${result.timestamp.toString().substring(11, 19)}',
                          ),
                    dense: true,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
