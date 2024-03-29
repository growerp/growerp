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

import 'package:growerp_core/growerp_core.dart';
import 'package:decimal/decimal.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:growerp_models/growerp_models.dart';

import '../../accounting/accounting.dart';
import '../findoc.dart';

class ShowPaymentDialog extends StatelessWidget {
  final FinDoc finDoc;
  final bool dialog;
  const ShowPaymentDialog(this.finDoc, {super.key, this.dialog = true});
  @override
  Widget build(BuildContext context) {
    RestClient repos = context.read<RestClient>();
    return BlocProvider<FinDocBloc>(
        create: (context) => FinDocBloc(
            repos, finDoc.sales, finDoc.docType!, context.read<String>())
          ..add(FinDocFetch(finDocId: finDoc.id()!, docType: finDoc.docType!)),
        child: BlocBuilder<FinDocBloc, FinDocState>(builder: (context, state) {
          if (state.status == FinDocStatus.success) {
            return RepositoryProvider.value(
                value: repos, child: PaymentDialog(finDoc: state.finDocs[0]));
          } else {
            return const LoadingIndicator();
          }
        }));
  }
}

class PaymentDialog extends StatelessWidget {
  final FinDoc finDoc;
  final PaymentMethod? paymentMethod;
  const PaymentDialog({required this.finDoc, this.paymentMethod, super.key});

  @override
  Widget build(BuildContext context) {
    if (finDoc.sales) {
      return MultiBlocProvider(
          providers: [
            BlocProvider<CompanyBloc>(
                create: (context) => CompanyBloc(context.read<RestClient>(),
                    Role.customer, context.read<AuthBloc>())),
            BlocProvider<GlAccountBloc>(
                create: (context) => GlAccountBloc(context.read<RestClient>())),
          ],
          child:
              PaymentDialogFull(finDoc: finDoc, paymentMethod: paymentMethod));
    }
    return MultiBlocProvider(providers: [
      BlocProvider<CompanyBloc>(
          create: (context) => CompanyBloc(context.read<RestClient>(),
              Role.supplier, context.read<AuthBloc>())),
      BlocProvider<GlAccountBloc>(
          create: (context) => GlAccountBloc(context.read<RestClient>())),
    ], child: PaymentDialogFull(finDoc: finDoc, paymentMethod: paymentMethod));
  }
}

class PaymentDialogFull extends StatefulWidget {
  final FinDoc finDoc;
  final PaymentMethod? paymentMethod;
  const PaymentDialogFull(
      {required this.finDoc, this.paymentMethod, super.key});
  @override
  PaymentDialogState createState() => PaymentDialogState();
}

class PaymentDialogState extends State<PaymentDialogFull> {
  final GlobalKey<FormState> paymentDialogFormKey = GlobalKey<FormState>();
  late FinDoc finDoc; // incoming finDoc
  late FinDoc finDocUpdated;
  late FinDocBloc _finDocBloc;
  GlAccount? _selectedGlAccount;
  Company? _selectedCompany;
  PaymentType? _selectedPaymentType;
  late CompanyBloc _companyBloc;
  late GlAccountBloc _accountBloc;

