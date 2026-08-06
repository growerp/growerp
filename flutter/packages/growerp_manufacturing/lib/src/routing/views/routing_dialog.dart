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
import 'package:growerp_manufacturing/l10n/generated/manufacturing_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../routing.dart';

class RoutingDialog extends StatefulWidget {
  final Routing routing;
  const RoutingDialog(this.routing, {super.key});
  @override
  RoutingDialogState createState() => RoutingDialogState();
}

class RoutingDialogState extends State<RoutingDialog> {
  late Routing routing;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _savingRouting = false;

  @override
  void initState() {
    super.initState();
    routing = widget.routing;
    _nameController.text = routing.routingName ?? '';
    _descriptionController.text = routing.description ?? '';
  }

  @override
  Widget build(BuildContext context) {
    bool isPhone = ResponsiveBreakpoints.of(context).isMobile;
    return Dialog(
      key: const Key('RoutingDialog'),
      insetPadding: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: BlocListener<RoutingBloc, RoutingState>(
        listener: (context, state) {
          switch (state.status) {
            case RoutingStatus.success:
              if (_savingRouting) {
                HelperFunctions.showMessage(
                  context,
                  routing.routingId.isEmpty
                      ? 'Add successful'
                      : 'Update successful',
                  Colors.green,
                );
                Navigator.of(context).pop();
              } else {
                // Task operation completed — refresh local routing from state
                final updated = state.routings.firstWhere(
                  (r) => r.routingId == routing.routingId,
                  orElse: () => routing,
                );
                setState(() => routing = updated);
              }
              break;
            case RoutingStatus.failure:
              _savingRouting = false;
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
          title: 'Routing ${routing.routingId.isEmpty ? 'New' : routing.routingId.lastChar(6)}',
          height: 600,
          width: 600,
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
            key: const Key('routingName'),
            decoration: const InputDecoration(labelText: 'Routing Name'),
            controller: _nameController,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a routing name';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          TextFormField(
            key: const Key('description'),
            decoration:
                const InputDecoration(labelText: 'Description (optional)'),
            controller: _descriptionController,
            maxLines: 2,
          ),
          const SizedBox(height: 20),
          // Routing tasks (existing routings only)
          if (routing.routingId.isNotEmpty) ...[
            const Text(
              'Routing Steps:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...routing.routingTasks.asMap().entries.map((entry) {
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
                    IconButton(
                      key: Key('deleteTaskItem$i'),
                      icon: const Icon(Icons.delete, size: 18),
                      onPressed: () => context
                          .read<RoutingBloc>()
                          .add(RoutingTaskDelete(task)),
                    ),
                  ],
                ),
                onTap: () => showDialog(
                  context: context,
                  builder: (_) => BlocProvider.value(
                    value: context.read<RoutingBloc>(),
                    child: RoutingTaskDialog(task),
                  ),
                ),
              );
            }),
            TextButton.icon(
              key: const Key('addTask'),
              icon: const Icon(Icons.add),
              label: Text(ManufacturingLocalizations.of(context)!.addStepButton),
              onPressed: () => showDialog(
                context: context,
                builder: (_) => BlocProvider.value(
                  value: context.read<RoutingBloc>(),
                  child: RoutingTaskDialog(
                    RoutingTask(routingId: routing.routingId),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          ElevatedButton(
            key: const Key('update'),
            child: Text(routing.routingId.isEmpty ? 'Add' : 'Update'),
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                _savingRouting = true;
                context.read<RoutingBloc>().add(
                      RoutingUpdate(
                        Routing(
                          routingId: routing.routingId,
                          routingName: _nameController.text,
                          description: _descriptionController.text.isNotEmpty
                              ? _descriptionController.text
                              : null,
                        ),
                      ),
                    );
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
