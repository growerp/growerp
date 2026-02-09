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
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_order_accounting/growerp_order_accounting.dart';
import 'findoc_item_list_styled_data.dart';

import 'add_another_item_dialog.dart';
import 'add_product_item_dialog.dart';
import 'add_rental_item_dialog.dart';

class ShowFinDocDialog extends StatelessWidget {
  final FinDoc finDoc;
  const ShowFinDocDialog(this.finDoc, {super.key});
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
            return SelectFinDocDialog(finDoc: state.finDocs[0]);
          } else {
            return const LoadingIndicator();
          }
        },
      ),
    );
  }
}

class FinDocDialog extends StatelessWidget {
  final FinDoc finDoc;
  const FinDocDialog(this.finDoc, {super.key});

  @override
  Widget build(BuildContext context) {
    RestClient restClient = context.read<RestClient>();

    //  if (finDoc.status != null && !FinDocStatusVal.statusFixed(finDoc.status!)) {
    if (finDoc.sales) {
      return BlocProvider<SalesCartBloc>(
        create: (context) => CartBloc(
          docType: finDoc.docType!,
          sales: true,
          finDocBloc: finDoc.docType == FinDocType.order
              ? context.read<SalesOrderBloc>() as FinDocBloc
              : finDoc.docType == FinDocType.invoice
              ? context.read<SalesInvoiceBloc>() as FinDocBloc
              : finDoc.docType == FinDocType.shipment
              ? context.read<OutgoingShipmentBloc>() as FinDocBloc
              : context.read<TransactionBloc>() as FinDocBloc,
          restClient: restClient,
        )..add(CartFetch(finDoc)),
        child: FinDocPage(finDoc),
      );
    }
    return BlocProvider<PurchaseCartBloc>(
      create: (context) => CartBloc(
        docType: finDoc.docType!,
        sales: false,
        finDocBloc: finDoc.docType == FinDocType.order
            ? context.read<PurchaseOrderBloc>() as FinDocBloc
            : finDoc.docType == FinDocType.invoice
            ? context.read<PurchaseInvoiceBloc>() as FinDocBloc
            : finDoc.docType == FinDocType.shipment
            ? context.read<IncomingShipmentBloc>() as FinDocBloc
            : context.read<TransactionBloc>() as FinDocBloc,
        restClient: restClient,
      )..add(CartFetch(finDoc)),
      child: FinDocPage(finDoc),
    );
    //  } else
    //    return FinDocPage(finDoc);
  }
}

class FinDocPage extends StatefulWidget {
  final FinDoc finDoc;
  const FinDocPage(this.finDoc, {super.key});
  @override
  MyFinDocState createState() => MyFinDocState();
}

class MyFinDocState extends State<FinDocPage> {
  final _formKeyHeader = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _pseudoIdController = TextEditingController();
  late CartBloc _cartBloc;
  late DataFetchBloc<Products> _productBloc;
  late GlAccountBloc _glAccountBloc;
  late FinDocBloc _finDocBloc;
  late String classificationId;
  late FinDoc finDocUpdated;
  late FinDoc finDoc; // incoming finDoc
  bool? _isPosted = false;
  CompanyUser? _selectedCompanyUser;
  late bool isPhone;
  late bool readOnly;
  late FinDocStatusVal _updatedStatus;
  late String currencyId;
  late double screenWidth;
  late OrderAccountingLocalizations _localizations;
  bool _shouldCloseOnFinDocSuccess = false;

  String _getDocTypeLabel(FinDocType docType) {
    switch (docType) {
      case FinDocType.request:
        return _localizations.docTypeRequest;
      case FinDocType.order:
        return _localizations.docTypeOrder;
      case FinDocType.invoice:
        return _localizations.docTypeInvoice;
      case FinDocType.payment:
        return _localizations.docTypePayment;
      case FinDocType.shipment:
        return _localizations.docTypeShipment;
      case FinDocType.transaction:
        return _localizations.docTypeTransaction;
      default:
        return '';
    }
  }

