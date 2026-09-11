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
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:intl/intl.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../../growerp_hr.dart';

/// Enter, change, cancel a leave request; an admin can also approve or reject
/// a pending request.
class LeaveRequestDialog extends StatefulWidget {
  final LeaveRequest leaveRequest;
  final bool myRequests;
  const LeaveRequestDialog(
    this.leaveRequest, {
    super.key,
    this.myRequests = false,
  });
  @override
  LeaveRequestDialogState createState() => LeaveRequestDialogState();
}

class LeaveRequestDialogState extends State<LeaveRequestDialog> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  final _commentsController = TextEditingController();
  LeaveType _leaveType = LeaveType.annual;
  DateTime? _fromDate;
  DateTime? _thruDate;
  String? _partyId;
  late bool isNew;
  late bool isAdmin;

  @override
  void initState() {
    super.initState();
    isNew = widget.leaveRequest.leaveRequestId.isEmpty;
    _leaveType = widget.leaveRequest.leaveType ?? LeaveType.annual;
    _fromDate = widget.leaveRequest.fromDate?.toLocal();
    _thruDate = widget.leaveRequest.thruDate?.toLocal();
    _reasonController.text = widget.leaveRequest.reason ?? '';
    _commentsController.text = widget.leaveRequest.comments ?? '';
    _partyId = widget.leaveRequest.partyId;
    final userGroup = context
        .read<AuthBloc>()
        .state
        .authenticate
        ?.user
        ?.userGroup;
    isAdmin = userGroup == UserGroup.admin || userGroup == UserGroup.system;
    if (isAdmin && !widget.myRequests) {
      context.read<EmployeeBloc>().add(const EmployeesFetch(refresh: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = HrLocalizations.of(context)!;
    final isPhone = ResponsiveBreakpoints.of(context).isMobile;
    return Dialog(
      key: const Key('LeaveRequestDialog'),
      insetPadding: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: BlocListener<LeaveRequestBloc, LeaveRequestState>(
        listener: (context, state) {
          switch (state.status) {
            case LeaveRequestStatus.success:
              HelperFunctions.showMessage(
                context,
                isNew ? localizations.addSuccess : localizations.updateSuccess,
                Colors.green,
              );
              Navigator.of(context).pop();
            case LeaveRequestStatus.failure:
              HelperFunctions.showMessage(context, state.message, Colors.red);
            default:
          }
        },
        child: popUp(
          context: context,
          title: isNew
              ? localizations.newLeaveRequest
              : '${localizations.leaveRequest} '
                    '${widget.leaveRequest.pseudoId}',
          height: 600,
          width: isPhone ? 400 : 500,
          child: _showForm(localizations),
        ),
      ),
    );
  }

  Widget _showForm(HrLocalizations localizations) {
    final isPending =
        (widget.leaveRequest.status ?? LeaveStatus.pending) ==
        LeaveStatus.pending;
    final employees = context.select<EmployeeBloc, List<Employee>>(
      (bloc) => bloc.state.employees,
    );
    return Form(
      key: _formKey,
      child: ListView(
        key: const Key('listView'),
        children: <Widget>[
          if (isNew && isAdmin && !widget.myRequests)
            DropdownButtonFormField<String>(
              key: const Key('employee'),
              decoration: InputDecoration(labelText: localizations.employee),
              initialValue: employees.any((e) => e.partyId == _partyId)
                  ? _partyId
                  : null,
              items: employees
                  .map(
                    (e) => DropdownMenuItem<String>(
                      value: e.partyId,
                      child: Text(e.name),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _partyId = value),
            )
          else if (!isNew)
            Text(
              '${widget.leaveRequest.employeeName ?? ''} '
              '(${widget.leaveRequest.status?.name ?? ''})',
              key: const Key('leaveRequestHeader'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          const SizedBox(height: 10),
          DropdownButtonFormField<LeaveType>(
            key: const Key('leaveType'),
            decoration: InputDecoration(labelText: localizations.leaveType),
            initialValue: _leaveType,
            items: LeaveType.values
                .where((t) => t != LeaveType.unknown)
                .map(
                  (t) => DropdownMenuItem<LeaveType>(
                    value: t,
                    child: Text(t.name),
                  ),
                )
                .toList(),
            onChanged: isPending
                ? (value) =>
                      setState(() => _leaveType = value ?? LeaveType.annual)
                : null,
          ),
          const SizedBox(height: 10),
          FormBuilderDateTimePicker(
            name: 'fromDate',
            key: const Key('fromDate'),
            initialValue: _fromDate,
            enabled: isPending,
            inputType: InputType.date,
            format: DateFormat('yyyy-MM-dd'),
            decoration: InputDecoration(
              labelText: localizations.fromDate,
              hintText: 'yyyy-MM-dd',
              suffixIcon: const Icon(Icons.calendar_today),
            ),
            onChanged: (value) => _fromDate = value,
          ),
          const SizedBox(height: 10),
          FormBuilderDateTimePicker(
            name: 'thruDate',
            key: const Key('thruDate'),
            initialValue: _thruDate,
            enabled: isPending,
            inputType: InputType.date,
            format: DateFormat('yyyy-MM-dd'),
            decoration: InputDecoration(
              labelText: localizations.thruDate,
              hintText: 'yyyy-MM-dd',
              suffixIcon: const Icon(Icons.calendar_today),
            ),
            onChanged: (value) => _thruDate = value,
          ),
          const SizedBox(height: 10),
          if (!isNew)
            Text(
              '${localizations.days}: ${widget.leaveRequest.days ?? ''}',
              key: const Key('days'),
            ),
          const SizedBox(height: 10),
          TextFormField(
            key: const Key('reason'),
            decoration: InputDecoration(labelText: localizations.reason),
            controller: _reasonController,
            enabled: isPending,
          ),
          if (isAdmin) ...[
            const SizedBox(height: 10),
            TextFormField(
              key: const Key('comments'),
              decoration: InputDecoration(labelText: localizations.comments),
              controller: _commentsController,
            ),
          ],
          const SizedBox(height: 20),
          if (isPending)
            ElevatedButton(
              key: const Key('update'),
              child: Text(isNew ? localizations.add : localizations.update),
              onPressed: () {
                if (!_formKey.currentState!.validate()) return;
                if (_fromDate == null || _thruDate == null) {
                  HelperFunctions.showMessage(
                    context,
                    '${localizations.fromDate}/${localizations.thruDate}?',
                    Colors.red,
                  );
                  return;
                }
                _send(status: null);
              },
            ),
          if (!isNew && isPending) ...[
            const SizedBox(height: 10),
            if (isAdmin)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      key: const Key('approve'),
                      onPressed: () => _send(status: LeaveStatus.approved),
                      child: Text(localizations.approve),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      key: const Key('reject'),
                      onPressed: () => _send(status: LeaveStatus.rejected),
                      child: Text(localizations.reject),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 10),
            OutlinedButton(
              key: const Key('cancelRequest'),
              onPressed: () => _send(status: LeaveStatus.cancelled),
              child: Text(localizations.cancelRequest),
            ),
          ],
        ],
      ),
    );
  }

  void _send({LeaveStatus? status}) {
    context.read<LeaveRequestBloc>().add(
      LeaveRequestUpdate(
        widget.leaveRequest.copyWith(
          partyId: _partyId ?? widget.leaveRequest.partyId,
          leaveType: _leaveType,
          fromDate: hrDateOnly(_fromDate),
          thruDate: hrDateOnly(_thruDate),
          reason: _reasonController.text,
          comments: _commentsController.text,
          status: status,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _commentsController.dispose();
    super.dispose();
  }
}
