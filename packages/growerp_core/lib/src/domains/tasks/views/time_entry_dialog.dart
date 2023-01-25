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

import '../../common/functions/helper_functions.dart';
import '../../../extensions.dart';
import '../../domains.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:responsive_framework/responsive_wrapper.dart';

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

  @override
  void initState() {
    super.initState();
    _commentsController.text = widget.timeEntry.comments ?? '';
    _hoursController.text =
        widget.timeEntry.hours != null ? widget.timeEntry.hours.toString() : '';
  }

  @override
  Widget build(BuildContext context) {
    bool isPhone = ResponsiveWrapper.of(context).isSmallerThan(TABLET);
    return GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Scaffold(
            backgroundColor: Colors.transparent,
            body: GestureDetector(
                onTap: () {},
                child: Dialog(
                    key: const Key('TimeEntryDialog'),
                    insetPadding: const EdgeInsets.all(10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: BlocListener<TaskBloc, TaskState>(
                        listener: (context, state) async {
                          switch (state.status) {
                            case TaskStatus.success:
                              HelperFunctions.showMessage(
                                  context,
                                  '${widget.timeEntry.timeEntryId == null ? "Add" : "Update"} successfull',
                                  Colors.green);
                              await Future.delayed(
                                  const Duration(milliseconds: 500));
                              if (!mounted) return;
                              Navigator.of(context).pop();
                              break;
                            case TaskStatus.failure:
                              HelperFunctions.showMessage(context,
                                  'Error: ${state.message}', Colors.red);
                              break;
                            default:
                              const Text("????");
                          }
                        },
                        child: Stack(clipBehavior: Clip.none, children: [
                          Container(
                              padding: const EdgeInsets.all(20),
                              width: 400,
                              height: 400,
                              child: Center(
                                child: _showForm(isPhone),
                              )),
                          const Positioned(
                              top: 10, right: 10, child: DialogCloseButton())
                        ]))))));
  }

  Widget _showForm(isPhone) {
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
                    child: ElevatedButton(
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
              ElevatedButton(
                  key: const Key('update'),
                  child: Text(widget.timeEntry.timeEntryId == null
                      ? 'Create'
                      : 'Update'),
                  onPressed: () async {
                    context.read<TaskBloc>().add(TaskTimeEntryUpdate(TimeEntry(
                          date: _selectedDate,
                          hours: Decimal.parse(_hoursController.text),
                          taskId: widget.timeEntry.taskId,
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
