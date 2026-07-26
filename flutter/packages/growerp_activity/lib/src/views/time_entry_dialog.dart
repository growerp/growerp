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
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

import '../../growerp_activity.dart';

class TimeEntryDialog extends StatefulWidget {
  final TimeEntry timeEntry;
  const TimeEntryDialog(this.timeEntry, {super.key});
  @override
  TimeEntryDialogState createState() => TimeEntryDialogState();
}

class TimeEntryDialogState extends State<TimeEntryDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _commentsController = TextEditingController();
  final TextEditingController _hoursController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  late ActivityBloc activityBloc;
  late ActivityLocalizations _localizations;

  @override
  void initState() {
    super.initState();
    _commentsController.text = widget.timeEntry.comments ?? '';
    _hoursController.text = widget.timeEntry.hours != null
        ? widget.timeEntry.hours.toString()
        : '';
    activityBloc = context.read<ActivityBloc>();
  }

  @override
  Widget build(BuildContext context) {
    _localizations = ActivityLocalizations.of(context)!;
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: GestureDetector(
        onTap: () {},
        child: Dialog(
          key: const Key('TimeEntryDialog'),
          insetPadding: const EdgeInsets.all(10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: BlocListener<ActivityBloc, ActivityState>(
            listener: (context, state) async {
              switch (state.status) {
                case ActivityBlocStatus.success:
                  HelperFunctions.showMessage(
                    context,
                    widget.timeEntry.timeEntryId == null
                        ? _localizations.timeEntry_addSuccess
                        : _localizations.timeEntry_updateSuccess,
                    Colors.green,
                  );
                  Navigator.of(context).pop();
                  break;
                case ActivityBlocStatus.failure:
                  HelperFunctions.showMessage(
                    context,
                    _localizations.activity_error(state.message ?? 'unknown'),
                    Colors.red,
                  );
                  break;
                default:
                  const Text("????");
              }
            },
            child: popUp(
              context: context,
              child: _showForm(),
              title: _localizations.timeEntry_title,
              height: 400,
              width: 400,
            ),
          ),
        ),
      ),
    );
  }

  Widget _showForm() {
    Future<void> selectDate(BuildContext context) async {
      // Get locale from LocaleBloc to respect user's language selection
      final localeState = context.read<LocaleBloc>().state;

      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: _selectedDate,
        firstDate: CustomizableDateTime.current.subtract(
          const Duration(days: 31),
        ),
        lastDate: CustomizableDateTime.current.add(const Duration(days: 356)),
        locale: localeState.locale,
      );
      if (picked != null && picked != _selectedDate) {
        setState(() {
          _selectedDate = picked;
        });
      }
    }

    return Center(
      child: Form(
        key: _formKey,
        child: ListView(
          key: const Key('listView'),
          children: <Widget>[
            Center(
              child: Text(
                widget.timeEntry.timeEntryId == null
                    ? _localizations.timeEntry_new
                    : _localizations.timeEntry_id(
                        widget.timeEntry.timeEntryId!,
                      ),
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(
                  child: Center(
                    child: Text(
                      "${_selectedDate.toLocal()}".split(' ')[0],
                      key: const Key('date'),
                    ),
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: OutlinedButton(
                    key: const Key('setDate'),
                    onPressed: () => selectDate(context),
                    child: Text(_localizations.timeEntry_updateDate),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextFormField(
              key: const Key('hours'),
              decoration: InputDecoration(
                labelText: _localizations.timeEntry_hours,
              ),
              controller: _hoursController,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value!.isEmpty) {
                  return _localizations.timeEntry_hoursError;
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            TextFormField(
              key: const Key('comments'),
              decoration: InputDecoration(
                labelText: _localizations.timeEntry_comments,
              ),
              controller: _commentsController,
            ),
            const SizedBox(height: 30),
            OutlinedButton(
              key: const Key('update'),
              child: Text(
                widget.timeEntry.timeEntryId == null
                    ? _localizations.activity_create
                    : _localizations.activity_update,
              ),
              onPressed: () async {
                activityBloc.add(
                  ActivityTimeEntryUpdate(
                    TimeEntry(
                      timeEntryId: widget.timeEntry.timeEntryId,
                      date: _selectedDate,
                      hours: Decimal.parse(_hoursController.text),
                      comments: _commentsController.text,
                      activityId: widget.timeEntry.activityId,
                      partyId:
                          widget.timeEntry.partyId ??
                          context
                              .read<AuthBloc>()
                              .state
                              .authenticate!
                              .user!
                              .partyId!,
                    ),
                  ),
                );
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}
