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
import '../../../../extensions.dart';
import '../../domains.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:responsive_framework/responsive_wrapper.dart';

class TimeEntryDialog extends StatefulWidget {
  final TimeEntry timeEntry;
  TimeEntryDialog(this.timeEntry);
  @override
  _TimeEntryState createState() => _TimeEntryState(timeEntry);
}

class _TimeEntryState extends State<TimeEntryDialog> {
  final TimeEntry timeEntry;
  final _formKey = GlobalKey<FormState>();
  TextEditingController _commentsController = TextEditingController();
  TextEditingController _hoursController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  _TimeEntryState(this.timeEntry);

  @override
  void initState() {
    super.initState();
    _commentsController.text = timeEntry.comments ?? '';
    _hoursController.text =
        timeEntry.hours != null ? timeEntry.hours.toString() : '';
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
                    key: Key('TimeEntryDialog'),
                    insetPadding: EdgeInsets.all(10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: BlocListener<TaskBloc, TaskState>(
                        listener: (context, state) async {
                          switch (state.status) {
                            case TaskStatus.success:
                              HelperFunctions.showMessage(
                                  context,
                                  '${timeEntry.timeEntryId == null ? "Add" : "Update"} successfull',
                                  Colors.green);
                              await Future.delayed(Duration(milliseconds: 500));
                              Navigator.of(context).pop();
                              break;
                            case TaskStatus.failure:
                              HelperFunctions.showMessage(context,
                                  'Error: ${state.message}', Colors.red);
                              break;
                            default:
                              Text("????");
                          }
                        },
                        child: Stack(clipBehavior: Clip.none, children: [
                          Container(
                              padding: EdgeInsets.all(20),
                              width: 400,
                              height: 400,
                              child: Center(
                                child: _showForm(isPhone),
                              )),
                          Positioned(
                              top: 10, right: 10, child: DialogCloseButton())
                        ]))))));
  }

  Widget _showForm(isPhone) {
    Future<void> _selectDate(BuildContext context) async {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: _selectedDate,
        firstDate: CustomizableDateTime.current.subtract(Duration(days: 31)),
        lastDate: CustomizableDateTime.current.add(Duration(days: 356)),
      );
      if (picked != null && picked != _selectedDate)
        setState(() {
          _selectedDate = picked;
        });
    }

    return Center(
        child: Container(
            child: Form(
                key: _formKey,
                child: ListView(key: Key('listView'), children: <Widget>[
                  Center(
                      child: Text(
                          "TimeEntry" +
                              (timeEntry.timeEntryId == null
                                  ? "New"
                                  : "${timeEntry.timeEntryId}"),
                          style: TextStyle(
                              fontSize: 10,
                              color: Colors.black,
                              fontWeight: FontWeight.bold))),
                  SizedBox(height: 30),
                  Row(children: [
                    Expanded(
                        child: Center(
                            child: Text(
                      "${_selectedDate.toLocal()}".split(' ')[0],
                      key: Key('date'),
                    ))),
                    SizedBox(
                        width: 100,
                        child: ElevatedButton(
                          key: Key('setDate'),
                          onPressed: () => _selectDate(context),
                          child: Text('Update\n date'),
                        )),
                  ]),
                  SizedBox(height: 20),
                  TextFormField(
                    key: Key('hours'),
                    decoration: InputDecoration(labelText: '# hours'),
                    controller: _hoursController,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value!.isEmpty)
                        return 'Please enter a number of hours?';
                      return null;
                    },
                  ),
                  SizedBox(height: 20),
                  TextFormField(
                    key: Key('comments'),
                    decoration: InputDecoration(labelText: 'Comments'),
                    controller: _commentsController,
                  ),
                  SizedBox(height: 30),
                  ElevatedButton(
                      key: Key('update'),
                      child: Text(
                          timeEntry.timeEntryId == null ? 'Create' : 'Update'),
                      onPressed: () async {
                        context
                            .read<TaskBloc>()
                            .add(TaskTimeEntryUpdate(TimeEntry(
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
                ]))));
  }
}
