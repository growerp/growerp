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

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import '../blocs/subscription_bloc.dart';

class SubscriptionDialog extends StatefulWidget {
  final Subscription subscription;
  const SubscriptionDialog(this.subscription, {super.key});
  @override
  SubscriptionDialogState createState() => SubscriptionDialogState();
}

class SubscriptionDialogState extends State<SubscriptionDialog> {
  final _formKey = GlobalKey<FormBuilderState>();
  CompanyUser? _selectedSubscriber;
  late SubscriptionBloc _subscriptionBloc;

  @override
  void initState() {
    super.initState();
    _subscriptionBloc = context.read<SubscriptionBloc>();
    _selectedSubscriber = widget.subscription.subscriber;
  }

  @override
  Widget build(BuildContext context) {
    int columns = ResponsiveBreakpoints.of(context).isMobile ? 1 : 2;
    return BlocListener<SubscriptionBloc, SubscriptionState>(
      listener: (context, state) async {
        switch (state.status) {
          case SubscriptionStatus.success:
            Navigator.of(context).pop();
            break;
          case SubscriptionStatus.failure:
            HelperFunctions.showMessage(
                context, 'Error: ${state.message}', Colors.red);
            break;
          default:
            const Text("????");
        }
      },
      child: Dialog(
        key: const Key('SubscriptionDialog'),
        insetPadding: const EdgeInsets.all(10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: popUp(
          context: context,
          title:
              "Subscription #${widget.subscription.subscriptionId!.isEmpty ? " New" : widget.subscription.pseudoId}",
          width: columns.toDouble() * 400,
          height: 1 / columns.toDouble() * 1000,
          child: _subscriptionForm(),
        ),
      ),
    );
  }

  Widget _subscriptionForm() {
    return FormBuilder(
      key: _formKey,
      initialValue: {
        'pseudoId': widget.subscription.pseudoId ?? '',
        'description': widget.subscription.description ?? '',
        'fromDate': widget.subscription.fromDate?.toString() ?? '',
        'thruDate': widget.subscription.thruDate?.toString() ?? '',
      },
      child: SingleChildScrollView(
        key: const Key('listView'),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            FormBuilderTextField(
              name: 'pseudoId',
              key: const Key('pseudoId'),
              decoration: const InputDecoration(labelText: 'Id'),
              validator: FormBuilderValidators.compose([
                FormBuilderValidators.required(),
              ]),
            ),
            FormBuilderTextField(
              name: 'description',
              key: const Key('description'),
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Description'),
              validator: FormBuilderValidators.compose([
                FormBuilderValidators.required(),
              ]),
            ),
            FormBuilderTextField(
              name: 'fromDate',
              key: const Key('fromDate'),
              decoration: const InputDecoration(labelText: 'From Date'),
              validator: FormBuilderValidators.compose([
                FormBuilderValidators.required(),
              ]),
            ),
            FormBuilderTextField(
              name: 'thruDate',
              key: const Key('thruDate'),
              decoration: const InputDecoration(labelText: 'Thru Date'),
            ),
            // Subscriber dropdown
            DropdownSearch<CompanyUser>(
              selectedItem: _selectedSubscriber,
              popupProps: PopupProps.menu(
                isFilterOnline: true,
                showSearchBox: true,
                searchFieldProps: const TextFieldProps(
                  autofocus: true,
                  decoration: InputDecoration(labelText: "subscriber,name"),
                ),
                menuProps: MenuProps(borderRadius: BorderRadius.circular(20.0)),
                title: popUp(
                  context: context,
                  title: 'Select Subscriber',
                  height: 50,
                ),
              ),
              dropdownDecoratorProps: const DropDownDecoratorProps(
                  dropdownSearchDecoration:
                      InputDecoration(labelText: 'Subscriber')),
              key: const Key('subscriber'),
              itemAsString: (CompanyUser? u) => " ${u?.name} "
                  "${u?.company?.name ?? ''}",
              asyncItems: (String filter) {
                // Implement your async fetch for subscribers here
                return Future.value([]); // Replace with actual fetch logic
              },
              compareFn: (item, sItem) => item.partyId == sItem.partyId,
              onChanged: (CompanyUser? newValue) {
                setState(() {
                  _selectedSubscriber = newValue;
                });
              },
            ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: const Key('update'),
                    child: Text(widget.subscription.subscriptionId!.isEmpty
                        ? 'Create'
                        : 'Update'),
                    onPressed: () {
                      if (_formKey.currentState!.saveAndValidate()) {
                        final formData = _formKey.currentState!.value;
                        _subscriptionBloc.add(SubscriptionUpdate(Subscription(
                          subscriptionId: widget.subscription.subscriptionId,
                          pseudoId: formData['pseudoId'] ?? '',
                          description: formData['description'] ?? '',
                          fromDate:
                              DateTime.tryParse(formData['fromDate'] ?? ''),
                          thruDate:
                              DateTime.tryParse(formData['thruDate'] ?? ''),
                          subscriber: _selectedSubscriber,
                        )));
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
