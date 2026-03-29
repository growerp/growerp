/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 */

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_catalog/growerp_catalog.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

import 'demo_progress_helper.dart';

// ── Phase definition ─────────────────────────────────────────────────────────

class DemoPhase {
  final String title;
  final String description;

  /// Widget name registered in WidgetRegistry — shown in the live screen panel.
  final String widgetName;

  final Future<String> Function(RestClient, String, String) action;

  const DemoPhase({
    required this.title,
    required this.description,
    required this.widgetName,
    required this.action,
  });
}

// ── Generic demo runner ───────────────────────────────────────────────────────

/// A reusable step-by-step demo runner.
///
/// Provide a [title], a list of [phases], and a [progress] helper.
/// Each phase executes an action via the REST client and shows a live widget.
class GenericDemoRunner extends StatefulWidget {
  final String title;
  final List<DemoPhase> phases;
  final DemoProgressHelper progress;

  const GenericDemoRunner({
    super.key,
    required this.title,
    required this.phases,
    required this.progress,
  });

  @override
  State<GenericDemoRunner> createState() => _GenericDemoRunnerState();
}

class _GenericDemoRunnerState extends State<GenericDemoRunner> {
  int _currentStep = 0;
  int _displayedStep = 0;
  int _screenVersion = 0;
  bool _isRunning = false;
  bool _isComplete = false;
  String? _lastMessage;
  String? _errorMessage;

  late RestClient _restClient;
  late String _classificationId;
  late String _ownerPartyId;

  @override
  void initState() {
    super.initState();
    _restClient = context.read<ProductBloc>().restClient;
    _classificationId = context.read<String>();
    _ownerPartyId =
        context.read<AuthBloc>().state.authenticate?.ownerPartyId ?? 'default';
    _loadSavedStep();
  }

  Future<void> _loadSavedStep() async {
    final step = await widget.progress.getCurrentStep(_ownerPartyId);
    if (mounted) {
      setState(() {
        _currentStep = step;
        _displayedStep = step.clamp(0, widget.phases.length - 1);
        _isComplete = step >= widget.phases.length;
        _screenVersion++;
      });
    }
  }

  Future<void> _runCurrentStep() async {
    if (_currentStep >= widget.phases.length) return;
    final phase = widget.phases[_currentStep];

    setState(() {
      _isRunning = true;
      _displayedStep = _currentStep;
      _screenVersion++;
      _errorMessage = null;
      _lastMessage = null;
    });

    try {
      final message =
          await phase.action(_restClient, _classificationId, _ownerPartyId);
      final nextStep = _currentStep + 1;
      await widget.progress.saveStep(nextStep, _ownerPartyId);

      if (mounted) {
        setState(() {
          _isRunning = false;
          _lastMessage = message;
          _currentStep = nextStep;
          _screenVersion++;
          _isComplete = nextStep >= widget.phases.length;
        });
      }
    } on DioException catch (e) {
      final msg = await getDioError(e);
      if (mounted) {
        setState(() {
          _isRunning = false;
          _errorMessage = msg;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRunning = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  Future<void> _reset() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Demo?'),
        content: const Text(
          'This will reset your progress to step 0.\n'
          'Demo data already created in the system will remain.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Reset', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await widget.progress.reset(_ownerPartyId);
      setState(() {
        _currentStep = 0;
        _displayedStep = 0;
        _screenVersion++;
        _isComplete = false;
        _lastMessage = null;
        _errorMessage = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset demo progress',
            onPressed: _isRunning ? null : _reset,
          ),
        ],
      ),
      body: Column(
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.44,
            ),
            child: SingleChildScrollView(child: _buildControlPanel()),
          ),
          const Divider(height: 1, thickness: 1),
          Expanded(child: _buildLiveScreen()),
        ],
      ),
    );
  }

  Widget _buildControlPanel() {
    final phase = _isComplete || _currentStep >= widget.phases.length
        ? widget.phases.last
        : widget.phases[_currentStep];
    final displayPhase =
        widget.phases[_displayedStep.clamp(0, widget.phases.length - 1)];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                _isComplete
                    ? 'All ${widget.phases.length} steps complete'
                    : 'Step ${_currentStep + 1} of ${widget.phases.length}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: LinearProgressIndicator(
                  value: widget.phases.isNotEmpty
                      ? (_isComplete
                            ? 1.0
                            : _currentStep / widget.phases.length)
                      : 0,
                  minHeight: 5,
                  borderRadius: BorderRadius.circular(4),
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation(
                    _isComplete ? Colors.green.shade600 : null,
                  ),
                ),
              ),
              if (_isComplete) ...[
                const SizedBox(width: 8),
                Icon(Icons.check_circle, size: 18, color: Colors.green.shade600),
              ],
            ],
          ),
          const SizedBox(height: 10),
          if (!_isComplete) ...[
            Text(
              '${_currentStep + 1}. ${phase.title}',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              phase.description,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ] else ...[
            Text(
              'Demo complete — all phases finished!',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.tv, size: 14, color: Colors.grey.shade500),
              const SizedBox(width: 4),
              Text(
                'Showing: ${displayPhase.title.split(':').last.trim()}',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_errorMessage != null) ...[
            _buildStatusBanner(
              icon: Icons.error_outline,
              message: _errorMessage!,
              color: Colors.red,
            ),
            const SizedBox(height: 8),
          ],
          if (_lastMessage != null && !_isRunning) ...[
            _buildStatusBanner(
              icon: Icons.check_circle_outline,
              message: _lastMessage!,
              color: Colors.green,
            ),
            const SizedBox(height: 8),
          ],
          SizedBox(
            width: double.infinity,
            child: _isComplete
                ? ElevatedButton.icon(
                    icon: const Icon(Icons.replay),
                    label: const Text('Reset to Run Again'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: _reset,
                  )
                : ElevatedButton.icon(
                    icon: _isRunning
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.play_arrow),
                    label: Text(
                      _isRunning
                          ? 'Running step ${_currentStep + 1}…'
                          : _errorMessage != null
                          ? 'Retry Step ${_currentStep + 1}'
                          : 'Run Step ${_currentStep + 1} of ${widget.phases.length}',
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: _isRunning ? null : _runCurrentStep,
                  ),
          ),
          if (!_isComplete && _currentStep > 0) ...[
            const SizedBox(height: 6),
            Text(
              'Progress saved — you can close and resume later.',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade500,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBanner({
    required IconData icon,
    required String message,
    required MaterialColor color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color.shade700),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 12, color: color.shade800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveScreen() {
    final widgetName = widget
        .phases[_displayedStep.clamp(0, widget.phases.length - 1)]
        .widgetName;
    return KeyedSubtree(
      key: ValueKey('$widgetName-$_screenVersion'),
      child: WidgetRegistry.getWidget(widgetName),
    );
  }
}
