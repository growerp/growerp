/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 */

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';

import 'catalog_swag_demo_runner.dart';
import 'demo_progress_service.dart';

// ── Demo registry ─────────────────────────────────────────────────────────────

/// Describes a runnable demo that appears in the demo list.
class DemoEntry {
  final String title;
  final String description;
  final IconData icon;
  final int totalPhases;
  final Future<int> Function(String ownerPartyId) getProgress;
  final Future<void> Function(String ownerPartyId) resetProgress;
  final Widget Function() builder;

  const DemoEntry({
    required this.title,
    required this.description,
    required this.icon,
    required this.totalPhases,
    required this.getProgress,
    required this.resetProgress,
    required this.builder,
  });
}

/// All registered demos. Add new demos here to have them appear in the list.
final List<DemoEntry> registeredDemos = [
  DemoEntry(
    title: 'Catalog & Manufacturing Demo',
    description:
        'End-to-end lifecycle: create swag products and a Bill of Materials, '
        'sell kits via a sales order, auto-create a work order, purchase and '
        'receive components, assemble the kits, ship to the customer, and '
        'review GL transactions.',
    icon: Icons.precision_manufacturing,
    totalPhases: 9,
    getProgress: DemoProgressService.getCurrentStep,
    resetProgress: DemoProgressService.reset,
    builder: () => const CatalogSwagDemoRunner(),
  ),
];

// ── Screen ────────────────────────────────────────────────────────────────────

/// Shows all available demos. Only visible when not running in release mode.
///
/// Register this widget as 'DemoList' in adminWidgetRegistrations and add a
/// menu item (widgetName: 'DemoList') via the admin FAB in development.
class DemoListScreen extends StatefulWidget {
  const DemoListScreen({super.key});

  @override
  State<DemoListScreen> createState() => _DemoListScreenState();
}

class _DemoListScreenState extends State<DemoListScreen> {
  // Per-demo cached progress (step index).
  late List<int> _progress;
  bool _loaded = false;
  String _ownerPartyId = 'default';

  @override
  void initState() {
    super.initState();
    _progress = List.filled(registeredDemos.length, 0);
    _ownerPartyId =
        context.read<AuthBloc>().state.authenticate?.ownerPartyId ?? 'default';
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final values = await Future.wait(
      registeredDemos.map((d) => d.getProgress(_ownerPartyId)),
    );
    if (mounted) {
      setState(() {
        _progress = values;
        _loaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Guard: never shown in production builds.
    if (kReleaseMode) {
      return const Scaffold(
        body: Center(
          child: Text('Demo features are not available in production.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('GrowERP Demos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh progress',
            onPressed: _loadProgress,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDevBanner(),
          Expanded(
            child: _loaded
                ? _buildDemoList()
                : const Center(child: CircularProgressIndicator()),
          ),
        ],
      ),
    );
  }

  Widget _buildDevBanner() {
    return Material(
      color: Colors.amber.shade100,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Icon(Icons.bug_report, size: 18, color: Colors.amber.shade800),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Development environment — demos are hidden in production builds.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.amber.shade900,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDemoList() {
    if (registeredDemos.isEmpty) {
      return const Center(child: Text('No demos registered.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: registeredDemos.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (ctx, index) => _DemoCard(
        entry: registeredDemos[index],
        currentStep: _progress[index],
        ownerPartyId: _ownerPartyId,
        onResetDone: _loadProgress,
        onOpen: () => _openDemo(ctx, index),
      ),
    );
  }

  Future<void> _openDemo(BuildContext ctx, int index) async {
    await Navigator.of(ctx).push<void>(
      MaterialPageRoute(
        builder: (_) => registeredDemos[index].builder(),
      ),
    );
    // Refresh progress when returning from the runner.
    await _loadProgress();
  }
}

// ── Demo card ─────────────────────────────────────────────────────────────────

class _DemoCard extends StatelessWidget {
  final DemoEntry entry;
  final int currentStep;
  final String ownerPartyId;
  final VoidCallback onResetDone;
  final VoidCallback onOpen;

  const _DemoCard({
    required this.entry,
    required this.currentStep,
    required this.ownerPartyId,
    required this.onResetDone,
    required this.onOpen,
  });

  bool get _isComplete => currentStep >= entry.totalPhases;
  bool get _isStarted => currentStep > 0;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: _isComplete
                        ? Colors.green.shade100
                        : Theme.of(context).colorScheme.primaryContainer,
                    child: Icon(
                      _isComplete ? Icons.check_circle : entry.icon,
                      color: _isComplete
                          ? Colors.green.shade700
                          : Theme.of(context).colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _statusLabel,
                          style: TextStyle(
                            fontSize: 12,
                            color: _isComplete
                                ? Colors.green.shade700
                                : Theme.of(context).colorScheme.secondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildResetButton(context),
                ],
              ),
              const SizedBox(height: 12),
              // Description
              Text(
                entry.description,
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              // Progress bar + step count
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: entry.totalPhases > 0
                            ? currentStep / entry.totalPhases
                            : 0,
                        minHeight: 6,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation(
                          _isComplete
                              ? Colors.green.shade600
                              : Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '$currentStep / ${entry.totalPhases}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Action button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: Icon(_buttonIcon, size: 18),
                  label: Text(_buttonLabel),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isComplete
                        ? Colors.grey.shade200
                        : null,
                    foregroundColor: _isComplete
                        ? Colors.grey.shade700
                        : null,
                  ),
                  onPressed: onOpen,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _statusLabel {
    if (_isComplete) return 'Completed';
    if (_isStarted) return 'In progress — step $currentStep of ${entry.totalPhases}';
    return 'Not started';
  }

  String get _buttonLabel {
    if (_isComplete) return 'Run Again';
    if (_isStarted) return 'Resume (step ${currentStep + 1})';
    return 'Start Demo';
  }

  IconData get _buttonIcon {
    if (_isComplete) return Icons.replay;
    if (_isStarted) return Icons.play_arrow;
    return Icons.play_circle_outline;
  }

  Widget _buildResetButton(BuildContext context) {
    if (!_isStarted) return const SizedBox.shrink();
    return IconButton(
      icon: const Icon(Icons.restart_alt, size: 20),
      tooltip: 'Reset progress',
      onPressed: () async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Reset demo?'),
            content: const Text(
              'Progress will be reset to step 0.\n'
              'Data already created in the system is kept.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text(
                  'Reset',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        );
        if (confirm == true) {
          await entry.resetProgress(ownerPartyId);
          onResetDone();
        }
      },
    );
  }
}
