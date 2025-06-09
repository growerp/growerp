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

import '../blocs/activity_bloc.dart';

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

  @override
  void initState() {
    super.initState();
    _commentsController.text = widget.timeEntry.comments ?? '';
    _hoursController.text =
        widget.timeEntry.hours != null ? widget.timeEntry.hours.toString() : '';
    activityBloc = context.read<ActivityBloc>();
  }

  @override
  Widget build(BuildContext context) {
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
                              '${widget.timeEntry.timeEntryId == null ? "Add" : "Update"} successfull',
                              Colors.green);
                          Navigator.of(context).pop();
                          break;
                        case ActivityBlocStatus.failure:
                          HelperFunctions.showMessage(
                              context, 'Error: ${state.message}', Colors.red);
                          break;
                        default:
                          const Text("????");
                      }
                    },
                    child: popUp(
                        context: context,
                        child: _showForm(),
                        title: 'Enter Time Entries',
                        height: 400,
                        width: 400)))));
  }

  Widget _showForm() {
    Future<void> selectDate(BuildContext context) async {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: _selectedDate,
        firstDate:
            CustomizableDateTime.current.subtract(const Duration(days: 31)),
        lastDate: CustomizableDateTime.current.add(const Duration(days: 356)),
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
            child: ListView(key: const Key('listView'), children: <Widget>[
              Center(
                  child: Text(
                      "TimeEntry${widget.timeEntry.timeEntryId == null ? "New" : "${widget.timeEntry.timeEntryId}"}",
                      style: const TextStyle(
                          fontSize: 10,
                          color: Colors.black,
                          fontWeight: FontWeight.bold))),
              const SizedBox(height: 30),
              Row(children: [
                Expanded(
                    child: Center(
                        child: Text(
                  "${_selectedDate.toLocal()}".split(' ')[0],
                  key: const Key('date'),
                ))),
                SizedBox(
                    width: 100,
                    child: OutlinedButton(
                      key: const Key('setDate'),
                      onPressed: () => selectDate(context),
                      child: const Text('Update\n date'),
                    )),
              ]),
              const SizedBox(height: 20),
              TextFormField(
                key: const Key('hours'),
                decoration: const InputDecoration(labelText: '# hours'),
                controller: _hoursController,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter a number of hours?';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                key: const Key('comments'),
                decoration: const InputDecoration(labelText: 'Comments'),
                controller: _commentsController,
              ),
              const SizedBox(height: 30),
              OutlinedButton(
                  key: const Key('update'),
                  child: Text(widget.timeEntry.timeEntryId == null
                      ? 'Create'
                      : 'Update'),
                  onPressed: () async {
                    activityBloc.add(ActivityTimeEntryUpdate(TimeEntry(
                      date: _selectedDate,
                      hours: Decimal.parse(_hoursController.text),
                      activityId: widget.timeEntry.activityId,
                      partyId: context
                          .read<AuthBloc>()
                          .state
                          .authenticate!
                          .user!
                          .partyId!,
                    )));
                    Navigator.of(context).pop();
                  })
            ])));
  }
}
