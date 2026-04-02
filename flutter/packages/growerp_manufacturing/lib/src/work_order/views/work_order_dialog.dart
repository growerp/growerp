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

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../work_order.dart';
import '../../routing/routing.dart';

class WorkOrderDialog extends StatefulWidget {
  final WorkOrder workOrder;
  /// Optional extra widgets injected by a higher-level package (e.g. growerp_manuf_liner).
  final List<Widget> Function(WorkOrder workOrder)? extraTabBuilder;
  /// Optional extra action buttons injected by a higher-level package (e.g. print button).
  final List<Widget> Function(WorkOrder workOrder)? extraActionBuilder;
  const WorkOrderDialog(
    this.workOrder, {
    super.key,
    this.extraTabBuilder,
    this.extraActionBuilder,
  });
  @override
  WorkOrderDialogState createState() => WorkOrderDialogState();
}

class WorkOrderDialogState extends State<WorkOrderDialog> {
  late WorkOrder workOrder;
  late RestClient _restClient;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  Bom? _selectedBom;
  final _quantityController = TextEditingController();
  final _startDateController = TextEditingController();
  String? _selectedRoutingId;

  @override
  void initState() {
    super.initState();
    workOrder = widget.workOrder;
    _restClient = context.read<WorkOrderBloc>().restClient;
    _nameController.text = workOrder.workEffortName ?? '';
    if (workOrder.productId.isNotEmpty) {
      _selectedBom = Bom(
        productId: workOrder.productId,
        productPseudoId: workOrder.productPseudoId ?? '',
        productName: workOrder.productName,
      );
    }
    _quantityController.text = workOrder.estimatedQuantity?.toString() ?? '';
    _startDateController.text = workOrder.estimatedStartDate ?? '';
    _selectedRoutingId = workOrder.routingId;
    // Fetch routings so dropdown is populated
    context.read<RoutingBloc>().add(const RoutingsFetch(refresh: true));
  }

  @override
  Widget build(BuildContext context) {
    bool isPhone = ResponsiveBreakpoints.of(context).isMobile;
    return Dialog(
      key: const Key('WorkOrderDialog'),
      insetPadding: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: BlocListener<WorkOrderBloc, WorkOrderState>(
        listener: (context, state) async {
          switch (state.status) {
            case WorkOrderStatus.success:
              HelperFunctions.showMessage(
                context,
                workOrder.workEffortId.isEmpty
                    ? 'Add successful'
                    : 'Update successful',
                Colors.green,
              );
              Navigator.of(context).pop();
              break;
            case WorkOrderStatus.failure:
              HelperFunctions.showMessage(
                context,
                'Error: ${state.message ?? ''}',
                Colors.red,
              );
              break;
            default:
              break;
          }
        },
        child: popUp(
          context: context,
          child: _showForm(isPhone),
          title:
              'Work Order ${workOrder.pseudoId.isEmpty ? 'New' : workOrder.pseudoId}',
          height: 650,
          width: 500,
        ),
      ),
    );
  }

