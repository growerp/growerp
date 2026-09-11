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

class JobTitleDialog extends StatefulWidget {
  final JobTitle jobTitle;
  const JobTitleDialog(this.jobTitle, {super.key});
  @override
  JobTitleDialogState createState() => JobTitleDialogState();
}

class JobTitleDialogState extends State<JobTitleDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.jobTitle.title;
    _descriptionController.text = widget.jobTitle.description ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final localizations = HrLocalizations.of(context)!;
    final isPhone = ResponsiveBreakpoints.of(context).isMobile;
    final isNew = widget.jobTitle.jobTitleId.isEmpty;
    return Dialog(
      key: const Key('JobTitleDialog'),
      insetPadding: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: BlocListener<JobTitleBloc, JobTitleState>(
        listener: (context, state) {
          switch (state.status) {
            case JobTitleStatus.success:
              HelperFunctions.showMessage(
                context,
                isNew ? localizations.addSuccess : localizations.updateSuccess,
                Colors.green,
              );
              Navigator.of(context).pop();
            case JobTitleStatus.failure:
              HelperFunctions.showMessage(context, state.message, Colors.red);
            default:
          }
        },
        child: popUp(
          context: context,
          title: isNew
              ? localizations.newJobTitle
              : '${localizations.jobTitle}: ${widget.jobTitle.title}',
          height: 350,
          width: isPhone ? 400 : 450,
          child: Center(
            child: Form(
              key: _formKey,
              child: ListView(
                key: const Key('listView'),
                children: <Widget>[
                  TextFormField(
                    key: const Key('title'),
                    decoration: InputDecoration(labelText: localizations.title),
                    controller: _titleController,
                    validator: (value) => value == null || value.isEmpty
                        ? '${localizations.title}?'
                        : null,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    key: const Key('description'),
                    decoration: InputDecoration(
                      labelText: localizations.description,
                    ),
                    controller: _descriptionController,
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    key: const Key('update'),
                    child: Text(
                      isNew ? localizations.add : localizations.update,
                    ),
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        context.read<JobTitleBloc>().add(
                          JobTitleUpdate(
                            widget.jobTitle.copyWith(
                              title: _titleController.text,
                              description: _descriptionController.text,
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
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
