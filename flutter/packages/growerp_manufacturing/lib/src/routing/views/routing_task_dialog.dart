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

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:growerp_manufacturing/l10n/generated/manufacturing_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../routing.dart';

class RoutingTaskDialog extends StatefulWidget {
  final RoutingTask routingTask;
  const RoutingTaskDialog(this.routingTask, {super.key});
  @override
  RoutingTaskDialogState createState() => RoutingTaskDialogState();
}

class RoutingTaskDialogState extends State<RoutingTaskDialog> {
  late RoutingTask routingTask;
  final _formKey = GlobalKey<FormState>();
  final _taskNameController = TextEditingController();
  final _sequenceNumController = TextEditingController();
  final _estimatedWorkTimeController = TextEditingController();
  final _workCenterNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    routingTask = widget.routingTask;
    _taskNameController.text = routingTask.taskName ?? '';
    _sequenceNumController.text = routingTask.sequenceNum?.toString() ?? '';
    _estimatedWorkTimeController.text =
        routingTask.estimatedWorkTime?.toString() ?? '';
    _workCenterNameController.text = routingTask.workCenterName ?? '';
  }

  @override
  Widget build(BuildContext context) {
    bool isPhone = ResponsiveBreakpoints.of(context).isMobile;
    return Dialog(
      key: const Key('RoutingTaskDialog'),
      insetPadding: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: BlocListener<RoutingBloc, RoutingState>(
        listener: (context, state) {
          switch (state.status) {
            case RoutingStatus.success:
              Navigator.of(context).pop();
              break;
            case RoutingStatus.failure:
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
          title: routingTask.routingTaskId.isEmpty
              ? 'New Routing Step'
              : 'Edit Routing Step',
          height: 420,
          width: 450,
        ),
      ),
    );
  }

  Widget _showForm(bool isPhone) {
    return Form(
      key: _formKey,
      child: ListView(
        key: const Key('listView'),
        children: <Widget>[
          TextFormField(
            key: const Key('taskName'),
            decoration: const InputDecoration(labelText: 'Step Name'),
            controller: _taskNameController,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a step name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            key: const Key('sequenceNum'),
            decoration: const InputDecoration(labelText: 'Sequence No. (optional)'),
            controller: _sequenceNumController,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          TextFormField(
            key: const Key('estimatedWorkTime'),
            decoration: const InputDecoration(labelText: 'Est. Hours (optional)'),
            controller: _estimatedWorkTimeController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 16),
          TextFormField(
            key: const Key('workCenterName'),
            decoration: const InputDecoration(labelText: 'Work Center (optional)'),
            controller: _workCenterNameController,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              if (routingTask.routingTaskId.isNotEmpty) ...[
                Expanded(
                  child: ElevatedButton(
                    key: const Key('delete'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red),
                    child: Text(ManufacturingLocalizations.of(context)!.deleteButton),
                    onPressed: () {
                      context
                          .read<RoutingBloc>()
                          .add(RoutingTaskDelete(routingTask));
                    },
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: ElevatedButton(
                  key: const Key('update'),
                  child: Text(
                      routingTask.routingTaskId.isEmpty ? 'Add' : 'Update'),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      context.read<RoutingBloc>().add(
                            RoutingTaskUpdate(
                              RoutingTask(
                                routingTaskId: routingTask.routingTaskId,
                                routingId: routingTask.routingId,
                                taskName: _taskNameController.text,
                                sequenceNum: _sequenceNumController
                                        .text.isNotEmpty
                                    ? int.tryParse(_sequenceNumController.text)
                                    : null,
                                estimatedWorkTime: _estimatedWorkTimeController
                                        .text.isNotEmpty
                                    ? Decimal.tryParse(
                                        _estimatedWorkTimeController.text)
                                    : null,
                                workCenterName:
                                    _workCenterNameController.text.isNotEmpty
                                        ? _workCenterNameController.text
                                        : null,
                              ),
                            ),
                          );
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _taskNameController.dispose();
    _sequenceNumController.dispose();
    _estimatedWorkTimeController.dispose();
    _workCenterNameController.dispose();
    super.dispose();
  }
}
