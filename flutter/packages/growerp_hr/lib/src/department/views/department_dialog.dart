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

class DepartmentDialog extends StatefulWidget {
  final Department department;
  const DepartmentDialog(this.department, {super.key});
  @override
  DepartmentDialogState createState() => DepartmentDialogState();
}

class DepartmentDialogState extends State<DepartmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String? _managerPartyId;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.department.name;
    _managerPartyId = widget.department.managerPartyId;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = HrLocalizations.of(context)!;
    final isPhone = ResponsiveBreakpoints.of(context).isMobile;
    final isNew = widget.department.partyId.isEmpty;
    return Dialog(
      key: const Key('DepartmentDialog'),
      insetPadding: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: BlocListener<DepartmentBloc, DepartmentState>(
        listener: (context, state) {
          switch (state.status) {
            case DepartmentStatus.success:
              HelperFunctions.showMessage(
                context,
                isNew ? localizations.addSuccess : localizations.updateSuccess,
                Colors.green,
              );
              Navigator.of(context).pop();
            case DepartmentStatus.failure:
              HelperFunctions.showMessage(context, state.message, Colors.red);
            default:
          }
        },
        child: popUp(
          context: context,
          title: isNew
              ? localizations.newDepartment
              : '${localizations.department}: ${widget.department.name}',
          height: 350,
          width: isPhone ? 400 : 450,
          child: _showForm(localizations),
        ),
      ),
    );
  }

  Widget _showForm(HrLocalizations localizations) {
    final employees = context.select<EmployeeBloc, List<Employee>>(
      (bloc) => bloc.state.employees,
    );
    return Center(
      child: Form(
        key: _formKey,
        child: ListView(
          key: const Key('listView'),
          children: <Widget>[
            TextFormField(
              key: const Key('name'),
              decoration: InputDecoration(labelText: localizations.name),
              controller: _nameController,
              validator: (value) => value == null || value.isEmpty
                  ? '${localizations.name}?'
                  : null,
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              key: const Key('manager'),
              decoration: InputDecoration(labelText: localizations.manager),
              initialValue: employees.any((e) => e.partyId == _managerPartyId)
                  ? _managerPartyId
                  : null,
              items: [
                DropdownMenuItem<String>(
                  value: null,
                  child: Text(localizations.none),
                ),
                ...employees.map(
                  (employee) => DropdownMenuItem<String>(
                    value: employee.partyId,
                    child: Text(employee.name),
                  ),
                ),
              ],
              onChanged: (value) => setState(() => _managerPartyId = value),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              key: const Key('update'),
              child: Text(
                widget.department.partyId.isEmpty
                    ? localizations.add
                    : localizations.update,
              ),
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  context.read<DepartmentBloc>().add(
                    DepartmentUpdate(
                      widget.department.copyWith(
                        name: _nameController.text,
                        managerPartyId: _managerPartyId,
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
    super.dispose();
  }
}
