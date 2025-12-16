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
import 'package:growerp_outreach/growerp_outreach.dart';

/// Test screen for BrowserMCP integration
class BrowserTestScreen extends StatefulWidget {
  const BrowserTestScreen({super.key});

  @override
  State<BrowserTestScreen> createState() => _BrowserTestScreenState();
}

class _BrowserTestScreenState extends State<BrowserTestScreen> {
  final FlutterMcpBrowserService _browserService = FlutterMcpBrowserService();
  final TextEditingController _urlController = TextEditingController();
  final List<String> _logs = [];
  bool _isLoading = false;
  bool _isInitialized = false;
  SnapshotElement? _lastSnapshot;

  @override
  void initState() {
    super.initState();
    _urlController.text = 'https://example.com';
  }

  @override
  void dispose() {
    _browserService.cleanup();
    _urlController.dispose();
    super.dispose();
  }

  void _log(String message) {
    setState(() {
      _logs.add('[${DateTime.now().toString().substring(11, 19)}] $message');
      // Keep only last 50 logs
      if (_logs.length > 50) {
        _logs.removeAt(0);
      }
    });
  }

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
    
    // Format: role "name" [ref=xxx]
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
    // Try to find heading or title
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
      });
      _log('✅ Cleanup complete');
    } catch (e) {
      _log('❌ Cleanup failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BrowserMCP Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status indicator
            Card(
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
                    Text(
                      _isInitialized ? 'BrowserMCP Connected' : 'Not Connected',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _isInitialized
                            ? Colors.green.shade800
                            : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Control buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _isLoading || _isInitialized ? null : _initialize,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Initialize'),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading || !_isInitialized ? null : _cleanup,
                  icon: const Icon(Icons.stop),
                  label: const Text('Cleanup'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade100,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

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
                  label: const Text('Navigate'),
                ),
              ],
            ),
            const SizedBox(height: 8),

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
                    backgroundColor: _lastSnapshot != null
                        ? Colors.blue.shade100
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Loading indicator
            if (_isLoading) const LinearProgressIndicator(),

            const SizedBox(height: 8),

            // Logs
            Expanded(
              child: Card(
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
            ),
          ],
        ),
      ),
    );
  }
}
