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
import 'package:growerp_outreach/growerp_outreach.dart';

/// Test screen for BrowserMCP integration with LinkedIn adapter testing
class BrowserTestScreen extends StatefulWidget {
  const BrowserTestScreen({super.key});

  @override
  State<BrowserTestScreen> createState() => _BrowserTestScreenState();
}

class _BrowserTestScreenState extends State<BrowserTestScreen>
    with SingleTickerProviderStateMixin {
  final FlutterMcpBrowserService _browserService = FlutterMcpBrowserService();
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _linkedInSearchController =
      TextEditingController();
  final List<String> _logs = [];
  bool _isLoading = false;
  bool _isInitialized = false;
  SnapshotElement? _lastSnapshot;
  List<ProfileData> _searchResults = [];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _urlController.text = 'https://example.com';
    _linkedInSearchController.text = 'Flutter developer Thailand';
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _browserService.cleanup();
    _urlController.dispose();
    _linkedInSearchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _log(String message) {
    setState(() {
      _logs.add('[${DateTime.now().toString().substring(11, 19)}] $message');
      if (_logs.length > 50) {
        _logs.removeAt(0);
      }
    });
  }

  // ========== Browser Tab Methods ==========

  Future<void> _initialize() async {
    setState(() => _isLoading = true);
    _log('Initializing BrowserMCP...');

    try {
      await _browserService.initialize();
      setState(() => _isInitialized = true);
      _log('✅ BrowserMCP initialized successfully!');
    } catch (e) {
      _log('❌ Failed to initialize: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _navigate() async {
    if (!_isInitialized) {
      _log('⚠️ Please initialize first');
      return;
    }

    final url = _urlController.text.trim();
    if (url.isEmpty) {
      _log('⚠️ Please enter a URL');
      return;
    }

    setState(() => _isLoading = true);
    _log('Navigating to: $url');

    try {
      await _browserService.navigate(url);
      _log('✅ Navigation complete');
      _log('Current URL: ${_browserService.currentUrl}');
    } catch (e) {
      _log('❌ Navigation failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _getSnapshot() async {
    if (!_isInitialized) {
      _log('⚠️ Please initialize first');
      return;
    }

    setState(() => _isLoading = true);
    _log('Getting page snapshot...');

    try {
      final snapshot = await _browserService.snapshot();
      setState(() => _lastSnapshot = snapshot);
      _log('✅ Snapshot received');
      _log('Page title: ${_extractTitle(snapshot)}');
      _log('Elements found: ${_countElements(snapshot)}');
      _log('📋 Tap "View Snapshot" to see the accessibility tree');
    } catch (e) {
      _log('❌ Failed to get snapshot: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnapshotDialog() {
    if (_lastSnapshot == null) {
      _log('⚠️ No snapshot available. Get a snapshot first.');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Page Snapshot (Accessibility Tree)',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: SingleChildScrollView(
                  child: SelectableText(
                    _formatSnapshot(_lastSnapshot!, 0),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatSnapshot(SnapshotElement element, int depth) {
    final buffer = StringBuffer();
    final indent = '  ' * depth;

    buffer.write(indent);
    buffer.write('- ${element.role}');
    if (element.name != null && element.name!.isNotEmpty) {
      buffer.write(' "${element.name}"');
    }
    buffer.write(' [ref=${element.ref}]');
    buffer.writeln();

    for (final child in element.children) {
      buffer.write(_formatSnapshot(child, depth + 1));
    }

    return buffer.toString();
  }

  String _extractTitle(SnapshotElement? element) {
    if (element == null) return 'Unknown';
    final headings = SnapshotParser.getElementsByRole(element, 'heading');
    if (headings.isNotEmpty) {
      return headings.first.name ?? 'Unknown';
    }
    return element.name ?? 'Unknown';
  }

  int _countElements(SnapshotElement? element) {
    if (element == null) return 0;
    int count = 1;
    for (final child in element.children) {
      count += _countElements(child);
    }
    return count;
  }

  Future<void> _cleanup() async {
    setState(() => _isLoading = true);
    _log('Cleaning up...');

    try {
      await _browserService.cleanup();
      setState(() {
        _isInitialized = false;
        _searchResults = [];
      });
      _log('✅ Cleanup complete');
    } catch (e) {
      _log('❌ Cleanup failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ========== LinkedIn Tab Methods ==========

  Future<void> _linkedInNavigate() async {
    if (!_isInitialized) {
      _log('⚠️ Please initialize first');
      return;
    }

    setState(() => _isLoading = true);
    _log('Navigating to LinkedIn...');

    try {
      await _browserService.navigate('https://www.linkedin.com');
      _log('✅ LinkedIn page loaded');

      final snapshot = await _browserService.snapshot();
      final homeNav = SnapshotParser.findByText(snapshot, 'Home');
      final signIn = SnapshotParser.findByText(snapshot, 'Sign in');

      if (homeNav != null) {
        _log('✅ Logged in to LinkedIn');
      } else if (signIn != null) {
        _log('⚠️ Not logged in. Please log in manually in the browser.');
      } else {
        _log('⚠️ Unable to determine login status');
      }
    } catch (e) {
      _log('❌ Navigation failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _linkedInSearch() async {
    if (!_isInitialized) {
      _log('⚠️ Please initialize first');
      return;
    }

    final searchQuery = _linkedInSearchController.text.trim();
    if (searchQuery.isEmpty) {
      _log('⚠️ Please enter a search query');
      return;
    }

    setState(() {
      _isLoading = true;
      _searchResults = [];
    });
    _log('Searching LinkedIn for: $searchQuery');

    try {
      final adapter = LinkedInAutomationAdapter(browser: _browserService);
      final profiles = await adapter.searchProfiles(searchQuery);

      setState(() => _searchResults = profiles);
      _log('✅ Found ${profiles.length} profiles');

      for (final profile in profiles.take(5)) {
        _log('  - ${profile.name}');
        if (profile.profileUrl != null) {
          _log('    URL: ${profile.profileUrl}');
        }
      }

      if (profiles.length > 5) {
        _log('  ... and ${profiles.length - 5} more');
      }
    } catch (e) {
      _log('❌ Search failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _linkedInCheckLogin() async {
    if (!_isInitialized) {
      _log('⚠️ Please initialize first');
      return;
    }

    setState(() => _isLoading = true);
    _log('Checking LinkedIn login status...');

    try {
      final adapter = LinkedInAutomationAdapter(browser: _browserService);
      final isLoggedIn = await adapter.isLoggedIn();
      _log(isLoggedIn
          ? '✅ Logged in to LinkedIn'
          : '❌ Not logged in to LinkedIn');
    } catch (e) {
      _log('❌ Login check failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ========== Build Methods ==========

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BrowserMCP Test'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.language), text: 'Browser'),
            Tab(icon: Icon(Icons.business), text: 'LinkedIn'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Status indicator (always visible)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              color:
                  _isInitialized ? Colors.green.shade100 : Colors.grey.shade200,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Icon(
                      _isInitialized
                          ? Icons.check_circle
                          : Icons.circle_outlined,
                      color: _isInitialized ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _isInitialized
                            ? 'BrowserMCP Connected'
                            : 'Not Connected',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _isInitialized
                              ? Colors.green.shade800
                              : Colors.grey.shade700,
                        ),
                      ),
                    ),
                    if (!_isInitialized)
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _initialize,
                        icon: const Icon(Icons.play_arrow, size: 18),
                        label: const Text('Initialize'),
                      )
                    else
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _cleanup,
                        icon: const Icon(Icons.stop, size: 18),
                        label: const Text('Cleanup'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade100,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Loading indicator
          if (_isLoading) const LinearProgressIndicator(),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildBrowserTab(),
                _buildLinkedInTab(),
              ],
            ),
          ),

          // Logs (always visible)
          _buildLogsSection(),
        ],
      ),
    );
  }

  Widget _buildBrowserTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // URL input
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _urlController,
                  decoration: const InputDecoration(
                    labelText: 'URL',
                    border: OutlineInputBorder(),
                    hintText: 'https://example.com',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _isLoading || !_isInitialized ? null : _navigate,
                icon: const Icon(Icons.navigation),
                label: const Text('Go'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Snapshot buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed:
                      _isLoading || !_isInitialized ? null : _getSnapshot,
                  icon: const Icon(Icons.camera),
                  label: const Text('Get Snapshot'),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _lastSnapshot == null ? null : _showSnapshotDialog,
                icon: const Icon(Icons.visibility),
                label: const Text('View Snapshot'),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _lastSnapshot != null ? Colors.blue.shade100 : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLinkedInTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Quick actions
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                onPressed:
                    _isLoading || !_isInitialized ? null : _linkedInNavigate,
                icon: const Icon(Icons.login),
                label: const Text('Go to LinkedIn'),
              ),
              ElevatedButton.icon(
                onPressed:
                    _isLoading || !_isInitialized ? null : _linkedInCheckLogin,
                icon: const Icon(Icons.verified_user),
                label: const Text('Check Login'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Search input
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _linkedInSearchController,
                  decoration: const InputDecoration(
                    labelText: 'Search Query',
                    border: OutlineInputBorder(),
                    hintText: 'e.g., Flutter developer Thailand',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed:
                    _isLoading || !_isInitialized ? null : _linkedInSearch,
                icon: const Icon(Icons.search),
                label: const Text('Search'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Search results
          if (_searchResults.isNotEmpty) ...[
            Text(
              'Search Results (${_searchResults.length})',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final profile = _searchResults[index];
                  return Card(
                    child: ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.person),
                      ),
                      title: Text(profile.name),
                      subtitle: profile.profileUrl != null
                          ? Text(
                              profile.profileUrl!,
                              overflow: TextOverflow.ellipsis,
                            )
                          : null,
                    ),
                  );
                },
              ),
            ),
          ] else
            const Expanded(
              child: Center(
                child: Text(
                  'No search results yet.\nUse the search above to find profiles.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLogsSection() {
    return SizedBox(
      height: 150,
      child: Card(
        margin: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Logs',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.clear_all, size: 20),
                    onPressed: () => setState(() => _logs.clear()),
                    tooltip: 'Clear logs',
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: _logs.length,
                itemBuilder: (context, index) {
                  final log = _logs[_logs.length - 1 - index];
                  return Text(
                    log,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: log.contains('❌')
                          ? Colors.red
                          : log.contains('✅')
                              ? Colors.green
                              : log.contains('⚠️')
                                  ? Colors.orange
                                  : null,
                    ),
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
