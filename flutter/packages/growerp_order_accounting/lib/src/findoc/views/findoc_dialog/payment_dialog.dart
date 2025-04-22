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

import 'package:universal_io/io.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:decimal/decimal.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:intl/intl.dart';

import '../../../accounting/accounting.dart';
import '../../findoc.dart';

class ShowPaymentDialog extends StatelessWidget {
  final FinDoc finDoc;
  const ShowPaymentDialog(this.finDoc, {super.key});
  @override
  Widget build(BuildContext context) {
    RestClient restClient = context.read<RestClient>();
    return BlocProvider<FinDocBloc>(
        create: (context) => FinDocBloc(
            restClient, finDoc.sales, finDoc.docType!, context.read<String>())
          ..add(FinDocFetch(finDocId: finDoc.id()!, docType: finDoc.docType!)),
        child: BlocBuilder<FinDocBloc, FinDocState>(builder: (context, state) {
          if (state.status == FinDocStatus.success) {
            return PaymentDialog(finDoc: state.finDocs[0]);
          } else {
            return const LoadingIndicator();
          }
        }));
  }
}

class PaymentDialog extends StatefulWidget {
  final FinDoc finDoc;
  final PaymentMethod? paymentMethod;
  const PaymentDialog({required this.finDoc, this.paymentMethod, super.key});
  @override
  PaymentDialogState createState() => PaymentDialogState();
}

class PaymentDialogState extends State<PaymentDialog> {
  final GlobalKey<FormState> paymentDialogFormKey = GlobalKey<FormState>();
  late FinDoc finDoc; // incoming finDoc
  late FinDoc finDocUpdated;
  late FinDocBloc _finDocBloc;
  GlAccount? _selectedGlAccount;
  CompanyUser? _selectedCompanyUser;
  PaymentType? _selectedPaymentType;
  late DataFetchBloc<CompaniesUsers> _companyUserBloc;
  // ignore: unused_field
  late GlAccountBloc _accountBloc; // needed for accountlist
  late FinDocStatusVal _updatedStatus;
  late AuthBloc _authBloc;

  late bool isPhone;
  late bool readOnly;
  late PaymentInstrument _paymentInstrument;
  final _amountController = TextEditingController();
  final _pseudoIdController = TextEditingController();
  late String currencyId;
  late String currencySymbol;

  @override
  void initState() {
    super.initState();
    finDoc = widget.finDoc;
    finDocUpdated = finDoc;
    currencyId = context
        .read<AuthBloc>()
        .state
        .authenticate!
        .company!
        .currency!
        .currencyId!;
    currencySymbol = NumberFormat.simpleCurrency(
            locale: Platform.localeName, name: currencyId)
        .currencySymbol;
    readOnly = finDoc.status == null
        ? false
        : FinDocStatusVal.statusFixed(finDoc.status!);
    _selectedCompanyUser = CompanyUser.tryParse(
        finDocUpdated.otherCompany ?? finDocUpdated.otherUser);
    _selectedGlAccount = finDocUpdated.items.isNotEmpty
        ? finDocUpdated.items[0].glAccount
        : null;
    _updatedStatus = finDocUpdated.status ?? FinDocStatusVal.created;
    _amountController.text = finDoc.grandTotal == null
        ? ''
        : finDoc.grandTotal.currency(currencyId: ''); // not show currency
    _pseudoIdController.text =
        finDoc.pseudoId == null ? '' : finDoc.pseudoId.toString();
    _selectedPaymentType = finDocUpdated.items.isNotEmpty
        ? finDocUpdated.items[0].paymentType
        : null;
    _paymentInstrument = finDocUpdated.paymentInstrument == null
        ? PaymentInstrument.cash
        : finDocUpdated.paymentInstrument!;
    _finDocBloc = context.read<FinDocBloc>();
    _companyUserBloc = context.read<DataFetchBloc<CompaniesUsers>>()
      ..add(GetDataEvent(() => context.read<RestClient>().getCompanyUser(
          limit: 3,
          role: finDoc.sales && finDoc.docType != FinDocType.transaction
              ? Role.customer
              : Role.supplier)));
    _accountBloc = context.read<GlAccountBloc>()
      ..add(const GlAccountFetch(limit: 3));
    _authBloc = context.read<AuthBloc>();
  }