  @override
  void initState() {
    super.initState();
    finDoc = widget.finDoc;
    finDocUpdated = finDoc;
    classificationId = context.read<String>();
    currencyId = context
        .read<AuthBloc>()
        .state
        .authenticate!
        .company!
        .currency!
        .currencyId!;
    readOnly = finDoc.status == null
        ? false
        : FinDocStatusVal.statusFixed(finDoc.status!);
    _isPosted = finDocUpdated.isPosted ?? false;
    _updatedStatus = finDocUpdated.status ?? FinDocStatusVal.created;
    _selectedCompanyUser = CompanyUser.tryParse(
      finDocUpdated.otherCompany ?? finDocUpdated.otherUser,
    );
    _pseudoIdController.text = finDocUpdated.pseudoId ?? '';
    _finDocBloc = context.read<FinDocBloc>();
    context.read<DataFetchBloc<CompaniesUsers>>().add(
      GetDataEvent(
        () => context.read<RestClient>().getCompanyUser(
          limit: 100,
          role: finDoc.sales && finDoc.docType != FinDocType.transaction
              ? Role.customer
              : Role.supplier,
        ),
      ),
    );
    _glAccountBloc = context.read<GlAccountBloc>();
    _glAccountBloc.add(const GlAccountFetch(limit: 100));
    _productBloc = context.read<DataFetchBloc<Products>>()
      ..add(
        GetDataEvent(
          () => context.read<RestClient>().getProduct(
            limit: 100,
            isForDropDown: true,
            assetClassId: classificationId == 'AppHotel' ? 'Hotel Room' : '',
          ),
        ),
      );
    _descriptionController.text = finDocUpdated.description ?? " ";
    if (finDoc.sales) {
      _cartBloc = context.read<SalesCartBloc>() as CartBloc;
    } else {
      _cartBloc = context.read<PurchaseCartBloc>() as CartBloc;
    }
  }

