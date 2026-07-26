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

import '../../growerp_activity.dart';

/// Admin dialog to create an invoice from approved time entries:
/// either a sales invoice for a client (billing the hours on their tasks)
/// or a purchase (self-billing) invoice for an assistant.
class TimeEntryInvoiceDialog extends StatefulWidget {
  const TimeEntryInvoiceDialog({super.key});
  @override
  TimeEntryInvoiceDialogState createState() => TimeEntryInvoiceDialogState();
}

class TimeEntryInvoiceDialogState extends State<TimeEntryInvoiceDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _rateController = TextEditingController();
  late ActivityBloc _activityBloc;
  bool _sales = true;
  User? _selectedParty;

  @override
  void initState() {
    super.initState();
    _activityBloc = context.read<ActivityBloc>();
  }

  @override
  void dispose() {
    _rateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ActivityBloc, ActivityState>(
      listener: (context, state) {
        if (state.status == ActivityBlocStatus.success &&
            state.message != null) {
          HelperFunctions.showMessage(context, state.message!, Colors.green);
          Navigator.of(context).pop();
        }
        if (state.status == ActivityBlocStatus.failure) {
          HelperFunctions.showMessage(
            context,
            state.message ?? 'unknown error',
            Colors.red,
          );
        }
      },
      child: Dialog(
        key: const Key('TimeEntryInvoiceDialog'),
        insetPadding: const EdgeInsets.all(10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: popUp(
          context: context,
          title: 'Invoice hours',
          height: 400,
          width: 400,
          child: _showForm(),
        ),
      ),
    );
  }

  Widget _showForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          DropdownButtonFormField<bool>(
            key: const Key('invoiceType'),
            decoration: const InputDecoration(labelText: 'Invoice type'),
            initialValue: _sales,
            items: const [
              DropdownMenuItem(
                value: true,
                child: Text('Sales invoice to client'),
              ),
              DropdownMenuItem(
                value: false,
                child: Text('Purchase invoice for assistant'),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _sales = value ?? true;
                _selectedParty = null;
              });
            },
          ),
          const SizedBox(height: 10),
          AutocompleteLabel<User>(
            key: Key(_sales ? 'clientSearch' : 'assistantSearch'),
            label: _sales ? 'Client' : 'Assistant',
            initialValue: _selectedParty,
            optionsBuilder: (TextEditingValue textEditingValue) =>
                context.read<RestClient>().getUser(
                  searchString: textEditingValue.text,
                  limit: 5,
                  isForDropDown: true,
                  role: _sales ? Role.customer : Role.company,
                ).then((users) => users.users),
            displayStringForOption: (User u) =>
                " ${[u.firstName, u.lastName].where((s) => s != null && s.isNotEmpty).join(' ')} "
                "${u.company?.name ?? ''}",
            onSelected: (User? newValue) {
              setState(() {
                _selectedParty = newValue;
              });
            },
          ),
          const SizedBox(height: 10),
          if (!_sales)
            TextFormField(
              key: const Key('hourlyRate'),
              decoration: const InputDecoration(
                labelText: 'Hourly rate to pay the assistant',
              ),
              controller: _rateController,
              keyboardType: TextInputType.number,
              validator: (value) => !_sales && (value == null || value.isEmpty)
                  ? 'Hourly rate required'
                  : null,
            ),
          const SizedBox(height: 20),
          OutlinedButton(
            key: const Key('createInvoice'),
            child: const Text('Create invoice'),
            onPressed: () {
              if (_selectedParty == null) {
                HelperFunctions.showMessage(
                  context,
                  _sales ? 'Select a client' : 'Select an assistant',
                  Colors.red,
                );
                return;
              }
              if (_formKey.currentState!.validate()) {
                _activityBloc.add(
                  ActivityInvoiceFromTimeEntries(
                    sales: _sales,
                    partyId: _selectedParty!.partyId!,
                    hourlyRate: _sales ? null : _rateController.text,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