  @override
  Widget build(BuildContext context) {
    isPhone = isAPhone(context);
    return Dialog(
        insetPadding: const EdgeInsets.all(10), // required for wider dialog
        key: Key("PaymentDialog${finDoc.sales ? 'Sales' : 'Purchase'}"),
        child: SingleChildScrollView(
            key: const Key('listView'),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: popUp(
                context: context,
                height: 650,
                width: 800,
                title: "${finDoc.sales ? 'Incoming' : 'Outgoing'} "
                    "Payment #${finDoc.pseudoId ?? 'New'}",
                child: BlocConsumer<FinDocBloc, FinDocState>(
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
                    return SingleChildScrollView(
                        child: paymentForm(state, paymentDialogFormKey));
                  },
                ))));
  }

  DataTable _createGatewayTable() {
    return DataTable(
        dividerThickness: 0,
        dataRowMaxHeight: 50,
        headingRowHeight: 50,
        columnSpacing: 20,
        columns: _createColumns(),
        rows: _createRows());
  }

  List<DataColumn> _createColumns() {
    return [
      if (!isPhone) const DataColumn(label: Text('ID')),
      const DataColumn(label: Text('Operation')),
      if (!isPhone) const DataColumn(label: Text('Method')),
      const DataColumn(label: Text('Amount')),
      const DataColumn(label: Text('Date')),
      const DataColumn(label: Text('OK?')),
    ];
  }

  List<DataRow> _createRows() {
    return finDoc.gatewayResponses
        .map((resp) => DataRow(cells: [
              if (!isPhone) DataCell(Text(resp.gatewayResponseId)),
              DataCell(Text(resp.paymentOperation)),
              if (!isPhone)
                DataCell(Text(resp.paymentMethod?.ccDescription! ?? '')),
              DataCell(Text(resp.amount.toString())),
              DataCell(Text(resp.transactionDate.toString().substring(0, 10))),
              DataCell(Text(resp.resultSuccess ? 'Y' : 'N')),
            ]))
        .toList();
  }

  Widget paymentForm(
      FinDocState state, GlobalKey<FormState> paymentDialogFormKey) {
    if (_selectedPaymentType != null && state.paymentTypes.isNotEmpty) {
      _selectedPaymentType = state.paymentTypes.firstWhere(
          (el) => _selectedPaymentType!.paymentTypeId == el.paymentTypeId);
    }
    Color getColor(Set<WidgetState> states) {
      const Set<WidgetState> interactiveStates = <WidgetState>{
        WidgetState.pressed,
        WidgetState.hovered,
        WidgetState.focused,
      };
      if (states.any(interactiveStates.contains)) {
        return Colors.blue;
      }
      return Colors.red;
    }

    final companyLabel =
        "Select ${finDocUpdated.sales ? 'customer' : 'supplier'}";
    return Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
        child: Form(
            key: paymentDialogFormKey,
            child: Column(children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextFormField(
                      key: const Key('pseudoId'),
                      enabled: !readOnly,
                      decoration: const InputDecoration(labelText: 'Id'),
                      controller: _pseudoIdController,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                      flex: 2,
                      child: BlocBuilder<DataFetchBloc<CompaniesUsers>,
                          DataFetchState>(builder: (context, state) {
                        switch (state.status) {
                          case DataFetchStatus.success:
                            return DropdownSearch<CompanyUser>(
                              enabled: !readOnly,
                              selectedItem: _selectedCompanyUser,
                              popupProps: PopupProps.menu(
                                isFilterOnline: true,
                                showSelectedItems: true,
                                showSearchBox: true,
                                searchFieldProps: TextFieldProps(
                                    autofocus: true,
                                    decoration: InputDecoration(
                                        labelText: companyLabel)),
                                menuProps: MenuProps(
                                    borderRadius: BorderRadius.circular(20.0)),
                                title: popUp(
                                  context: context,
                                  title: companyLabel,
                                  height: 50,
                                ),
                              ),
                              dropdownDecoratorProps: DropDownDecoratorProps(
                                  dropdownSearchDecoration:
                                      InputDecoration(labelText: companyLabel)),
                              key: Key(finDocUpdated.sales
                                  ? 'customer'
                                  : 'supplier'),
                              itemAsString: (CompanyUser? u) => " ${u!.name}",
                              asyncItems: (String filter) {
                                _companyUserBloc.add(GetDataEvent(() => context
                                    .read<RestClient>()
                                    .getCompanyUser(
                                        searchString: filter,
                                        limit: 3,
                                        role: widget.finDoc.sales
                                            ? Role.customer
                                            : Role.supplier)));
                                return Future.delayed(
                                    const Duration(milliseconds: 250), () {
                                  return Future<List<CompanyUser>>.value(
                                      (_companyUserBloc.state.data
                                              as CompaniesUsers)
                                          .companiesUsers);
                                });
                              },
                              compareFn: (item, sItem) =>
                                  item.partyId == sItem.partyId,
                              onChanged: (CompanyUser? newValue) {
                                setState(() {
                                  _selectedCompanyUser = newValue;
                                });
                              },
                              validator: (value) => value == null
                                  ? "Select ${finDocUpdated.sales ? 'Customer' : 'Supplier'}!"
                                  : null,
                            );
                          case DataFetchStatus.failure:
                            return const FatalErrorForm(
                                message: 'server connection problem');
                          default:
                            return const Center(child: LoadingIndicator());
                        }
                      })),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 5, 0, 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<FinDocStatusVal>(
                        key: const Key('statusDropDown'),
                        decoration: InputDecoration(
                            labelText: 'Status', enabled: !readOnly),
                        value: _updatedStatus,
                        validator: (value) =>
                            value == null ? 'field required' : null,
                        items: FinDocStatusVal.validStatusList(
                                finDoc.status ?? FinDocStatusVal.created)
                            .map((label) => DropdownMenuItem<FinDocStatusVal>(
                                  value: label,
                                  child: Text(label.name),
                                ))
                            .toList(),
                        onChanged: readOnly
                            ? null
                            : (FinDocStatusVal? newValue) {
                                _updatedStatus = newValue!;
                              },
                        isExpanded: true,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                          enabled: !readOnly,
                          key: const Key('amount'),
                          decoration: InputDecoration(
                              labelText: 'Amount($currencySymbol)'),
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          validator: (value) =>
                              value!.isEmpty ? "Enter Price or Amount?" : null),
                    ),
                  ],
                ),
              ),
              if (widget.finDoc.id() != null)
                RelatedFinDocs(finDoc: widget.finDoc, context: context),
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 5, 0, 5),
                child: IgnorePointer(
                  ignoring: readOnly,
                  child: DropdownButtonFormField<PaymentType>(
                    decoration: InputDecoration(
                      labelText: 'Payment Type',
                      enabled: !readOnly,
                    ),
                    key: const Key('paymentType'),
                    value: _selectedPaymentType,
                    validator: (value) =>
                        value == null && _selectedGlAccount == null
                            ? 'Enter a item type for posting?'
                            : null,
                    items: state.paymentTypes.map((item) {
                      return DropdownMenuItem<PaymentType>(
                          value: item,
                          child: Text(
                              "${item.paymentTypeName} ${item.accountCode} "
                              "Apply:${item.isApplied ? 'Y' : 'N'}\n"
                              "${item.accountName}",
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2));
                    }).toList(),
                    onChanged: (newValue) => _selectedPaymentType = newValue,
                    isExpanded: true,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              BlocBuilder<GlAccountBloc, GlAccountState>(
                  builder: (context, state) {
                switch (state.status) {
                  case GlAccountStatus.failure:
                    return const FatalErrorForm(
                        message: 'server connection problem');
                  case GlAccountStatus.success:
                    return DropdownSearch<GlAccount>(
                      enabled: !readOnly,
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
                        _accountBloc.add(
                            GlAccountFetch(searchString: filter, limit: 3));
                        return Future.delayed(const Duration(milliseconds: 100),
                            () {
                          return Future.value(_accountBloc.state.glAccounts);
                        });
                      },
                      compareFn: (item, sItem) =>
                          item.accountCode == sItem.accountCode,
                      onChanged: (GlAccount? newValue) {
                        _selectedGlAccount = newValue!;
                      },
                    );
                  default:
                    return const Center(child: LoadingIndicator());
                }
              }),
              const SizedBox(height: 10),
              InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Payment Methods',
                  enabled: !readOnly,
                ),
                child: Column(
                  children: [
                    Row(children: [
                      Checkbox(
                          key: const Key('creditCard'),
                          checkColor: Colors.white,
                          fillColor: WidgetStateProperty.resolveWith(getColor),
                          value: _paymentInstrument ==
                              PaymentInstrument.creditcard,
                          onChanged: (bool? value) {
                            !readOnly
                                ? setState(() {
                                    if (value == true) {
                                      _paymentInstrument =
                                          PaymentInstrument.creditcard;
                                    }
                                  })
                                : null;
                          }),
                      Expanded(
                          child: Text(((finDoc.sales == true &&
                                      _selectedCompanyUser
                                              ?.paymentMethod?.ccDescription !=
                                          null) ||
                                  (finDoc.sales == false &&
                                      _authBloc.state.authenticate?.company
                                              ?.paymentMethod?.ccDescription !=
                                          null))
                              ? "Credit Card ${finDoc.sales == false ? _authBloc.state.authenticate?.company?.paymentMethod?.ccDescription : _selectedCompanyUser?.paymentMethod?.ccDescription}"
                              : 'Credit Card'))
                    ]),
                    Row(children: [
                      Checkbox(
                          key: const Key('cash'),
                          checkColor: Colors.white,
                          fillColor: WidgetStateProperty.resolveWith(getColor),
                          value: _paymentInstrument == PaymentInstrument.cash,
                          onChanged: (bool? value) {
                            !readOnly
                                ? setState(() {
                                    if (value == true) {
                                      _paymentInstrument =
                                          PaymentInstrument.cash;
                                    }
                                  })
                                : null;
                          }),
                      const Text(
                        "Cash",
                      ),
                    ]),
                    Row(children: [
                      Checkbox(
                          key: const Key('check'),
                          checkColor: Colors.white,
                          fillColor: WidgetStateProperty.resolveWith(getColor),
                          value: _paymentInstrument == PaymentInstrument.check,
                          onChanged: (bool? value) {
                            !readOnly
                                ? setState(() {
                                    if (value == true) {
                                      _paymentInstrument =
                                          PaymentInstrument.check;
                                    }
                                  })
                                : null;
                          }),
                      const Text(
                        "Check",
                      ),
                    ]),
                    Row(children: [
                      Checkbox(
                          key: const Key('bank'),
                          checkColor: Colors.white,
                          fillColor: WidgetStateProperty.resolveWith(getColor),
                          value: _paymentInstrument == PaymentInstrument.bank,
                          onChanged: (bool? value) {
                            !readOnly
                                ? setState(() {
                                    if (value == true) {
                                      _paymentInstrument =
                                          PaymentInstrument.bank;
                                    }
                                  })
                                : null;
                          }),
                      Text(
                        "Bank ${finDoc.otherCompany?.paymentMethod?.creditCardNumber ?? ''}",
                      ),
                    ]),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              if (!readOnly)
                Row(
                  children: [
                    OutlinedButton(
                        key: const Key('cancelFinDoc'),
                        child: const Text(
                          'Cancel',
                          softWrap: false,
                        ),
                        onPressed: () {
                          _finDocBloc.add(FinDocUpdate(finDocUpdated.copyWith(
                            status: FinDocStatusVal.cancelled,
                          )));
                        }),
                    const SizedBox(width: 20),
                    Expanded(
                      child: OutlinedButton(
                          key: const Key('update'),
                          child: Text(
                              '${finDoc.idIsNull() ? 'Create ' : 'Update '}${finDocUpdated.docType}'),
                          onPressed: () {
                            if (paymentDialogFormKey.currentState!.validate()) {
                              _finDocBloc
                                  .add(FinDocUpdate(finDocUpdated.copyWith(
                                otherCompany:
                                    _selectedCompanyUser?.getCompany(),
                                otherUser: _selectedCompanyUser?.getUser(),
                                grandTotal:
                                    Decimal.parse(_amountController.text),
                                pseudoId: _pseudoIdController.text,
                                status: _updatedStatus,
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
              const SizedBox(height: 20),
              if (finDoc.gatewayResponses.isNotEmpty)
                InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Gateway Responses',
                      enabled: false,
                    ),
                    child: SizedBox(
                        height: isPhone ? 100 : 150,
                        child: SingleChildScrollView(
                            child: _createGatewayTable()))),
            ])));
  }
}
