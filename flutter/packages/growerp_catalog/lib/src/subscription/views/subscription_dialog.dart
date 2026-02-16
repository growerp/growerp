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

import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:intl/intl.dart';

import '../../../growerp_catalog.dart';

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
      ..add(
        GetDataEvent(
          () => context.read<RestClient>().getCompanyUser(
            limit: 3,
            role: Role.customer,
          ),
        ),
      );
    _productBloc = context.read<DataFetchBloc<Products>>()
      ..add(
        GetDataEvent(() => context.read<RestClient>().getProducts(limit: 3)),
      );
  }

  @override
  Widget build(BuildContext context) {
    int columns = ResponsiveBreakpoints.of(context).isMobile ? 1 : 2;
    bool isPhone = isAPhone(context);
    var catalogLocalizations = CatalogLocalizations.of(context)!;
    return BlocListener<SubscriptionBloc, SubscriptionState>(
      listenWhen: (previous, current) =>
          current.status == SubscriptionStatus.failure ||
          (current.status == SubscriptionStatus.success &&
              current.message != null &&
              current.message!.isNotEmpty),
      listener: (context, state) async {
        switch (state.status) {
          case SubscriptionStatus.success:
            Navigator.of(context).pop();
            break;
          case SubscriptionStatus.failure:
            HelperFunctions.showMessage(
              context,
              catalogLocalizations.error(state.message ?? ''),
              Colors.red,
            );
            break;
          default:
            Text(catalogLocalizations.question);
        }
      },
      child: Dialog(
        key: const Key('SubscriptionDialog'),
        insetPadding: const EdgeInsets.all(10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: popUp(
          context: context,
          title: catalogLocalizations.subscriptionNumber(
            widget.subscription.subscriptionId == null
                ? catalogLocalizations.newItem
                : widget.subscription.pseudoId ?? '',
          ),
          width: columns.toDouble() * (isPhone ? 400 : 300),
          height: 1 / columns.toDouble() * (isPhone ? 550 : 900),
          child: _subscriptionForm(),
        ),
      ),
    );
  }

  Widget _subscriptionForm() {
    var catalogLocalizations = CatalogLocalizations.of(context)!;
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
                    decoration: InputDecoration(
                      labelText: catalogLocalizations.id(
                        widget.subscription.pseudoId ?? '',
                      ),
                    ),
                  ),
                ),

                // Subscriber dropdown
                const SizedBox(width: 16),
                Flexible(
                  flex: 3,
                  child: AutocompleteLabel<CompanyUser>(
                    key: const Key('subscriber'),
                    label: catalogLocalizations.subscriberLabel,
                    initialValue: _selectedSubscriber,
                    validator: (CompanyUser? value) {
                      return value == null
                          ? catalogLocalizations.subscriberRequired
                          : null;
                    },
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      _companyUserBloc.add(
                        GetDataEvent(
                          () => context.read<RestClient>().getCompanyUser(
                            searchString: textEditingValue.text,
                            limit: 3,
                          ),
                        ),
                      );
                      return Future.delayed(
                        const Duration(milliseconds: 150),
                        () {
                          return (_companyUserBloc.state.data as CompaniesUsers)
                              .companiesUsers;
                        },
                      );
                    },
                    displayStringForOption: (CompanyUser u) =>
                        " ${u.name ?? ''} ${u.company?.name ?? ''}",
                    onSelected: (CompanyUser? newValue) {
                      setState(() {
                        _selectedSubscriber = newValue;
                      });
                    },
                  ),
                ),
              ],
            ),
            if (widget.subscription.subscriptionId != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        catalogLocalizations.purchased(
                          widget.subscription.purchaseFromDate!
                              .toLocalizedDateOnly(context),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        catalogLocalizations.cancelled(
                          widget.subscription.purchaseThruDate
                              .toLocalizedDateOnly(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            FormBuilderTextField(
              name: 'description',
              key: const Key('description'),
              maxLines: 2,
              decoration: InputDecoration(
                labelText: catalogLocalizations.description,
              ),
            ),
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: FormBuilderDateTimePicker(
                    name: 'fromDate',
                    key: const Key('fromDate'),
                    // Convert from server UTC time to local time for display
                    initialValue: widget.subscription.fromDate?.toLocal(),
                    inputType: InputType.date,
                    format: DateFormat('yyyy-MM-dd'),
                    decoration: InputDecoration(
                      labelText: catalogLocalizations.fromDate,
                      hintText: 'yyyy-MM-dd',
                      suffixIcon: const Icon(Icons.calendar_today),
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
                    format: DateFormat('yyyy-MM-dd'),
                    decoration: InputDecoration(
                      labelText: catalogLocalizations.thruDate,
                      hintText: 'yyyy-MM-dd',
                      suffixIcon: const Icon(Icons.calendar_today),
                    ),
                  ),
                ),
              ],
            ),
            // Product dropdown
            AutocompleteLabel<Product>(
              key: const Key('product'),
              label: catalogLocalizations.product,
              initialValue: _selectedProduct,
              validator: (Product? value) {
                return value == null
                    ? catalogLocalizations.productRequired
                    : null;
              },
              optionsBuilder: (TextEditingValue textEditingValue) {
                _productBloc.add(
                  GetDataEvent(
                    () => context.read<RestClient>().getProduct(
                      searchString: textEditingValue.text,
                      limit: 3,
                      isForDropDown: true,
                    ),
                  ),
                );
                return Future.delayed(const Duration(milliseconds: 150), () {
                  return (_productBloc.state.data as Products).products;
                });
              },
              displayStringForOption: (Product p) =>
                  "${p.productName ?? ''} (${p.pseudoId})",
              onSelected: (Product? newValue) {
                setState(() {
                  _selectedProduct = newValue;
                });
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: const Key('update'),
                    child: Text(
                      widget.subscription.subscriptionId == null
                          ? catalogLocalizations.create
                          : catalogLocalizations.update,
                    ),
                    onPressed: () {
                      if (_formKey.currentState!.saveAndValidate()) {
                        final formData = _formKey.currentState!.value;
                        DateTime? fromDate = formData['fromDate'] as DateTime?;
                        DateTime? thruDate = formData['thruDate'] as DateTime?;
                        CompanyUser? subscriber = _selectedSubscriber;
                        Product? product = _selectedProduct;

                        _subscriptionBloc.add(
                          SubscriptionUpdate(
                            Subscription(
                              subscriptionId:
                                  widget.subscription.subscriptionId,
                              pseudoId: formData['pseudoId'] ?? '',
                              description: formData['description'] ?? '',
                              // Convert dates to UTC for server storage
                              fromDate: fromDate?.noon().toServerTime(),
                              thruDate: thruDate?.noon().toServerTime(),
                              subscriber: subscriber,
                              product: product,
                            ),
                          ),
                        );
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
