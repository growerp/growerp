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
import 'package:intl/intl.dart';

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
  Product? _selectedProduct;
  late SubscriptionBloc _subscriptionBloc;
  late DataFetchBloc<CompaniesUsers> _companyUserBloc;
  late DataFetchBloc<Products> _productBloc;

  @override
  void initState() {
    super.initState();
    _subscriptionBloc = context.read<SubscriptionBloc>();
    _selectedProduct = widget.subscription.product;
    _selectedSubscriber = widget.subscription.subscriber;
    _companyUserBloc = context.read<DataFetchBloc<CompaniesUsers>>()
      ..add(GetDataEvent(() => context
          .read<RestClient>()
          .getCompanyUser(limit: 3, role: Role.customer)));
    _productBloc = context.read<DataFetchBloc<Products>>()
      ..add(
          GetDataEvent(() => context.read<RestClient>().getProducts(limit: 3)));
  }

  @override
  Widget build(BuildContext context) {
    int columns = ResponsiveBreakpoints.of(context).isMobile ? 1 : 2;
    bool isPhone = isAPhone(context);
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
              "Subscription #${widget.subscription.subscriptionId == null ? " New" : widget.subscription.pseudoId}",
          width: columns.toDouble() * (isPhone ? 400 : 300),
          height: 1 / columns.toDouble() * (isPhone ? 500 : 800),
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
        'subscriber': _selectedSubscriber,
        'product': _selectedProduct,
      },
      child: SingleChildScrollView(
        key: const Key('listView'),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Flexible(
                  flex: 1,
                  child: FormBuilderTextField(
                    name: 'pseudoId',
                    key: const Key('pseudoId'),
                    decoration: const InputDecoration(labelText: 'Id'),
                  ),
                ),
                // Subscriber dropdown

                const SizedBox(width: 16),
                Flexible(
                  flex: 3,
                  child: FormBuilderField<CompanyUser>(
                    name: 'subscriber',
                    initialValue: _selectedSubscriber,
                    builder: (FormFieldState<CompanyUser> field) {
                      return DropdownSearch<CompanyUser>(
                        selectedItem: field.value,
                        popupProps: PopupProps.menu(
                          isFilterOnline: true,
                          showSearchBox: true,
                          searchFieldProps: const TextFieldProps(
                            autofocus: true,
                            decoration:
                                InputDecoration(labelText: "subscriber,name"),
                          ),
                          menuProps: MenuProps(
                              borderRadius: BorderRadius.circular(20.0)),
                          title: popUp(
                            context: context,
                            title: 'Select Subscriber',
                            height: 50,
                          ),
                        ),
                        dropdownDecoratorProps: DropDownDecoratorProps(
                          dropdownSearchDecoration: InputDecoration(
                            labelText: 'Subscriber',
                            errorText: field.errorText,
                          ),
                        ),
                        key: const Key('subscriber'),
                        itemAsString: (CompanyUser? u) => " ${u?.name} "
                            "${u?.company?.name ?? ''}",
                        asyncItems: (String filter) {
                          _companyUserBloc.add(GetDataEvent(
                              () => context.read<RestClient>().getCompanyUser(
                                    searchString: filter,
                                    limit: 3,
                                  )));
                          return Future.delayed(
                              const Duration(milliseconds: 150), () {
                            return Future.value(
                                (_companyUserBloc.state.data as CompaniesUsers)
                                    .companiesUsers);
                          });
                        },
                        compareFn: (item, sItem) =>
                            item.partyId == sItem.partyId,
                        onChanged: (CompanyUser? newValue) {
                          setState(() {
                            _selectedSubscriber = newValue;
                          });
                          field.didChange(newValue);
                        },
                      );
                    },
                    validator: (CompanyUser? value) {
                      return value == null
                          ? 'Please select a subscriber'
                          : null;
                    },
                  ),
                ),
              ],
            ),
            FormBuilderTextField(
              name: 'description',
              key: const Key('description'),
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            Row(children: [
              Expanded(
                flex: 1,
                child: FormBuilderDateTimePicker(
                  name: 'fromDate',
                  key: const Key('fromDate'),
                  // Convert from server UTC time to local time for display
                  initialValue: widget.subscription.fromDate?.toLocal(),
                  inputType: InputType.date,
                  format: DateFormat('yyyy/M/d'),
                  decoration: const InputDecoration(
                    labelText: 'From Date',
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(),
                  ]),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: FormBuilderDateTimePicker(
                  name: 'thruDate',
                  key: const Key('thruDate'),
                  // Convert from server UTC time to local time for display
                  initialValue: widget.subscription.thruDate?.toLocal(),
                  inputType: InputType.date,
                  format: DateFormat('yyyy/M/d'),
                  decoration: const InputDecoration(
                    labelText: 'Thru Date',
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                flex: 1,
                child: FormBuilderDateTimePicker(
                  name: 'purchaseFromDate',
                  key: const Key('purchaseFromDate'),
                  // Convert from server UTC time to local time for display
                  initialValue: widget.subscription.purchaseFromDate?.toLocal(),
                  inputType: InputType.date,
                  format: DateFormat('yyyy/M/d'),
                  decoration: const InputDecoration(
                    labelText: 'Purchase Date',
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: FormBuilderDateTimePicker(
                  name: 'purchaseThruDate',
                  key: const Key('purchaseThruDate'),
                  // Convert from server UTC time to local time for display
                  initialValue: widget.subscription.purchaseThruDate?.toLocal(),
                  inputType: InputType.date,
                  format: DateFormat('yyyy/M/d'),
                  decoration: const InputDecoration(
                    labelText: 'Cancel Date',
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                ),
              ),
            ]),
            // Product dropdown
            const SizedBox(height: 16),
            FormBuilderField<Product>(
              name: 'product',
              initialValue: _selectedProduct,
              builder: (FormFieldState<Product> field) {
                return DropdownSearch<Product>(
                  selectedItem: field.value,
                  popupProps: PopupProps.menu(
                    isFilterOnline: true,
                    showSearchBox: true,
                    searchFieldProps: const TextFieldProps(
                      autofocus: true,
                      decoration:
                          InputDecoration(labelText: "Search products..."),
                    ),
                    menuProps:
                        MenuProps(borderRadius: BorderRadius.circular(20.0)),
                    title: popUp(
                      context: context,
                      title: 'Select Product',
                      height: 50,
                    ),
                  ),
                  dropdownDecoratorProps: DropDownDecoratorProps(
                    dropdownSearchDecoration: InputDecoration(
                      labelText: 'Product',
                      errorText: field.errorText,
                    ),
                  ),
                  key: const Key('product'),
                  itemAsString: (Product? p) => "${p?.productName ?? ''} "
                      "(${p?.pseudoId ?? ''})",
                  asyncItems: (String filter) {
                    _productBloc.add(GetDataEvent(() => context
                        .read<RestClient>()
                        .getProduct(
                            searchString: filter,
                            limit: 3,
                            isForDropDown: true)));
                    return Future.delayed(const Duration(milliseconds: 150),
                        () {
                      return Future.value(
                          (_productBloc.state.data as Products).products);
                    });
                  },
                  compareFn: (item, sItem) => item.productId == sItem.productId,
                  onChanged: (Product? newValue) {
                    setState(() {
                      _selectedProduct = newValue;
                    });
                    field.didChange(newValue);
                  },
                );
              },
              validator: (Product? value) {
                return value == null ? 'Please select a product' : null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: const Key('update'),
                    child: Text(widget.subscription.subscriptionId == null
                        ? 'Create'
                        : 'Update'),
                    onPressed: () {
                      if (_formKey.currentState!.saveAndValidate()) {
                        final formData = _formKey.currentState!.value;
                        DateTime? fromDate = formData['fromDate'] as DateTime?;
                        DateTime? thruDate = formData['thruDate'] as DateTime?;
                        DateTime? purchaseFromDate =
                            formData['purchaseFromDate'] as DateTime?;
                        DateTime? purchaseThruDate =
                            formData['purchaseThruDate'] as DateTime?;
                        CompanyUser? subscriber =
                            formData['subscriber'] as CompanyUser?;
                        Product? product = formData['product'] as Product?;

                        _subscriptionBloc.add(SubscriptionUpdate(Subscription(
                          subscriptionId: widget.subscription.subscriptionId,
                          pseudoId: formData['pseudoId'] ?? '',
                          description: formData['description'] ?? '',
                          // Convert dates to UTC for server storage
                          fromDate: fromDate?.noon().toServerTime(),
                          thruDate: thruDate?.noon().toServerTime(),
                          purchaseFromDate:
                              purchaseFromDate?.noon().toServerTime(),
                          purchaseThruDate:
                              purchaseThruDate?.noon().toServerTime(),
                          subscriber: subscriber,
                          product: product,
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
