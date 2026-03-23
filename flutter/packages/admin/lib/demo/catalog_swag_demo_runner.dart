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

import 'catalog_swag_demo_service.dart';
import 'demo_progress_service.dart';

// ── Phase definitions ─────────────────────────────────────────────────────────

class _Phase {
  final String title;
  final String description;
  /// Widget name registered in WidgetRegistry — shown in the live screen panel.
  final String widgetName;
  final Future<String> Function(RestClient, String, String) action;

  const _Phase({
    required this.title,
    required this.description,
    required this.widgetName,
    required this.action,
  });
}

final List<_Phase> _phases = [
  _Phase(
    title: 'Setup: Create Demo Products & BOM',
    description:
        'Creates the Moqui Marketing Package (SWAG-PKG-001) and its three '
        'components (Baseball Cap, Coffee Mug, USB Drive) together with a '
        'Bill of Materials and demo customer/supplier companies. '
        'Skipped automatically if the data already exists.',
    widgetName: 'BomList',
    action: setupDemoData,
  ),
  _Phase(
    title: 'Create Sales Order',
    description:
        'A customer orders 2× Moqui Marketing Package. '
        'The order is saved in Created state so you can review it '
        'before approving.',
    widgetName: 'SalesOrderList',
    action: createSalesOrder,
  ),
  _Phase(
    title: 'Approve Sales Order',
    description:
        'Approving the sales order triggers the backend to automatically '
        'create a Work Order because the product has a Bill of Materials.',
    widgetName: 'SalesOrderList',
    action: approveSalesOrder,
  ),
  _Phase(
    title: 'View Work Order — Material Shortage',
    description:
        'The system created a Work Order for the 2 kits. '
        'It shows a material shortage for all three components '
        'because no swag items are in the warehouse yet.',
    widgetName: 'WorkOrderList',
    action: viewWorkOrder,
  ),
  _Phase(
    title: 'Order & Pay for Components',
    description:
        'A purchase order is raised for 3 each of Baseball Cap, Coffee Mug, '
        'and USB Drive. The order is approved and payment is processed.',
    widgetName: 'PurchaseOrderList',
    action: createAndApprovePurchaseOrder,
  ),
  _Phase(
    title: 'Receive Components into Warehouse',
    description:
        'The incoming shipment from the supplier is received. '
        'Caps, mugs, and USB drives are now in stock and the Work Order '
        'shortage is cleared.',
    widgetName: 'IncomingShipmentList',
    action: receiveIncomingShipment,
  ),
  _Phase(
    title: 'Assemble the Kits',
    description:
        'The Work Order is released, started, and completed. '
        'Components are consumed and 2× Moqui Marketing Package '
        'are added to finished-goods inventory.',
    widgetName: 'WorkOrderList',
    action: completeWorkOrder,
  ),
  _Phase(
    title: 'Ship to Customer & Collect Payment',
    description:
        'The finished kits are shipped to the customer. '
        'The outgoing shipment is approved, completed, and '
        'customer payment is collected.',
    widgetName: 'OutgoingShipmentList',
    action: shipToCustomerAndCollectPayment,
  ),
  _Phase(
    title: 'Update Statistics & Ledger Totals',
    description:
        'Runs the ledger recalculation and statistics update jobs for this '
        'company. Dashboard numbers, balance sheet totals, and GL account '
        'summaries are refreshed to reflect all completed transactions.',
    widgetName: 'TransactionList',
    action: updateStatsAndLedger,
  ),
];

// ── Widget ────────────────────────────────────────────────────────────────────

class CatalogSwagDemoRunner extends StatefulWidget {
  const CatalogSwagDemoRunner({super.key});

  @override
  State<CatalogSwagDemoRunner> createState() => _CatalogSwagDemoRunnerState();
}

class _CatalogSwagDemoRunnerState extends State<CatalogSwagDemoRunner> {
  /// The step that is next to run (0-based).
  int _currentStep = 0;

  /// The step whose screen is displayed in the live panel.
  /// Set to _currentStep when a step starts; stays there after completion
  /// so the user can see the newly created data before the next step.
  int _displayedStep = 0;

  /// Incremented after each step to force the embedded screen to reload.
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
    final step = await DemoProgressService.getCurrentStep(_ownerPartyId);
    if (mounted) {
      setState(() {
        _currentStep = step;
        _displayedStep = step.clamp(0, _phases.length - 1);
        _isComplete = step >= _phases.length;
        _screenVersion++;
      });
    }
  }

  Future<void> _runCurrentStep() async {
    if (_currentStep >= _phases.length) return;
    final phase = _phases[_currentStep];

    setState(() {
      _isRunning = true;
      _displayedStep = _currentStep; // Show this step's screen while it runs
      _screenVersion++;               // Force fresh load before the API call
      _errorMessage = null;
      _lastMessage = null;
    });

    try {
      final message =
          await phase.action(_restClient, _classificationId, _ownerPartyId);
      final nextStep = _currentStep + 1;
      await DemoProgressService.saveStep(nextStep, _ownerPartyId);

      if (mounted) {
        setState(() {
          _isRunning = false;
          _lastMessage = message;
          _currentStep = nextStep;
          _screenVersion++; // Reload the same screen to show created data
          _isComplete = nextStep >= _phases.length;
          // _displayedStep stays on the completed step so user sees the result
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
      await DemoProgressService.reset(_ownerPartyId);
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

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catalog & Manufacturing Demo'),
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
          // ── Control panel (top) ──────────────────────────────────────────
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.44,
            ),
            child: SingleChildScrollView(child: _buildControlPanel()),
          ),
          const Divider(height: 1, thickness: 1),
          // ── Live screen (bottom) ─────────────────────────────────────────
          Expanded(child: _buildLiveScreen()),
        ],
      ),
    );
  }

  // ── Control panel ──────────────────────────────────────────────────────────

  Widget _buildControlPanel() {
    final phase = _isComplete || _currentStep >= _phases.length
        ? _phases.last
        : _phases[_currentStep];
    final displayPhase = _phases[_displayedStep.clamp(0, _phases.length - 1)];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress row
          Row(
            children: [
              Text(
                _isComplete
                    ? 'All ${_phases.length} steps complete'
                    : 'Step ${_currentStep + 1} of ${_phases.length}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: LinearProgressIndicator(
                  value: _phases.isNotEmpty
                      ? (_isComplete ? 1.0 : _currentStep / _phases.length)
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

          // Current step title & description
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

          // Live screen label
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

          // Status messages
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

          // Action button
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
                          : 'Run Step ${_currentStep + 1} of ${_phases.length}',
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: _isRunning ? null : _runCurrentStep,
                  ),
          ),

          // Resume hint
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

  // ── Live screen ───────────────────────────────────────────────────────────

  Widget _buildLiveScreen() {
    final widgetName =
        _phases[_displayedStep.clamp(0, _phases.length - 1)].widgetName;
    return KeyedSubtree(
      // Key forces the widget to fully rebuild (= re-fetch data) when version changes.
      key: ValueKey('$widgetName-$_screenVersion'),
      child: WidgetRegistry.getWidget(widgetName),
    );
  }
}
