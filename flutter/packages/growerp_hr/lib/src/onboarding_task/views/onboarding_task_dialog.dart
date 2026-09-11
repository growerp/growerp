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
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../../growerp_hr.dart';

class OnboardingTaskDialog extends StatefulWidget {
  final OnboardingTask onboardingTask;
  const OnboardingTaskDialog(this.onboardingTask, {super.key});
  @override
  OnboardingTaskDialogState createState() => OnboardingTaskDialogState();
}

class OnboardingTaskDialogState extends State<OnboardingTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _sequenceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _descriptionController.text = widget.onboardingTask.description;
    _sequenceController.text = widget.onboardingTask.sequenceNum.toString();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = HrLocalizations.of(context)!;
    final isPhone = ResponsiveBreakpoints.of(context).isMobile;
    final isNew = widget.onboardingTask.onboardingTaskId.isEmpty;
    return Dialog(
      key: const Key('OnboardingTaskDialog'),
      insetPadding: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: BlocListener<OnboardingTaskBloc, OnboardingTaskState>(
        listener: (context, state) {
          switch (state.status) {
            case OnboardingTaskStatus.success:
              HelperFunctions.showMessage(
                context,
                isNew ? localizations.addSuccess : localizations.updateSuccess,
                Colors.green,
              );
              Navigator.of(context).pop();
            case OnboardingTaskStatus.failure:
              HelperFunctions.showMessage(context, state.message, Colors.red);
            default:
          }
        },
        child: popUp(
          context: context,
          title: isNew
              ? localizations.newOnboardingTask
              : localizations.onboardingTask,
          height: 350,
          width: isPhone ? 400 : 450,
          child: Center(
            child: Form(
              key: _formKey,
              child: ListView(
                key: const Key('listView'),
                children: <Widget>[
                  TextFormField(
                    key: const Key('description'),
                    decoration: InputDecoration(
                      labelText: localizations.description,
                    ),
                    controller: _descriptionController,
                    validator: (value) => value == null || value.isEmpty
                        ? '${localizations.description}?'
                        : null,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    key: const Key('sequenceNum'),
                    decoration: InputDecoration(
                      labelText: localizations.sequence,
                    ),
                    controller: _sequenceController,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    key: const Key('update'),
                    child: Text(
                      isNew ? localizations.add : localizations.update,
                    ),
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        context.read<OnboardingTaskBloc>().add(
                          OnboardingTaskUpdate(
                            widget.onboardingTask.copyWith(
                              description: _descriptionController.text,
                              sequenceNum:
                                  int.tryParse(_sequenceController.text) ?? 0,
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
        ),
      ),
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _sequenceController.dispose();
    super.dispose();
  }
}
