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

import 'package:decimal/decimal.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_order_accounting/l10n/generated/order_accounting_localizations.dart';
import 'package:intl/intl.dart';
import 'package:universal_io/io.dart';

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
        restClient,
        finDoc.sales,
        finDoc.docType!,
        context.read<String>(),
      )..add(FinDocFetch(finDocId: finDoc.id()!, docType: finDoc.docType!)),
      child: BlocBuilder<FinDocBloc, FinDocState>(
        builder: (context, state) {
          if (state.status == FinDocStatus.success) {
            return PaymentDialog(finDoc: state.finDocs[0]);
          } else {
            return const LoadingIndicator();
          }
        },
      ),
    );
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
  final _origAmountController = TextEditingController();
  final _pseudoIdController = TextEditingController();
  late String currencyId;
  late String currencySymbol;
  late String origCurrencySymbol;
  late OrderAccountingLocalizations _local;

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
      locale: Platform.localeName,
      name: currencyId,
    ).currencySymbol;
    origCurrencySymbol = NumberFormat.simpleCurrency(
      locale: Platform.localeName,
      name: widget.finDoc.originalCurrency?.currencyId,
    ).currencySymbol;
    readOnly = finDoc.status == null
        ? false
        : FinDocStatusVal.statusFixed(finDoc.status!);
    _selectedCompanyUser = CompanyUser.tryParse(
      finDocUpdated.otherCompany ?? finDocUpdated.otherUser,
    );
    _selectedGlAccount = finDocUpdated.items.isNotEmpty
        ? finDocUpdated.items[0].glAccount
        : null;
    _updatedStatus = finDocUpdated.status ?? FinDocStatusVal.created;
    _amountController.text = finDoc.grandTotal == null
        ? ''
        : finDoc.grandTotal.currency(currencyId: ''); // not show currency
    _pseudoIdController.text = finDoc.pseudoId == null
        ? ''
        : finDoc.pseudoId.toString();
    _selectedPaymentType = finDocUpdated.items.isNotEmpty
        ? finDocUpdated.items[0].paymentType
        : null;
    _paymentInstrument = finDocUpdated.paymentInstrument == null
        ? PaymentInstrument.cash
        : finDocUpdated.paymentInstrument!;
    _finDocBloc = context.read<FinDocBloc>();
    _companyUserBloc = context.read<DataFetchBloc<CompaniesUsers>>()
      ..add(
        GetDataEvent(
          () => context.read<RestClient>().getCompanyUser(
            limit: 3,
            role: finDoc.sales && finDoc.docType != FinDocType.transaction
                ? Role.customer
                : Role.supplier,
          ),
        ),
      );
    _accountBloc = context.read<GlAccountBloc>()
      ..add(const GlAccountFetch(limit: 3));
    _authBloc = context.read<AuthBloc>();
  }

  @override
  Widget build(BuildContext context) {
    isPhone = isAPhone(context);
    _local = OrderAccountingLocalizations.of(context)!;
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
          title:
              "${finDoc.sales ? _local.incoming : _local.outgoing} "
              "${_local.paymentId}${finDoc.pseudoId ?? _local.newItem}",
          child: BlocConsumer<FinDocBloc, FinDocState>(
            listener: (context, state) {
              if (state.status == FinDocStatus.success) {
                Navigator.of(context).pop();
              }
              if (state.status == FinDocStatus.failure) {
                HelperFunctions.showMessage(
                  context,
                  '${state.message}',
                  Colors.red,
                );
              }
            },
            builder: (context, state) {
              if (state.status == FinDocStatus.loading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state.status == FinDocStatus.success) {
                finDoc = finDoc.copyWith(
                  gatewayResponses:
                      state.finDoc?.gatewayResponses ??
                      widget.finDoc.gatewayResponses,
                );
              }
              return SingleChildScrollView(
                child: paymentForm(state, paymentDialogFormKey),
              );
            },
          ),
        ),
      ),
    );
  }

  DataTable _createGatewayTable() {
    return DataTable(
      dividerThickness: 0,
      dataRowMaxHeight: 50,
      headingRowHeight: 50,
      columnSpacing: 20,
      columns: _createColumns(),
      rows: _createRows(),
    );
  }

  List<DataColumn> _createColumns() {
    return [
      if (!isPhone) DataColumn(label: Text(_local.id)),
      DataColumn(label: Text(_local.operation)),
      if (!isPhone) DataColumn(label: Text(_local.method)),
      DataColumn(label: Text(_local.amount)),
      DataColumn(label: Text(_local.date)),
      DataColumn(label: Text(_local.result)),
    ];
  }

  List<DataRow> _createRows() {
    List<DataRow> rows = [];

    for (var resp in finDoc.gatewayResponses) {
      // Add the main data row
      rows.add(
        DataRow(
          cells: [
            if (!isPhone) DataCell(Text(resp.gatewayResponseId)),
            DataCell(Text(resp.paymentOperation)),
            if (!isPhone)
              DataCell(Text(resp.paymentMethod?.ccDescription! ?? '')),
            DataCell(Text(resp.amount != null ? resp.amount.toString() : "")),
            DataCell(Text(resp.transactionDate.dateOnly())),
            DataCell(Text(resp.resultSuccess ? 'Y' : 'N')),
          ],
        ),
      );

      // Add an additional row for result message if it exists
      if (resp.resultMessage != null && resp.resultMessage!.trim().isNotEmpty) {
        rows.add(
          DataRow(
            cells: [
              if (!isPhone) const DataCell(Text('')), // Empty ID cell
              DataCell(
                Text(
                  _local.message,
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              if (!isPhone) const DataCell(Text('')), // Empty Method cell
              DataCell(
                Text(
                  resp.resultMessage!,
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const DataCell(Text('')), // Empty Date cell
              const DataCell(Text('')), // Empty OK cell
            ],
          ),
        );
      }
    }

    return rows;
  }

  Widget paymentForm(
    FinDocState state,
    GlobalKey<FormState> paymentDialogFormKey,
  ) {
    if (_selectedPaymentType != null && state.paymentTypes.isNotEmpty) {
      _selectedPaymentType = state.paymentTypes.firstWhere(
        (el) => _selectedPaymentType!.paymentTypeId == el.paymentTypeId,
        orElse: () => state.paymentTypes.first,
      );
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
        "Select ${finDocUpdated.sales ? _local.customer : _local.supplier}";
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
      child: Form(
        key: paymentDialogFormKey,
        child: Column(
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextFormField(
                    key: const Key('pseudoId'),
                    enabled: !readOnly,
                    decoration: InputDecoration(labelText: _local.id),
                    controller: _pseudoIdController,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: BlocBuilder<DataFetchBloc<CompaniesUsers>, DataFetchState>(
                    builder: (context, state) {
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
                                  labelText: companyLabel,
                                ),
                              ),
                              menuProps: MenuProps(
                                borderRadius: BorderRadius.circular(20.0),
                              ),
                              title: popUp(
                                context: context,
                                title: companyLabel,
                                height: 50,
                              ),
                            ),
                            dropdownDecoratorProps: DropDownDecoratorProps(
                              dropdownSearchDecoration: InputDecoration(
                                labelText: companyLabel,
                              ),
                            ),
                            key: Key(
                              finDocUpdated.sales ? 'customer' : 'supplier',
                            ),
                            itemAsString: (CompanyUser? u) => " ${u!.name}",
                            asyncItems: (String filter) {
                              _companyUserBloc.add(
                                GetDataEvent(
                                  () =>
                                      context.read<RestClient>().getCompanyUser(
                                        searchString: filter,
                                        limit: 3,
                                        role: widget.finDoc.sales
                                            ? Role.customer
                                            : Role.supplier,
                                      ),
                                ),
                              );
                              return Future.delayed(
                                const Duration(milliseconds: 250),
                                () {
                                  return Future<List<CompanyUser>>.value(
                                    (_companyUserBloc.state.data
                                            as CompaniesUsers)
                                        .companiesUsers,
                                  );
                                },
                              );
                            },
                            compareFn: (item, sItem) =>
                                item.partyId == sItem.partyId,
                            onChanged: (CompanyUser? newValue) {
                              setState(() {
                                _selectedCompanyUser = newValue;
                              });
                            },
                            validator: (value) => value == null
                                ? "Select ${finDocUpdated.sales ? _local.customer : _local.supplier}!"
                                : null,
                          );
                        case DataFetchStatus.failure:
                          return const FatalErrorForm(
                            message: 'server connection problem',
                          );
                        default:
                          return const Center(child: LoadingIndicator());
                      }
                    },
                  ),
                ),
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
                        labelText: _local.status,
                        enabled: !readOnly,
                      ),
                      initialValue: _updatedStatus,
                      validator: (value) =>
                          value == null ? 'field required' : null,
                      items:
                          FinDocStatusVal.validStatusList(
                                finDoc.status ?? FinDocStatusVal.created,
                              )
                              .map(
                                (label) => DropdownMenuItem<FinDocStatusVal>(
                                  value: label,
                                  child: Text(label.name),
                                ),
                              )
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
                        labelText: '${_local.amount}($currencySymbol)',
                      ),
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                          value!.isEmpty ? _local.enterAmount : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      enabled: !readOnly,
                      key: const Key('origAmount'),
                      decoration: InputDecoration(
                        labelText: 'OrigAmount($origCurrencySymbol)',
                      ),
                      controller: _origAmountController,
                      keyboardType: TextInputType.number,
                    ),
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
                    labelText: _local.paymentType,
                    enabled: !readOnly,
                  ),
                  key: const Key('paymentType'),
                  initialValue: _selectedPaymentType,
                  validator: (value) =>
                      value == null && _selectedGlAccount == null
                      ? _local.enterPaymentType
                      : null,
                  items: state.paymentTypes.map((item) {
                    return DropdownMenuItem<PaymentType>(
                      value: item,
                      child: Text(
                        "${item.paymentTypeName} ${item.accountCode} "
                        "${_local.apply} ${item.isApplied ? _local.yes : _local.no} ${isPhone ? '\n' : ''}"
                        "${item.accountName}",
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    );
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
                      message: 'server connection problem',
                    );
                  case GlAccountStatus.success:
                    return DropdownSearch<GlAccount>(
                      enabled: !readOnly,
                      selectedItem: _selectedGlAccount,
                      popupProps: PopupProps.menu(
                        isFilterOnline: true,
                        showSelectedItems: true,
                        showSearchBox: true,
                        searchFieldProps: TextFieldProps(
                          autofocus: true,
                          decoration:
                              InputDecoration(labelText: _local.glAccount),
                        ),
                        menuProps: MenuProps(
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        title: popUp(
                          context: context,
                          title: _local.selectGlAccount,
                          height: 50,
                        ),
                      ),
                      dropdownDecoratorProps: DropDownDecoratorProps(
                        dropdownSearchDecoration: InputDecoration(
                          labelText: _local.glAccount,
                        ),
                      ),
                      key: const Key('glAccount'),
                      itemAsString: (GlAccount? u) =>
                          " ${u?.accountCode ?? ''} ${u?.accountName ?? ''} ",
                      asyncItems: (String filter) async {
                        _accountBloc.add(
                          GlAccountFetch(searchString: filter, limit: 3),
                        );
                        return Future.delayed(
                          const Duration(milliseconds: 100),
                          () {
                            return Future.value(_accountBloc.state.glAccounts);
                          },
                        );
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
              },
            ),
            const SizedBox(height: 10),
            InputDecorator(
              decoration: InputDecoration(
                labelText: _local.paymentMethods,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                ),
                enabled: !readOnly,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Checkbox(
                        key: const Key('creditCard'),
                        checkColor: Colors.white,
                        fillColor: WidgetStateProperty.resolveWith(getColor),
                        value:
                            _paymentInstrument == PaymentInstrument.creditcard,
                        onChanged: (bool? value) {
                          !readOnly
                              ? setState(() {
                                  if (value == true) {
                                    _paymentInstrument =
                                        PaymentInstrument.creditcard;
                                  }
                                })
                              : null;
                        },
                      ),
                      Expanded(
                        child: Text(
                          ((finDoc.sales == true &&
                                      _selectedCompanyUser
                                              ?.paymentMethod
                                              ?.ccDescription !=
                                          null) ||
                                  (finDoc.sales == false &&
                                      _authBloc
                                              .state
                                              .authenticate
                                              ?.company
                                              ?.paymentMethod
                                              ?.ccDescription !=
                                          null))
                              ? "${_local.creditCard} ${finDoc.sales == false ? _authBloc.state.authenticate?.company?.paymentMethod?.ccDescription : _selectedCompanyUser?.paymentMethod?.ccDescription}"
                              : _local.creditCard,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Checkbox(
                        key: const Key('cash'),
                        checkColor: Colors.white,
                        fillColor: WidgetStateProperty.resolveWith(getColor),
                        value: _paymentInstrument == PaymentInstrument.cash,
                        onChanged: (bool? value) {
                          !readOnly
                              ? setState(() {
                                  if (value == true) {
                                    _paymentInstrument = PaymentInstrument.cash;
                                  }
                                })
                              : null;
                        },
                      ),
                      Text(_local.cash),
                    ],
                  ),
                  Row(
                    children: [
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
                        },
                      ),
                      Text(_local.check),
                    ],
                  ),
                  Row(
                    children: [
                      Checkbox(
                        key: const Key('bank'),
                        checkColor: Colors.white,
                        fillColor: WidgetStateProperty.resolveWith(getColor),
                        value: _paymentInstrument == PaymentInstrument.bank,
                        onChanged: (bool? value) {
                          !readOnly
                              ? setState(() {
                                  if (value == true) {
                                    _paymentInstrument = PaymentInstrument.bank;
                                  }
                                })
                              : null;
                        },
                      ),
                      Text(
                        "${_local.bank} ${finDoc.otherCompany?.paymentMethod?.creditCardNumber ?? ''}",
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            if (!readOnly)
              Row(
                children: [
                  OutlinedButton(
                    key: const Key('cancelFinDoc'),
                    child: Text(_local.cancel, softWrap: false),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: OutlinedButton(
                      key: const Key('update'),
                      child: Text(
                        '${finDoc.idIsNull() ? _local.create : _local.update} ${finDocUpdated.docType}',
                      ),
                      onPressed: () {
                        if (paymentDialogFormKey.currentState!.validate()) {
                          _finDocBloc.add(
                            FinDocUpdate(
                              finDocUpdated.copyWith(
                                otherCompany: _selectedCompanyUser
                                    ?.getCompany(),
                                otherUser: _selectedCompanyUser?.getUser(),
                                grandTotal: Decimal.parse(
                                  _amountController.text,
                                ),
                                pseudoId: _pseudoIdController.text,
                                status: _updatedStatus,
                                paymentInstrument: _paymentInstrument,
                                items: [
                                  FinDocItem(
                                    paymentType: _selectedPaymentType,
                                    glAccount: _selectedGlAccount,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 20),
            if (finDoc.gatewayResponses.isNotEmpty)
              InputDecorator(
                decoration: InputDecoration(
                  labelText:
                      '${_local.gatewayResponses}(${finDoc.gatewayResponses.length})',
                  enabled: false,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25.0),
                  ),
                ),
                child: SingleChildScrollView(child: _createGatewayTable()),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.finDoc.paymentId != null &&
                    !readOnly &&
                    finDoc.gatewayResponses.any(
                      (e) =>
                          e.paymentOperation == 'Authorize' && e.resultSuccess,
                    ) &&
                    !finDoc.gatewayResponses.any(
                      (e) => e.paymentOperation == 'Release' && e.resultSuccess,
                    ))
                  Padding(
                    padding: const EdgeInsetsGeometry.all(5),
                    child: OutlinedButton(
                      key: const Key('release'),
                      child: Text(_local.release, softWrap: false),
                      onPressed: () {
                        _finDocBloc.add(
                          FinDocGatewayPaymentRelease(widget.finDoc.paymentId!),
                        );
                      },
                    ),
                  ),
                if (widget.finDoc.paymentId != null &&
                    !readOnly &&
                    finDoc.gatewayResponses.any(
                      (e) =>
                          e.paymentOperation == 'Authorize' && e.resultSuccess,
                    ) &&
                    !finDoc.gatewayResponses.any(
                      (e) => e.paymentOperation == 'Release' && e.resultSuccess,
                    ))
                  Padding(
                    padding: const EdgeInsetsGeometry.all(5),
                    child: OutlinedButton(
                      key: const Key('capture'),
                      child: Text(_local.capture, softWrap: false),
                      onPressed: () {
                        _finDocBloc.add(
                          FinDocGatewayPaymentCapture(widget.finDoc.paymentId!),
                        );
                      },
                    ),
                  ),
                if (widget.finDoc.paymentId != null &&
                    !readOnly &&
                    !finDoc.gatewayResponses.any(
                      (e) =>
                          e.paymentOperation == 'Authorize' && e.resultSuccess,
                    ))
                  Padding(
                    padding: const EdgeInsetsGeometry.all(5),
                    child: OutlinedButton(
                      key: const Key('authorize'),
                      child: Text(_local.authorize, softWrap: false),
                      onPressed: () {
                        _finDocBloc.add(
                          FinDocGatewayPaymentAuthorize(
                            widget.finDoc.paymentId!,
                          ),
                        );
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