  Widget _showForm(bool isPhone) {
    final isComplete = workOrder.status == WorkOrderStatusVal.complete;
    final currencyId = context
        .read<AuthBloc>()
        .state
        .authenticate!
        .company!
        .currency!
        .currencyId!;
    return Center(
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          key: const Key('listView'),
          child: Column(
            children: <Widget>[
            TextFormField(
              key: const Key('name'),
              decoration:
                  const InputDecoration(labelText: 'Work Order Name (optional)'),
              controller: _nameController,
              readOnly: isComplete,
            ),
            const SizedBox(height: 20),
            AutocompleteLabel<Bom>(
              key: const Key('productId'),
              label: 'Product (with BOM)',
              initialValue: _selectedBom,
              readOnly: isComplete,
              optionsBuilder: (TextEditingValue v) async {
                final r = await _restClient.getBoms(
                  search: v.text,
                  limit: 5,
                );
                return r.boms;
              },
              displayStringForOption: (b) =>
                  '${b.productPseudoId}  ${b.productName ?? ''}',
              onSelected: (Bom? b) => setState(() => _selectedBom = b),
              validator: (value) =>
                  _selectedBom == null ? 'Please select a product' : null,
            ),
            const SizedBox(height: 20),
            TextFormField(
              key: const Key('quantity'),
              decoration: const InputDecoration(labelText: 'Quantity'),
              controller: _quantityController,
              readOnly: isComplete,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a quantity';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            TextFormField(
              key: const Key('startDate'),
              decoration:
                  const InputDecoration(labelText: 'Start Date (YYYY-MM-DD)'),
              controller: _startDateController,
              readOnly: isComplete,
            ),
            const SizedBox(height: 20),
            // Routing dropdown + inline routing steps
            BlocBuilder<RoutingBloc, RoutingState>(
              builder: (context, routingState) {
                final routings = routingState.routings;
                final selectedRouting = _selectedRoutingId != null
                    ? routings.cast<Routing?>().firstWhere(
                        (r) => r?.routingId == _selectedRoutingId,
                        orElse: () => null)
                    : null;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<String>(
                      key: const Key('routingDropdown'),
                      decoration: const InputDecoration(
                        labelText: 'Production Routing (optional)',
                      ),
                      initialValue: routings.any(
                              (r) => r.routingId == _selectedRoutingId)
                          ? _selectedRoutingId
                          : null,
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('— None —'),
                        ),
                        ...routings.map((r) => DropdownMenuItem<String>(
                              value: r.routingId,
                              child: Text(r.routingName ?? r.routingId),
                            )),
                      ],
                      onChanged: isComplete
                          ? null
                          : (value) =>
                              setState(() => _selectedRoutingId = value),
                    ),
                    if (selectedRouting != null) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Routing Steps:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      ...selectedRouting.routingTasks.asMap().entries.map((entry) {
                        final i = entry.key;
                        final task = entry.value;
                        return ListTile(
                          key: Key('taskItem$i'),
                          dense: true,
                          leading: CircleAvatar(
                            radius: 14,
                            child: Text('${task.sequenceNum ?? '?'}'),
                          ),
                          title: Text(
                            task.taskName ?? '',
                            key: Key('taskItemName$i'),
                          ),
                          subtitle: task.workCenterName != null
                              ? Text(task.workCenterName!)
                              : null,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (task.estimatedWorkTime != null)
                                Text('${task.estimatedWorkTime}h'),
                              if (!isComplete)
                                IconButton(
                                  key: Key('deleteTaskItem$i'),
                                  icon: const Icon(Icons.delete, size: 18),
                                  onPressed: () => context
                                      .read<RoutingBloc>()
                                      .add(RoutingTaskDelete(task)),
                                ),
                            ],
                          ),
                          onTap: isComplete
                              ? null
                              : () => showDialog(
                                    context: context,
                                    builder: (_) => BlocProvider.value(
                                      value: context.read<RoutingBloc>(),
                                      child: RoutingTaskDialog(task),
                                    ),
                                  ),
                        );
                      }),
                      if (!isComplete)
                        TextButton.icon(
                          key: const Key('addRoutingTask'),
                          icon: const Icon(Icons.add),
                          label: const Text('Add Step'),
                          onPressed: () => showDialog(
                            context: context,
                            builder: (_) => BlocProvider.value(
                              value: context.read<RoutingBloc>(),
                              child: RoutingTaskDialog(
                                RoutingTask(
                                    routingId: selectedRouting.routingId),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            // BOM components with shortage indicators
            if (workOrder.workEffortId.isNotEmpty &&
                workOrder.bomItems.isNotEmpty) ...[
              const Text(
                'BOM Components:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...workOrder.bomItems.map((item) {
                final needed = item.quantity ?? Decimal.one;
                final available = item.availableQuantity;
                final hasShortage =
                    available != null && available < needed;
                return ListTile(
                  dense: true,
                  title: Text(item.componentName ?? item.componentPseudoId),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Need: $needed'),
                      if (available != null && !isComplete) ...[
                        const SizedBox(width: 8),
                        Text(
                          key: Key('have${item.componentPseudoId}'),
                          'Have: $available',
                          style: TextStyle(
                            color: hasShortage ? Colors.red : Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (hasShortage)
                          const Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: Icon(Icons.warning,
                                color: Colors.red, size: 16),
                          ),
                      ],
                      if (isComplete && item.unitCost != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          key: Key('cost${item.componentPseudoId}'),
                          'Cost: ${item.totalCost.currency(currencyId: currencyId)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ],
                  ),
                );
              }),
              if (workOrder.status == WorkOrderStatusVal.complete &&
                  workOrder.totalCost != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Text(
                        'Total Production Cost: ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        key: const Key('totalProductionCost'),
                        workOrder.totalCost.currency(currencyId: currencyId),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),
            ],
            // Extra widgets injected by higher-level package
            if (workOrder.workEffortId.isNotEmpty &&
                widget.extraTabBuilder != null) ...[
              ...widget.extraTabBuilder!(workOrder),
              const SizedBox(height: 20),
            ],
            // Extra action buttons (e.g. Print)
            if (workOrder.workEffortId.isNotEmpty &&
                widget.extraActionBuilder != null) ...[
              ...widget.extraActionBuilder!(workOrder),
              const SizedBox(height: 20),
            ],
            // Status display and lifecycle buttons — placed after panels so
            // scrolling to these buttons is not obscured by the list above
            if (workOrder.workEffortId.isNotEmpty) ...[
              Text(
                key: const Key('statusLabel'),
                'Status: ${workOrder.status?.name ?? WorkOrderStatusVal.inPlanning.name}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (workOrder.status == null ||
                  workOrder.status == WorkOrderStatusVal.inPlanning)
                ElevatedButton(
                  key: const Key('releaseButton'),
                  child: const Text('Release to Shop Floor'),
                  onPressed: () => context.read<WorkOrderBloc>().add(
                        WorkOrderUpdate(
                          workOrder.copyWith(
                              status: WorkOrderStatusVal.approved),
                        ),
                      ),
                ),
              if (workOrder.status == WorkOrderStatusVal.approved)
                ElevatedButton(
                  key: const Key('startButton'),
                  child: const Text('Start Production'),
                  onPressed: () => context.read<WorkOrderBloc>().add(
                        WorkOrderUpdate(
                          workOrder.copyWith(
                              status: WorkOrderStatusVal.inProgress),
                        ),
                      ),
                ),
              if (workOrder.status == WorkOrderStatusVal.inProgress)
                ElevatedButton(
                  key: const Key('completeButton'),
                  child: const Text('Complete Production'),
                  onPressed: () => context.read<WorkOrderBloc>().add(
                        WorkOrderUpdate(
                          workOrder.copyWith(
                              status: WorkOrderStatusVal.complete),
                        ),
                      ),
                ),
              const SizedBox(height: 20),
            ],
            if (!isComplete)
            ElevatedButton(
              key: const Key('update'),
              child: Text(workOrder.workEffortId.isEmpty ? 'Add' : 'Update'),
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  context.read<WorkOrderBloc>().add(
                    WorkOrderUpdate(
                      WorkOrder(
                        workEffortId: workOrder.workEffortId,
                        workEffortName: _nameController.text.isNotEmpty
                            ? _nameController.text
                            : null,
                        productPseudoId: _selectedBom?.productPseudoId ?? '',
                        productId: _selectedBom?.productId ?? workOrder.productId,
                        estimatedQuantity:
                            Decimal.tryParse(_quantityController.text),
                        estimatedStartDate:
                            _startDateController.text.isNotEmpty
                                ? _startDateController.text
                                : null,
                        routingId: _selectedRoutingId,
                      ),
                    ),
                  );
                }
              },
            ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _startDateController.dispose();
    super.dispose();
  }
}