  late bool isPhone;
  late PaymentInstrument _paymentInstrument;
  final _userSearchBoxController = TextEditingController();
  final _amountController = TextEditingController();
  final _pseudoIdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    finDoc = widget.finDoc;
    finDocUpdated = finDoc;
    _selectedCompany = finDocUpdated.otherCompany;
    _selectedGlAccount = finDocUpdated.items.isNotEmpty
        ? finDocUpdated.items[0].glAccount
        : null;
    _selectedCompany = finDocUpdated.otherCompany;
    _amountController.text =
        finDoc.grandTotal == null ? '' : finDoc.grandTotal.toString();
    _pseudoIdController.text =
        finDoc.pseudoId == null ? '' : finDoc.pseudoId.toString();
    _selectedPaymentType = finDocUpdated.items.isNotEmpty
        ? finDocUpdated.items[0].paymentType
        : null;
    _paymentInstrument = finDocUpdated.paymentInstrument == null
        ? PaymentInstrument.cash
        : finDocUpdated.paymentInstrument!;
    _finDocBloc = context.read<FinDocBloc>();
    _finDocBloc.add(FinDocGetPaymentTypes(sales: finDoc.sales));
    _companyBloc = context.read<CompanyBloc>();
    _companyBloc.add(const CompanyFetch(limit: 3));
    _accountBloc = context.read<GlAccountBloc>();
    _accountBloc.add(const GlAccountFetch(limit: 3));
  }

  @override
  Widget build(BuildContext context) {
    isPhone = ResponsiveBreakpoints.of(context).isMobile;
    return BlocProvider.value(
        value: context.read<FinDocBloc>(),
        child: Dialog(
            key: Key("PaymentDialog${finDoc.sales ? 'Sales' : 'Purchase'}"),
            insetPadding: const EdgeInsets.all(10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: BlocConsumer<FinDocBloc, FinDocState>(
              listenWhen: (previous, current) =>
                  previous.status == FinDocStatus.loading,
              listener: (context, state) {
                if (state.status == FinDocStatus.success) {
                  Navigator.of(context).pop();
                }
                if (state.status == FinDocStatus.failure) {
                  HelperFunctions.showMessage(
                      context, '${state.message}', Colors.red);
                }
              },
              builder: (context, state) {
                return popUp(
                    context: context,
                    height: 750,
                    width: 400,
                    title: "${finDoc.sales ? 'Incoming' : 'Outgoing'} "
                        "Payment #${finDoc.pseudoId ?? 'New'}",
                    child: SingleChildScrollView(
                        key: const Key('listView2'),
                        physics: const ClampingScrollPhysics(),
                        child: paymentForm(state, paymentDialogFormKey)));
              },
            )));
  }

  Widget paymentForm(
      FinDocState state, GlobalKey<FormState> paymentDialogFormKey) {
    if (_selectedPaymentType != null) {
      _selectedPaymentType = state.paymentTypes.firstWhere(
          (el) => _selectedPaymentType!.paymentTypeId == el.paymentTypeId);
    }
    AuthBloc authBloc = context.read<AuthBloc>();
    GlAccountBloc glAccountBloc = context.read<GlAccountBloc>();
    Color getColor(Set<MaterialState> states) {
      const Set<MaterialState> interactiveStates = <MaterialState>{
        MaterialState.pressed,
        MaterialState.hovered,
        MaterialState.focused,
      };
      if (states.any(interactiveStates.contains)) {
        return Colors.blue;
      }
      return Colors.red;
    }

    return Padding(
        padding: const EdgeInsets.all(10),
        child: Form(
            key: paymentDialogFormKey,
            child: Column(children: <Widget>[
              TextFormField(
                key: const Key('pseudoId'),
                decoration: const InputDecoration(labelText: 'Id (opt)'),
                controller: _pseudoIdController,
                keyboardType: TextInputType.number,
              ),
              BlocBuilder<CompanyBloc, CompanyState>(builder: (context, state) {
                switch (state.status) {
                  case CompanyStatus.failure:
                    return const FatalErrorForm(
                        message: 'server connection problem');
                  case CompanyStatus.success:
                    return DropdownSearch<Company>(
                      selectedItem: _selectedCompany,
                      popupProps: PopupProps.menu(
                        showSearchBox: true,
                        searchFieldProps: TextFieldProps(
                          autofocus: true,
                          decoration: InputDecoration(
                              labelText:
                                  "${finDocUpdated.sales ? 'customer' : 'supplier'} name"),
                          controller: _userSearchBoxController,
                        ),
                        menuProps: MenuProps(
                            borderRadius: BorderRadius.circular(20.0)),
                        title: popUp(
                          context: context,
                          title:
                              "Select ${finDocUpdated.sales ? 'customer' : 'supplier'}",
                          height: 50,
                        ),
                      ),
                      dropdownDecoratorProps: DropDownDecoratorProps(
                          dropdownSearchDecoration: InputDecoration(
                              labelText: finDocUpdated.sales
                                  ? 'Customer'
                                  : 'Supplier')),
                      key: Key(finDocUpdated.sales ? 'customer' : 'supplier'),
                      itemAsString: (Company? u) => " ${u!.name}",
                      asyncItems: (String filter) {
                        _companyBloc.add(CompanyFetch(searchString: filter));
                        return Future.value(state.companies);
                      },
                      onChanged: (Company? newValue) {
                        setState(() {
                          _selectedCompany = newValue;
                        });
                      },
                      validator: (value) => value == null
                          ? "Select ${finDocUpdated.sales ? 'Customer' : 'Supplier'}!"
                          : null,
                    );
                  default:
                    return const Center(child: CircularProgressIndicator());
                }
              }),
              TextFormField(
                  key: const Key('amount'),
                  decoration: const InputDecoration(labelText: 'Amount'),
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                      value!.isEmpty ? "Enter Price or Amount?" : null),
              const SizedBox(height: 20),
              InputDecorator(
                decoration: InputDecoration(
                  labelText: 'PaymentMethods',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                ),
                child: Column(
                  children: [
                    Visibility(
                        visible: (finDoc.sales == true &&
                                _selectedCompany
                                        ?.paymentMethod?.ccDescription !=
                                    null) ||
                            (finDoc.sales == false &&
                                authBloc.state.authenticate?.company
                                        ?.paymentMethod?.ccDescription !=
                                    null),
                        child: Row(children: [
                          Checkbox(
                              key: const Key('creditCard'),
                              checkColor: Colors.white,
                              fillColor:
                                  MaterialStateProperty.resolveWith(getColor),
                              value: _paymentInstrument ==
                                  PaymentInstrument.creditcard,
                              onChanged: (bool? value) {
                                setState(() {
                                  if (value == true) {
                                    _paymentInstrument =
                                        PaymentInstrument.creditcard;
                                  }
                                });
                              }),
                          Expanded(
                              child: Text(
                                  "Credit Card ${finDoc.sales == false ? authBloc.state.authenticate?.company?.paymentMethod?.ccDescription : _selectedCompany?.paymentMethod?.ccDescription}")),
                        ])),
                    Row(children: [
                      Checkbox(
                          key: const Key('cash'),
                          checkColor: Colors.white,
                          fillColor:
                              MaterialStateProperty.resolveWith(getColor),
                          value: _paymentInstrument == PaymentInstrument.cash,
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                _paymentInstrument = PaymentInstrument.cash;
                              }
                            });
                          }),
                      const Expanded(
                          child: Text(
                        "Cash",
                      )),
                    ]),
                    Row(children: [
                      Checkbox(
                          key: const Key('check'),
                          checkColor: Colors.white,
                          fillColor:
                              MaterialStateProperty.resolveWith(getColor),
                          value: _paymentInstrument == PaymentInstrument.check,
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                _paymentInstrument = PaymentInstrument.check;
                              }
                            });
                          }),
                      const Expanded(
                          child: Text(
                        "Check",
                      )),
                    ]),
                    Row(children: [
                      Checkbox(
                          key: const Key('bank'),
                          checkColor: Colors.white,
                          fillColor:
                              MaterialStateProperty.resolveWith(getColor),
                          value: _paymentInstrument == PaymentInstrument.bank,
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                _paymentInstrument = PaymentInstrument.bank;
                              }
                            });
                          }),
                      Expanded(
                          child: Text(
                        "Bank ${finDoc.otherCompany?.paymentMethod?.creditCardNumber ?? ''}",
                      )),
                    ]),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<PaymentType>(
                key: const Key('paymentType'),
                decoration: const InputDecoration(labelText: 'Payment Type'),
                hint: const Text('Payment Type'),
                value: _selectedPaymentType,
                validator: (value) =>
                    value == null && _selectedGlAccount == null
                        ? 'Enter a item type for posting?'
                        : null,
                items: state.paymentTypes.map((item) {
                  return DropdownMenuItem<PaymentType>(
                      value: item,
                      child: Text(
                          '${item.paymentTypeName}\n ${item.accountCode} ${item.accountName}',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2));
                }).toList(),
                onChanged: (PaymentType? newValue) {
                  _selectedPaymentType = newValue;
                },
                isExpanded: true,
              ),
              const SizedBox(height: 20),
              BlocBuilder<GlAccountBloc, GlAccountState>(
                  builder: (context, state) {
                switch (state.status) {
                  case GlAccountStatus.failure:
                    return const FatalErrorForm(
                        message: 'server connection problem');
                  case GlAccountStatus.success:
                    return DropdownSearch<GlAccount>(
                      selectedItem: _selectedGlAccount,
                      popupProps: PopupProps.menu(
                        isFilterOnline: true,
                        showSelectedItems: true,
                        showSearchBox: true,
                        searchFieldProps: const TextFieldProps(
                          autofocus: true,
                          decoration: InputDecoration(labelText: 'Gl Account'),
                        ),
                        menuProps: MenuProps(
                            borderRadius: BorderRadius.circular(20.0)),
                        title: popUp(
                          context: context,
                          title: 'Select GL Account',
                          height: 50,
                        ),
                      ),
                      dropdownDecoratorProps: const DropDownDecoratorProps(
                          dropdownSearchDecoration:
                              InputDecoration(labelText: 'GL Account')),
                      key: const Key('glAccount'),
                      itemAsString: (GlAccount? u) =>
                          " ${u?.accountCode ?? ''} ${u?.accountName ?? ''} ",
                      asyncItems: (String filter) async {
                        glAccountBloc.add(
                            GlAccountFetch(searchString: filter, limit: 3));
                        return Future.delayed(const Duration(milliseconds: 100),
                            () {
                          return Future.value(glAccountBloc.state.glAccounts);
                        });
                      },
                      compareFn: (item, sItem) =>
                          item.accountCode == sItem.accountCode,
                      onChanged: (GlAccount? newValue) {
                        _selectedGlAccount = newValue!;
                      },
                    );
                  default:
                    return const Center(child: CircularProgressIndicator());
                }
              }),
              const SizedBox(height: 20),
              Row(
                children: [
                  ElevatedButton(
                      key: const Key('cancelFinDoc'),
                      child: const Text('Cancel Payment'),
                      onPressed: () {
                        _finDocBloc.add(FinDocUpdate(finDocUpdated.copyWith(
                          status: FinDocStatusVal.cancelled,
                        )));
                      }),
                  const SizedBox(width: 20),
                  Expanded(
                    child: ElevatedButton(
                        key: const Key('update'),
                        child: Text(
                            '${finDoc.idIsNull() ? 'Create ' : 'Update '}${finDocUpdated.docType}'),
                        onPressed: () {
                          if (paymentDialogFormKey.currentState!.validate()) {
                            _finDocBloc.add(FinDocUpdate(finDocUpdated.copyWith(
                              otherCompany: _selectedCompany,
                              grandTotal: Decimal.parse(_amountController.text),
                              pseudoId: _pseudoIdController.text,
                              paymentInstrument: _paymentInstrument,
                              items: [
                                FinDocItem(
                                  paymentType: _selectedPaymentType,
                                  glAccount: _selectedGlAccount,
                                )
                              ],
                            )));
                          }
                        }),
                  ),
                ],
              ),
            ])));
  }
}
