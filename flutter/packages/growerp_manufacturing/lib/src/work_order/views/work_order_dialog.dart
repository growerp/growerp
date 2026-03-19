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

class WorkOrderDialog extends StatefulWidget {
  final WorkOrder workOrder;
  const WorkOrderDialog(this.workOrder, {super.key});
  @override
  WorkOrderDialogState createState() => WorkOrderDialogState();
}

class WorkOrderDialogState extends State<WorkOrderDialog> {
  late WorkOrder workOrder;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _productIdController = TextEditingController();
  final _quantityController = TextEditingController();
  final _startDateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    workOrder = widget.workOrder;
    _nameController.text = workOrder.workEffortName ?? '';
    _productIdController.text = workOrder.productPseudoId ?? '';
    _quantityController.text = workOrder.estimatedQuantity?.toString() ?? '';
    _startDateController.text = workOrder.estimatedStartDate ?? '';
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
          height: 600,
          width: 500,
        ),
      ),
    );
  }

  Widget _showForm(bool isPhone) {
    return Center(
      child: Form(
        key: _formKey,
        child: ListView(
          key: const Key('listView'),
          children: <Widget>[
            TextFormField(
              key: const Key('name'),
              decoration:
                  const InputDecoration(labelText: 'Work Order Name (optional)'),
              controller: _nameController,
            ),
            const SizedBox(height: 20),
            TextFormField(
              key: const Key('productId'),
              decoration:
                  const InputDecoration(labelText: 'Product ID (to produce)'),
              controller: _productIdController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a product ID';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            TextFormField(
              key: const Key('quantity'),
              decoration: const InputDecoration(labelText: 'Quantity'),
              controller: _quantityController,
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
            ),
            const SizedBox(height: 20),
            // Status display and lifecycle buttons (existing orders only)
            if (workOrder.workEffortId.isNotEmpty) ...[
              Text(
                key: const Key('statusLabel'),
                'Status: ${workOrder.statusId ?? 'WeInPlanning'}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (workOrder.statusId == null ||
                  workOrder.statusId == 'WeInPlanning')
                ElevatedButton(
                  key: const Key('releaseButton'),
                  child: const Text('Release to Shop Floor'),
                  onPressed: () => context.read<WorkOrderBloc>().add(
                        WorkOrderUpdate(
                          workOrder.copyWith(statusId: 'WeApproved'),
                        ),
                      ),
                ),
              if (workOrder.statusId == 'WeApproved')
                ElevatedButton(
                  key: const Key('startButton'),
                  child: const Text('Start Production'),
                  onPressed: () => context.read<WorkOrderBloc>().add(
                        WorkOrderUpdate(
                          workOrder.copyWith(statusId: 'WeInProgress'),
                        ),
                      ),
                ),
              if (workOrder.statusId == 'WeInProgress')
                ElevatedButton(
                  key: const Key('completeButton'),
                  child: const Text('Complete Production'),
                  onPressed: () => context.read<WorkOrderBloc>().add(
                        WorkOrderUpdate(
                          workOrder.copyWith(statusId: 'WeComplete'),
                        ),
                      ),
                ),
              const SizedBox(height: 20),
            ],
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
                final isComplete = workOrder.statusId == 'WeComplete';
                return ListTile(
                  dense: true,
                  title: Text(item.componentName ?? item.componentPseudoId),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Need: $needed'),
                      if (available != null) ...[
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
                          'Cost: ${item.totalCost}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ],
                  ),
                );
              }),
              if (workOrder.statusId == 'WeComplete' &&
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
                        workOrder.totalCost.toString(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),
            ],
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
                        productPseudoId: _productIdController.text,
                        productId: workOrder.productId,
                        estimatedQuantity:
                            Decimal.tryParse(_quantityController.text),
                        estimatedStartDate:
                            _startDateController.text.isNotEmpty
                                ? _startDateController.text
                                : null,
                      ),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _productIdController.dispose();
    _quantityController.dispose();
    _startDateController.dispose();
    super.dispose();
  }
}