  @override
  Widget build(BuildContext context) {
    isPhone = isAPhone(context);
    screenWidth = isPhone ? 400 : 900;
    _localizations = OrderAccountingLocalizations.of(context)!;

    blocConsumerListener(
      BuildContext context,
      CartState state, [
      bool mounted = true,
    ]) {
      switch (state.status) {
        case CartStatus.saving:
          // Mark that we should close when FinDocBloc succeeds
          _shouldCloseOnFinDocSuccess = true;
          break;
        case CartStatus.complete:
          // Only close immediately if we're not waiting for FinDocBloc update
          if (!_shouldCloseOnFinDocSuccess) {
            Navigator.of(context).pop(finDocUpdated);
          }
          break;
        case CartStatus.failure:
          _shouldCloseOnFinDocSuccess = false;
          HelperFunctions.showMessage(context, '${state.message}', Colors.red);
          break;
        default:
          return const Center(child: LoadingIndicator());
      }
    }

    blocConsumerBuilder(BuildContext context, CartState state) {
      switch (state.status) {
        case CartStatus.inProcess:
          finDocUpdated = state.finDoc;
          return Column(
            children: [
              // header
              widget.finDoc.docType == FinDocType.transaction
                  ? headerEntryTransaction()
                  : headerEntry(),
              // related documents
              RelatedFinDocs(finDoc: finDocUpdated, context: context),
              // update buttons
              const SizedBox(height: 10),
              if (!readOnly) updateButtons(state),
              const SizedBox(height: 10),
              widget.finDoc.docType == FinDocType.transaction
                  ? finDocItemListTransaction(state)
                  : widget.finDoc.docType == FinDocType.shipment
                  ? finDocItemListShipment(state)
                  : finDocItemList(state),
              const SizedBox(height: 10),
              if (finDoc.docType == FinDocType.shipment)
                Text("Items# ${finDocUpdated.items.length}"),
              if (finDoc.docType != FinDocType.shipment)
                Text(
                  "Items# ${finDocUpdated.items.length}   "
                  "Grand total : ${finDocUpdated.grandTotal.currency(currencyId: currencyId)}",
                  key: const Key('grandTotal'),
                ),
              const SizedBox(height: 10),
              if (!readOnly) generalButtons(),
            ],
          );
        default:
          return const LoadingIndicator();
      }
    }

    return Dialog(
      key: Key(
        "FinDocDialog${finDoc.sales == true ? 'Sales' : 'Purchase'}"
        "${finDoc.docType}",
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.all(10),
      child: SingleChildScrollView(
        key: const Key('listView'),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: popUp(
          title: finDoc.docType == FinDocType.transaction
              ? "${_getDocTypeLabel(finDoc.docType!)} #${finDoc.pseudoId ?? _localizations.newItem}"
              : "${finDoc.sales ? _localizations.sales : _localizations.purchase} ${_getDocTypeLabel(finDoc.docType!)}"
                    " #${finDoc.pseudoId ?? _localizations.newItem}",
          height: 650,
          width: screenWidth,
          context: context,
          child: BlocListener<FinDocBloc, FinDocState>(
            listener: (context, finDocState) {
              // Close dialog when FinDocBloc successfully updates and we're waiting for it
              if (finDocState.status == FinDocStatus.success &&
                  _shouldCloseOnFinDocSuccess) {
                _shouldCloseOnFinDocSuccess = false;
                Navigator.of(context).pop(finDocUpdated);
              }
            },
            child: Builder(
              builder: (BuildContext context) {
                if (finDoc.sales) {
                  return BlocConsumer<SalesCartBloc, CartState>(
                    listener: blocConsumerListener,
                    builder: blocConsumerBuilder,
                  );
                }
                // purchase from here
                return BlocConsumer<PurchaseCartBloc, CartState>(
                  listener: blocConsumerListener,
                  builder: blocConsumerBuilder,
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  /// list the widgets list either in a single column for phone
  /// or 2 columns for the web.
  Widget headerEntry() {
    // list of widgets to display
    List<Widget> widgets = [
      Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SizedBox(
                width: 80,
                child: TextFormField(
                  key: const Key('pseudoId'),
                  enabled: !readOnly,
                  decoration: InputDecoration(
                    labelText: _localizations.finDocId,
                  ),
                  controller: _pseudoIdController,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 10),
              BlocBuilder<
                DataFetchBloc<CompaniesUsers>,
                DataFetchState<CompaniesUsers>
              >(
                builder: (context, state) {
                  switch (state.status) {
                    case DataFetchStatus.failure:
                    case DataFetchStatus.success:
                      final companyUsers =
                          (state.data as CompaniesUsers).companiesUsers;
                      return Expanded(
                        child: Autocomplete<CompanyUser>(
                          key: Key(
                            finDocUpdated.sales ? 'customer' : 'supplier',
                          ),
                          initialValue: TextEditingValue(
                            text: _selectedCompanyUser != null
                                ? "${_selectedCompanyUser!.name}[${_selectedCompanyUser!.pseudoId}]"
                                : '',
                          ),
                          displayStringForOption: (CompanyUser u) =>
                              "${u.name}[${u.pseudoId}]",
                          optionsBuilder: (TextEditingValue textEditingValue) {
                            final query = textEditingValue.text
                                .toLowerCase()
                                .trim();
                            if (query.isEmpty) return companyUsers;
                            return companyUsers.where((cu) {
                              final display = "${cu.name}[${cu.pseudoId}]"
                                  .toLowerCase();
                              return display.contains(query);
                            }).toList();
                          },
                          fieldViewBuilder:
                              (
                                context,
                                textController,
                                focusNode,
                                onFieldSubmitted,
                              ) {
                                return TextFormField(
                                  key: Key(
                                    finDocUpdated.sales
                                        ? 'customerField'
                                        : 'supplierField',
                                  ),
                                  enabled: !readOnly,
                                  controller: textController,
                                  focusNode: focusNode,
                                  decoration: InputDecoration(
                                    labelText: finDocUpdated.sales
                                        ? _localizations.customer
                                        : _localizations.supplier,
                                  ),
                                  onFieldSubmitted: (_) => onFieldSubmitted(),
                                  validator: (value) =>
                                      (value == null || value.isEmpty)
                                      ? "${_localizations.select} ${finDocUpdated.sales ? _localizations.customer : _localizations.supplier}!"
                                      : null,
                                );
                              },
                          optionsViewBuilder: (context, onSelected, options) {
                            return Align(
                              alignment: Alignment.topLeft,
                              child: Material(
                                elevation: 4,
                                borderRadius: BorderRadius.circular(12),
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxHeight: 250,
                                    maxWidth: 400,
                                  ),
                                  child: ListView.builder(
                                    padding: EdgeInsets.zero,
                                    shrinkWrap: true,
                                    itemCount: options.length,
                                    itemBuilder: (context, idx) {
                                      final cu = options.elementAt(idx);
                                      return ListTile(
                                        dense: true,
                                        title: Text(
                                          "${cu.name}[${cu.pseudoId}]",
                                        ),
                                        onTap: () => onSelected(cu),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            );
                          },
                          onSelected: (CompanyUser newValue) {
                            setState(() {
                              _selectedCompanyUser = newValue;
                            });
                          },
                        ),
                      );
                    default:
                      return const Center(child: LoadingIndicator());
                  }
                },
              ),
            ],
          ),
          if (finDoc.placedDate != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "${_localizations.created}: ${finDoc.creationDate.toLocalizedDateOnly(context)}",
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "${_localizations.placed}: ${finDoc.placedDate!.toLocalizedDateOnly(context)}",
                  ),
                ],
              ),
            ),
        ],
      ),
      Padding(
        padding: const EdgeInsets.all(5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            SizedBox(
              width: 145,
              child: DropdownButtonFormField<FinDocStatusVal>(
                key: const Key('statusDropDown'),
                decoration: InputDecoration(
                  labelText: _localizations.status,
                  enabled: !readOnly,
                ),
                initialValue: _updatedStatus,
                validator: (value) =>
                    value == null ? _localizations.fieldRequired : null,
                items: FinDocStatusVal.validStatusList(_updatedStatus)
                    .map(
                      (label) => DropdownMenuItem<FinDocStatusVal>(
                        value: label,
                        child: Text(
                          classificationId == 'AppHotel'
                              ? label.hotel
                              : label.name,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: readOnly
                    ? null
                    : (FinDocStatusVal? newValue) {
                        setState(() {
                          _updatedStatus = newValue!;
                        });
                      },
                isExpanded: true,
              ),
            ),
            Expanded(
              child: TextFormField(
                key: const Key('description'),
                readOnly: readOnly,
                decoration: InputDecoration(
                  labelText:
                      '${_getDocTypeLabel(finDoc.docType!)} ${_localizations.description}',
                  enabled: !readOnly,
                ),
                controller: _descriptionController,
              ),
            ),
          ],
        ),
      ),
    ];

    return SizedBox(
      //  height: isPhone ? 210 : 100,
      child: Form(
        key: _formKeyHeader,
        child: isPhone
            ? Column(children: widgets)
            : Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: widgets[0]),
                  Expanded(child: widgets[1]),
                ],
              ),
      ),
    );
  }

  Widget headerEntryTransaction() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    key: const Key('pseudoId'),
                    enabled: !readOnly,
                    decoration: InputDecoration(labelText: _localizations.id),
                    controller: _pseudoIdController,
                    keyboardType: TextInputType.number,
                  ),
                ),

                Text(_localizations.posted),
                const SizedBox(width: 20),
                Expanded(
                  child: Row(
                    children: [
                      Text(_localizations.no),
                      Switch(
                        key: const Key('isPosted'),
                        value: _isPosted ?? false,
                        onChanged: readOnly
                            ? null
                            : (bool value) {
                                setState(() {
                                  _isPosted = value;
                                });
                              },
                      ),
                      Text(_localizations.yes),
                    ],
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText:
                          '${_getDocTypeLabel(finDoc.docType!)} ${_localizations.type}',
                    ),
                    child: Text(finDoc.docSubType ?? ''),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    key: const Key('description'),
                    readOnly: readOnly,
                    decoration: InputDecoration(
                      labelText:
                          '${finDoc.docType} ${_localizations.description}',
                      enabled: !readOnly,
                    ),
                    controller: _descriptionController,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget updateButtons(dynamic state) {
    List<Widget> buttons = [
      OutlinedButton(
        key: const Key('header'),
        child: Text(_localizations.updateHeader),
        onPressed: () {
          _cartBloc.add(
            CartHeader(
              finDocUpdated.copyWith(
                otherCompany: _selectedCompanyUser?.getCompany(),
                otherUser: _selectedCompanyUser?.getUser(),
                description: _descriptionController.text,
                isPosted: _isPosted,
              ),
            ),
          );
        },
      ),
      OutlinedButton(
        key: const Key('addItem'),
        child: Text(
          widget.finDoc.docType == FinDocType.transaction
              ? _localizations.addTransactionItem
              : _localizations.addOtherItem,
        ),
        onPressed: () async {
          final dynamic finDocItem;
          if (widget.finDoc.docType != FinDocType.transaction) {
            finDocItem = await addAnotherItemDialog(
              context,
              finDocUpdated.sales,
              state,
            );
          } else {
            finDocItem = await addTransactionItemDialog(
              context,
              finDocUpdated.sales,
              state,
            );
          }
          if (finDocItem != null) {
            _cartBloc.add(
              CartAdd(
                finDoc: finDocUpdated.copyWith(
                  otherCompany: _selectedCompanyUser?.getCompany(),
                  otherUser: _selectedCompanyUser?.getUser(),
                  description: _descriptionController.text,
                  isPosted: _isPosted,
                ),
                newItem: finDocItem,
              ),
            );
          }
        },
      ),
      if (widget.finDoc.docType == FinDocType.order)
        OutlinedButton(
          key: const Key('itemRental'),
          child: Text(_localizations.addRental),
          onPressed: () async {
            final dynamic finDocItem = await addRentalItemDialog(
              context,
              _productBloc,
              _finDocBloc,
            );
            if (finDocItem != null) {
              _cartBloc.add(
                CartAdd(
                  finDoc: finDocUpdated.copyWith(
                    otherCompany: _selectedCompanyUser?.getCompany(),
                    otherUser: _selectedCompanyUser?.getUser(),
                    description: _descriptionController.text,
                  ),
                  newItem: finDocItem,
                ),
              );
            }
          },
        ),
      if (widget.finDoc.docType != FinDocType.transaction)
        OutlinedButton(
          key: const Key('addProduct'),
          child: Text(_localizations.addProduct),
          onPressed: () async {
            final dynamic finDocItem = await addProductItemDialog(context);
            if (finDocItem != null) {
              _cartBloc.add(
                CartAdd(
                  finDoc: finDocUpdated.copyWith(
                    otherCompany: _selectedCompanyUser?.getCompany(),
                    otherUser: _selectedCompanyUser?.getUser(),
                    description: _descriptionController.text,
                  ),
                  newItem: finDocItem,
                ),
              );
            }
          },
        ),
    ];

    if (isPhone) {
      List<Widget> rows = [];
      for (var i = 0; i < buttons.length; i++) {
        rows.add(
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 0, 5, 5),
                  child: buttons[i],
                ),
              ),
              if (++i < buttons.length)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(5, 0, 10, 5),
                    child: buttons[i],
                  ),
                ),
            ],
          ),
        );
      }
      return Column(children: rows);
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: buttons,
    );
  }

  Widget generalButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: <Widget>[
        Visibility(
          visible: !finDoc.idIsNull(),
          child: OutlinedButton(
            key: const Key('cancelFinDoc'),
            child: Text(_localizations.cancelFinDoc),
            onPressed: () {
              _cartBloc.add(CartCancelFinDoc(finDocUpdated));
            },
          ),
        ),
        const SizedBox(width: 5),
        OutlinedButton(
          key: const Key('clear'),
          child: Text(_localizations.clearCart),
          onPressed: () {
            if (finDocUpdated.items.isNotEmpty) {
              _cartBloc.add(CartClear());
            }
          },
        ),
        const SizedBox(width: 5),
        Expanded(
          child: OutlinedButton(
            key: const Key('update'),
            child: Text(
              "${finDoc.idIsNull() ? _localizations.create : _localizations.update} "
              "${_getDocTypeLabel(finDocUpdated.docType!)}",
            ),
            onPressed: () {
              finDocUpdated = finDocUpdated.copyWith(
                // set order to created, others not. inprep only used by website.
                status: _updatedStatus,
                otherCompany: _selectedCompanyUser?.getCompany(),
                otherUser: _selectedCompanyUser?.getUser(),
                description: _descriptionController.text,
                isPosted: _isPosted,
              );
              if ((finDocUpdated.docType == FinDocType.transaction &&
                      finDocUpdated.items.isNotEmpty) ||
                  (finDocUpdated.items.isNotEmpty &&
                      (finDocUpdated.otherCompany != null ||
                          finDocUpdated.otherUser != null))) {
                _cartBloc.add(CartCreateFinDoc(finDocUpdated));
              } else {
                HelperFunctions.showMessage(
                  context,
                  _localizations.itemOrCustomerRequired(
                    (finDocUpdated.sales
                        ? _localizations.customer
                        : _localizations.supplier),
                    _getDocTypeLabel(finDocUpdated.docType!),
                  ),
                  Colors.red,
                );
              }
            },
          ),
        ),
      ],
    );
  }

  Widget finDocItemList(CartState state) {
    List<FinDocItem> items = finDocUpdated.items;
    String currencyId = context
        .read<AuthBloc>()
        .state
        .authenticate!
        .company!
        .currency!
        .currencyId!;

    final rows = items.map((item) {
      final index = items.indexOf(item);
      final itemType = item.itemType != null && state.itemTypes.isNotEmpty
          ? state.itemTypes.firstWhere(
              (e) => e.itemTypeId == item.itemType!.itemTypeId,
              orElse: () => ItemType(),
            )
          : ItemType();
      return getFinDocItemListRow(
        context: context,
        item: item,
        index: index,
        currencyId: currencyId,
        itemType: itemType,
        readOnly: readOnly,
        onDelete: () => _cartBloc.add(CartDeleteItem(index)),
      );
    }).toList();

    return Flexible(
      child: items.isEmpty
          ? Text(_localizations.noItems)
          : StyledDataTable(
              columns: getFinDocItemListColumns(context),
              rows: rows,
            ),
    );
  }

  Widget finDocItemListShipment(CartState state) {
    List<FinDocItem> items = finDocUpdated.items;
    final rows = items.map((item) {
      final index = items.indexOf(item);
      return getFinDocItemListShipmentRow(
        context: context,
        item: item,
        index: index,
        readOnly: readOnly,
        finDocStatus: finDoc.status,
        onDelete: () => _cartBloc.add(CartDeleteItem(index)),
      );
    }).toList();

    return Flexible(
      child: items.isEmpty
          ? Text(_localizations.noItems)
          : StyledDataTable(
              columns: getFinDocItemListShipmentColumns(context, finDoc),
              rows: rows,
            ),
    );
  }

  Widget finDocItemListTransaction(CartState state) {
    List<FinDocItem> items = finDocUpdated.items;
    String currencyId = context
        .read<AuthBloc>()
        .state
        .authenticate!
        .company!
        .currency!
        .currencyId!;

    final rows = items.map((item) {
      final index = items.indexOf(item);
      return getFinDocItemListTransactionRow(
        context: context,
        item: item,
        index: index,
        currencyId: currencyId,
        readOnly: readOnly,
        onDelete: () => _cartBloc.add(CartDeleteItem(index)),
      );
    }).toList();

    return items.isEmpty
        ? Text(_localizations.noItems)
        : Flexible(
            child: Padding(
              padding: const EdgeInsets.only(left: 10.0),
              child: StyledDataTable(
                columns: getFinDocItemListTransactionColumns(context),
                rows: rows,
              ),
            ),
          );
  }

  Future addTransactionItemDialog(
    BuildContext context,
    bool sales,
    CartState state,
  ) async {
    final priceController = TextEditingController(text: '');
    bool? isDebit = true;
    GlAccount? selectedGlAccount;
    GlAccountBloc glAccountBloc = context.read<GlAccountBloc>()
      ..add(const GlAccountFetch(limit: 3));
    return showDialog<FinDocItem>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        var addOtherFormKey = GlobalKey<FormState>();
        return BlocProvider.value(
          value: glAccountBloc,
          child: Dialog(
            key: const Key('addTransactionItemDialog'),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(20)),
            ),
            child: popUp(
              context: context,
              height: 400,
              title: _localizations.addTransactionItemTitle,
              child: Form(
                key: addOtherFormKey,
                child: SingleChildScrollView(
                  key: const Key('listView2'),
                  child: Column(
                    children: <Widget>[
                      BlocBuilder<GlAccountBloc, GlAccountState>(
                        builder: (context, state) {
                          switch (state.status) {
                            case GlAccountStatus.failure:
                              return FatalErrorForm(
                                message: _localizations.serverProblem,
                              );
                            case GlAccountStatus.success:
                              return Autocomplete<GlAccount>(
                                key: const Key('glAccount'),
                                initialValue: TextEditingValue(
                                  text: selectedGlAccount != null
                                      ? " ${selectedGlAccount?.accountCode} ${selectedGlAccount?.accountName} "
                                      : '',
                                ),
                                displayStringForOption: (GlAccount u) =>
                                    " ${u.accountCode} ${u.accountName} ",
                                optionsBuilder:
                                    (TextEditingValue textEditingValue) {
                                      final query = textEditingValue.text
                                          .toLowerCase()
                                          .trim();
                                      if (query.isEmpty) {
                                        return state.glAccounts;
                                      }
                                      return state.glAccounts.where((gl) {
                                        final display =
                                            " ${gl.accountCode} ${gl.accountName} "
                                                .toLowerCase();
                                        return display.contains(query);
                                      }).toList();
                                    },
                                fieldViewBuilder:
                                    (
                                      context,
                                      textController,
                                      focusNode,
                                      onFieldSubmitted,
                                    ) {
                                      return TextFormField(
                                        key: const Key('glAccountField'),
                                        controller: textController,
                                        focusNode: focusNode,
                                        decoration: InputDecoration(
                                          labelText: _localizations.glAccount,
                                        ),
                                        onFieldSubmitted: (_) =>
                                            onFieldSubmitted(),
                                      );
                                    },
                                optionsViewBuilder: (context, onSelected, options) {
                                  return Align(
                                    alignment: Alignment.topLeft,
                                    child: Material(
                                      elevation: 4,
                                      borderRadius: BorderRadius.circular(12),
                                      child: ConstrainedBox(
                                        constraints: const BoxConstraints(
                                          maxHeight: 250,
                                          maxWidth: 400,
                                        ),
                                        child: ListView.builder(
                                          padding: EdgeInsets.zero,
                                          shrinkWrap: true,
                                          itemCount: options.length,
                                          itemBuilder: (context, idx) {
                                            final gl = options.elementAt(idx);
                                            return ListTile(
                                              dense: true,
                                              title: Text(
                                                " ${gl.accountCode} ${gl.accountName} ",
                                              ),
                                              onTap: () => onSelected(gl),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                onSelected: (GlAccount newValue) {
                                  selectedGlAccount = newValue;
                                },
                              );
                            default:
                              return const Center(child: LoadingIndicator());
                          }
                        },
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              key: const Key('price'),
                              decoration: InputDecoration(
                                labelText: _localizations.amount,
                              ),
                              controller: priceController,
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value!.isEmpty) {
                                  return _localizations.enterAmount;
                                }
                                return null;
                              },
                            ),
                          ),
                          Text(_localizations.credit),
                          StatefulBuilder(
                            builder: (context, setState) {
                              return Switch(
                                key: const Key('isDebit'),
                                value: isDebit ?? true,
                                onChanged: (bool value) {
                                  setState(() {
                                    isDebit = value;
                                  });
                                },
                              );
                            },
                          ),
                          Text(_localizations.debit),
                        ],
                      ),

                      const SizedBox(height: 20),
                      OutlinedButton(
                        key: const Key('ok'),
                        child: Text(_localizations.ok),
                        onPressed: () {
                          if (addOtherFormKey.currentState!.validate()) {
                            Navigator.of(context).pop(
                              FinDocItem(
                                glAccount: selectedGlAccount,
                                isDebit: isDebit,
                                price: Decimal.parse(priceController.text),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
