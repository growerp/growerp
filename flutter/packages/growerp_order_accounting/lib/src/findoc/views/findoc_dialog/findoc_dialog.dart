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
import 'package:growerp_order_accounting/growerp_order_accounting.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

import 'add_another_item_dialog.dart';
import 'add_product_item_dialog.dart';
import 'add_rental_item_dialog.dart';
import 'add_transaction_item_dialog.dart';

class ShowFinDocDialog extends StatelessWidget {
  final FinDoc finDoc;
  const ShowFinDocDialog(this.finDoc, {super.key});
  @override
  Widget build(BuildContext context) {
    RestClient restClient = context.read<RestClient>();
    return BlocProvider<FinDocBloc>(
        create: (context) => FinDocBloc(
            restClient, finDoc.sales, finDoc.docType!, context.read<String>())
          ..add(FinDocFetch(finDocId: finDoc.id()!, docType: finDoc.docType!)),
        child: BlocBuilder<FinDocBloc, FinDocState>(builder: (context, state) {
          if (state.status == FinDocStatus.success) {
            return SelectFinDocDialog(finDoc: state.finDocs[0]);
          } else {
            return const LoadingIndicator();
          }
        }));
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
              restClient: restClient)
            ..add(CartFetch(finDoc)),
          child: FinDocPage(finDoc));
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
            restClient: restClient)
          ..add(CartFetch(finDoc)),
        child: FinDocPage(finDoc));
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
  final _companySearchBoxController = TextEditingController();
  final _pseudoIdController = TextEditingController();
  late CartBloc _cartBloc;
  late DataFetchBloc<Companies> _companyBloc;
  late DataFetchBloc<Products> _productBloc;
  late GlAccountBloc _glAccountBloc;
  late FinDocBloc _finDocBloc;
  late String classificationId;
  late FinDoc finDocUpdated;
  late FinDoc finDoc; // incoming finDoc
  bool? _isPosted = false;
  Company? _selectedCompany;
  late bool isPhone;
  late bool readOnly;
  late FinDocStatusVal _updatedStatus;

  @override
  void initState() {
    super.initState();
    finDoc = widget.finDoc;
    finDocUpdated = finDoc;
    classificationId = context.read<String>();
    readOnly = finDoc.status == null
        ? false
        : FinDocStatusVal.statusFixed(finDoc.status!);
    _isPosted = finDocUpdated.isPosted ?? false;
    _updatedStatus = finDocUpdated.status ?? FinDocStatusVal.created;
    _selectedCompany = finDocUpdated.otherCompany ?? finDocUpdated.otherCompany;
    _pseudoIdController.text = finDocUpdated.pseudoId ?? '';
    _finDocBloc = context.read<FinDocBloc>();
    _companyBloc = context.read<DataFetchBloc<Companies>>()
      ..add(GetDataEvent(() => context.read<RestClient>().getCompany(
          limit: 3,
          role: finDoc.sales && finDoc.docType != FinDocType.transaction
              ? Role.customer
              : Role.supplier)));
    _glAccountBloc = context.read<GlAccountBloc>();
    _glAccountBloc.add(const GlAccountFetch(limit: 3));
    _productBloc = context.read<DataFetchBloc<Products>>()
      ..add(GetDataEvent(() => context.read<RestClient>().getProduct(
          limit: 3,
          isForDropDown: true,
          assetClassId: classificationId == 'AppHotel' ? 'Hotel Room' : '')));
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

    blocConsumerListener(BuildContext context, CartState state,
        [bool mounted = true]) async {
      switch (state.status) {
        case CartStatus.complete:
          Navigator.of(context).pop();
          break;
        case CartStatus.failure:
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
          return Column(children: [
            // header
            widget.finDoc.docType == FinDocType.transaction
                ? headerEntryTransaction()
                : headerEntry(),
            // related documents
            relatedFinDocs(finDoc: finDocUpdated, context: context),
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
                  "Grand total : ${finDocUpdated.grandTotal.currency()}",
                  key: const Key('grandTotal')),
            const SizedBox(height: 10),
            if (!readOnly) generalButtons(),
          ]);
        default:
          return const LoadingIndicator();
      }
    }

    return Scaffold(
        backgroundColor: Colors.transparent,
        body: Dialog(
            key:
                Key("FinDocDialog${finDoc.sales == true ? 'Sales' : 'Purchase'}"
                    "${finDoc.docType}"),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            insetPadding: const EdgeInsets.all(10),
            child: SingleChildScrollView(
                key: const Key('listView'),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: popUp(
                  title:
                      "${finDoc.sales ? 'Sales' : 'Purchase'} ${finDoc.docType} "
                      "#${finDoc.pseudoId ?? ' new'}",
                  height: 650,
                  width: isPhone ? 400 : 800,
                  context: context,
                  child: Builder(builder: (BuildContext context) {
                    if (finDoc.sales) {
                      return BlocConsumer<SalesCartBloc, CartState>(
                          listener: blocConsumerListener,
                          builder: blocConsumerBuilder);
                    }
                    // purchase from here
                    return BlocConsumer<PurchaseCartBloc, CartState>(
                        listener: blocConsumerListener,
                        builder: blocConsumerBuilder);
                  }),
                ))));
  }

  /// list the widgets list either in a single column for phone
  /// or 2 columns for the web.
  Widget headerEntry() {
    // list of widgets to display
    List<Widget> widgets = [
      BlocBuilder<DataFetchBloc<Companies>, DataFetchState>(
          builder: (context, state) {
        switch (state.status) {
          case DataFetchStatus.failure:
            return const FatalErrorForm(message: 'server connection problem');
          case DataFetchStatus.loading:
            return LoadingIndicator();
          case DataFetchStatus.success:
            return Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SizedBox(
                    width: 115,
                    child: TextFormField(
                      key: const Key('pseudoId'),
                      decoration: const InputDecoration(labelText: 'Id'),
                      controller: _pseudoIdController,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  Expanded(
                    child: DropdownSearch<Company>(
                      enabled: !readOnly,
                      selectedItem: _selectedCompany,
                      popupProps: PopupProps.menu(
                        isFilterOnline: true,
                        showSearchBox: true,
                        searchFieldProps: TextFieldProps(
                          autofocus: true,
                          decoration: InputDecoration(
                              labelText:
                                  "${finDocUpdated.sales ? 'Customer' : 'Supplier'} name"),
                          controller: _companySearchBoxController,
                        ),
                        title: popUp(
                          context: context,
                          title:
                              "Select ${finDocUpdated.sales ? 'Customer' : 'Supplier'}",
                          height: 50,
                        ),
                      ),
                      dropdownDecoratorProps: DropDownDecoratorProps(
                        dropdownSearchDecoration: InputDecoration(
                          labelText:
                              finDocUpdated.sales ? 'Customer' : 'Supplier',
                        ),
                      ),
                      key: Key(finDocUpdated.sales ? 'customer' : 'supplier'),
                      itemAsString: (Company? u) => "${u!.name}",
                      asyncItems: (String filter) {
                        _companyBloc.add(GetDataEvent(() => context
                            .read<RestClient>()
                            .getCompany(
                                searchString: filter,
                                limit: 3,
                                isForDropDown: true,
                                role: widget.finDoc.sales
                                    ? Role.customer
                                    : Role.supplier)));
                        return Future.delayed(const Duration(milliseconds: 150),
                            () {
                          return Future<List<Company>>.value(
                              (_companyBloc.state.data as Companies).companies);
                        });
                      },
                      compareFn: (item, sItem) => item.partyId == sItem.partyId,
                      onChanged: (Company? newValue) {
                        setState(() {
                          _selectedCompany = newValue;
                        });
                      },
                      validator: (value) => value == null
                          ? "Select ${finDocUpdated.sales ? 'Customer' : 'Supplier'}!"
                          : null,
                    ),
                  ),
                ],
              ),
            );
          default:
            return const Center(child: LoadingIndicator());
        }
      }),
      Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            SizedBox(
              width: 115,
              child: DropdownButtonFormField<FinDocStatusVal>(
                key: const Key('statusDropDown'),
                decoration: const InputDecoration(labelText: 'Status'),
                value: _updatedStatus,
                validator: (value) => value == null ? 'field required' : null,
                items: FinDocStatusVal.validStatusList(_updatedStatus)
                    .map((label) => DropdownMenuItem<FinDocStatusVal>(
                          value: label,
                          child: Text(label.name),
                        ))
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
                decoration:
                    InputDecoration(labelText: '${finDoc.docType} Description'),
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
                : Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Expanded(child: widgets[0]),
                    Expanded(child: widgets[1]),
                  ])));
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
                    SizedBox(
                      width: 80,
                      child: TextFormField(
                        key: const Key('pseudoId'),
                        decoration: const InputDecoration(labelText: 'Id'),
                        controller: _pseudoIdController,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        key: const Key('description'),
                        readOnly: readOnly,
                        decoration: InputDecoration(
                            labelText: '${finDoc.docType} Description'),
                        controller: _descriptionController,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: DropdownSearch<Company>(
                        enabled: !readOnly,
                        selectedItem: _selectedCompany,
                        popupProps: PopupProps.menu(
                          isFilterOnline: true,
                          showSelectedItems: true,
                          showSearchBox: true,
                          searchFieldProps: TextFieldProps(
                            autofocus: true,
                            decoration: InputDecoration(
                                labelText:
                                    "${finDocUpdated.sales ? 'Customer' : 'Supplier'} name"),
                            controller: _companySearchBoxController,
                          ),
                          title: popUp(
                            context: context,
                            title:
                                "Select ${finDocUpdated.sales ? 'Customer' : 'Supplier'}",
                            height: 50,
                          ),
                        ),
                        dropdownDecoratorProps: DropDownDecoratorProps(
                          dropdownSearchDecoration: InputDecoration(
                            labelText: 'Company',
                          ),
                        ),
                        key: Key('company'),
                        itemAsString: (Company? u) => "${u!.name ?? ''}",
                        asyncItems: (String filter) {
                          _companyBloc.add(GetDataEvent(
                              () => context.read<RestClient>().getCompany(
                                    searchString: filter,
                                    limit: 3,
                                    isForDropDown: true,
                                  )));
                          return Future.delayed(
                              const Duration(milliseconds: 150), () {
                            return Future.value(
                                (_companyBloc.state.data as Companies)
                                    .companies);
                          });
                        },
                        compareFn: (item, sItem) =>
                            item.partyId == sItem.partyId,
                        onChanged: (Company? newValue) {
                          _selectedCompany = newValue;
                        },
                      ),
                    ),
                    Column(children: [
                      const Text("Posted"),
                      Radio(
                        key: const Key('isPosted'),
                        value: true,
                        groupValue: _isPosted,
                        toggleable: true,
                        onChanged: (newValue) => readOnly
                            ? null
                            : setState(() {
                                _isPosted = newValue;
                              }),
                      ),
                    ])
                  ],
                )
              ],
            )));
  }

  Widget updateButtons(state) {
    List<Widget> buttons = [
      ElevatedButton(
          key: const Key('header'),
          child: const Text("Update Header"),
          onPressed: () {
            _cartBloc.add(CartHeader(finDocUpdated.copyWith(
                otherCompany: _selectedCompany,
                description: _descriptionController.text,
                isPosted: _isPosted)));
          }),
      ElevatedButton(
          key: const Key('addItem'),
          child: Text(widget.finDoc.docType == FinDocType.transaction
              ? 'Add\n transaction item'
              : 'Add other item'),
          onPressed: () async {
            final dynamic finDocItem;
            if (widget.finDoc.docType != FinDocType.transaction) {
              finDocItem = await addAnotherItemDialog(
                  context, finDocUpdated.sales, state);
            } else {
              finDocItem = await addTransactionItemDialog(
                  context, finDocUpdated.sales, state, _glAccountBloc);
            }
            if (finDocItem != null) {
              _cartBloc.add(CartAdd(
                  finDoc: finDocUpdated.copyWith(
                      otherCompany: _selectedCompany,
                      description: _descriptionController.text,
                      isPosted: _isPosted),
                  newItem: finDocItem));
            }
          }),
      if (widget.finDoc.docType == FinDocType.order)
        ElevatedButton(
            key: const Key('itemRental'),
            child: const Text('Asset Rental'),
            onPressed: () async {
              final dynamic finDocItem =
                  await addRentalItemDialog(context, _productBloc, _finDocBloc);
              if (finDocItem != null) {
                _cartBloc.add(CartAdd(
                    finDoc: finDocUpdated.copyWith(
                        otherCompany: _selectedCompany,
                        description: _descriptionController.text),
                    newItem: finDocItem));
              }
            }),
      if (widget.finDoc.docType != FinDocType.transaction)
        ElevatedButton(
            key: const Key('addProduct'),
            child: const Text('Add Product'),
            onPressed: () async {
              final dynamic finDocItem = await addProductItemDialog(context);
              if (finDocItem != null) {
                _cartBloc.add(CartAdd(
                    finDoc: finDocUpdated.copyWith(
                        otherCompany: _selectedCompany,
                        description: _descriptionController.text),
                    newItem: finDocItem));
              }
            }),
    ];

    if (isPhone) {
      List<Widget> rows = [];
      for (var i = 0; i < buttons.length; i++) {
        rows.add(Row(children: [
          Expanded(
              child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 0, 5, 5),
                  child: buttons[i])),
          if (++i < buttons.length)
            Expanded(
                child: Padding(
                    padding: const EdgeInsets.fromLTRB(5, 0, 10, 5),
                    child: buttons[i]))
        ]));
      }
      return Column(children: rows);
    }
    return Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround, children: buttons);
  }

  Widget generalButtons() {
    return Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          Visibility(
              visible: !finDoc.idIsNull(),
              child: ElevatedButton(
                  key: const Key('cancelFinDoc'),
                  child: const Text('Cancel'),
                  onPressed: () {
                    _cartBloc.add(CartCancelFinDoc(finDocUpdated));
                  })),
          const SizedBox(width: 5),
          ElevatedButton(
              key: const Key('clear'),
              child: const Text('Clear Cart'),
              onPressed: () {
                if (finDocUpdated.items.isNotEmpty) {
                  _cartBloc.add(CartClear());
                }
              }),
          const SizedBox(width: 5),
          Expanded(
            child: ElevatedButton(
                key: const Key('update'),
                child: Text(
                    "${finDoc.idIsNull() ? CoreLocalizations.of(context)!.create : CoreLocalizations.of(context)!.update} "
                    "${finDocUpdated.docType!}"),
                onPressed: () {
                  finDocUpdated = finDocUpdated.copyWith(
                      // set order to created, others not. inprep only used by website.
                      status: _updatedStatus,
                      otherCompany: _selectedCompany,
                      description: _descriptionController.text);
                  if ((finDocUpdated.docType == FinDocType.transaction &&
                          finDocUpdated.items.isNotEmpty) ||
                      (finDocUpdated.items.isNotEmpty &&
                          finDocUpdated.otherCompany != null)) {
                    _cartBloc.add(CartCreateFinDoc(finDocUpdated));
                  } else {
                    HelperFunctions.showMessage(
                        context,
                        'A ${finDocUpdated.sales ? CoreLocalizations.of(context)!.customer : CoreLocalizations.of(context)!.supplier} '
                        '${CoreLocalizations.of(context)!.andAtLeastOne} '
                        '${finDocUpdated.docType!} '
                        '${CoreLocalizations.of(context)!.itemIsRequired}',
                        Colors.red);
                  }
                }),
          ),
        ]);
  }

  Widget finDocItemList(CartState state) {
    List<FinDocItem> items = finDocUpdated.items;
    late final ScrollController _verticalController = ScrollController();
    late final ScrollController _horizontalController = ScrollController();
    // field headers
    List<dynamic> getItemFieldNames(
        {int? itemIndex,
        String? classificationId,
        FinDocItem? item,
        BuildContext? context}) {
      return [
        "#",
        "ProdId",
        if (!isPhone) "Item Type",
        "Description",
        if (!isPhone) "Qty",
        "Price",
        if (!isPhone) "SubTotal",
        " "
      ];
    }

    // field lengths
    List<double> getItemFieldWidth(
        {int? itemIndex, FinDocItem? item, BuildContext? context}) {
      if (isPhone)
        return [6, 14, 25, 10, 14];
      else
        return [4, 8, 8, 28, 6, 10, 10, 10];
    }

    // fields content
    List<dynamic> getItemFieldContent(FinDocItem item,
        {int? itemIndex, BuildContext? context}) {
      var itemType = item.itemType != null
          ? state.itemTypes
              .firstWhere((e) => e.itemTypeId == item.itemType!.itemTypeId)
          : ItemType();
      return [
        CircleAvatar(
          backgroundColor: Colors.green,
          child: Text(item.itemSeqId.toString()),
        ),
        Text("${item.productId}",
            textAlign: TextAlign.center, key: Key('itemProductId$itemIndex')),
        if (!isPhone)
          Text(itemType.itemTypeName,
              textAlign: TextAlign.left, key: Key('itemType$itemIndex')),
        Text("${item.description}",
            key: Key('itemDescription${itemIndex}'), textAlign: TextAlign.left),
        if (!isPhone)
          Text("${item.quantity}",
              textAlign: TextAlign.center, key: Key('itemQuantity$itemIndex')),
        Text(item.price!.currency(),
            textAlign: TextAlign.right, key: Key('itemPrice$itemIndex')),
        if (!isPhone) // subtotal
          Text((item.price! * (item.quantity ?? Decimal.parse('1'))).toString(),
              textAlign: TextAlign.center),
      ];
    }

    // buttons
    List<Widget> getRowActionButtons({
      Bloc<dynamic, dynamic>? bloc,
      BuildContext? context,
      FinDocItem? item,
      int? itemIndex,
    }) =>
        readOnly
            ? []
            : [
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.delete_forever),
                  padding: EdgeInsets.all(0),
                  key: Key("itemDelete$itemIndex"),
                  onPressed: () {
                    _cartBloc.add(CartDeleteItem(itemIndex!));
                  },
                )
              ];

    var padding = SpanPadding(trailing: 8, leading: 8);
    SpanDecoration? getBackGround(BuildContext context, int index) {
      return index == 0
          ? SpanDecoration(
              color: Theme.of(context).colorScheme.tertiaryContainer)
          : null;
    } // field content

    var (
      List<List<TableViewCell>> tableViewCells,
      List<double> fieldWidths,
      double? rowHeight
    ) = get2dTableData<FinDocItem>(
        getItemFieldNames, getItemFieldWidth, items, getItemFieldContent,
        getRowActionButtons: getRowActionButtons,
        context: context,
        bloc: _finDocBloc);
    return Flexible(
      child: items.isEmpty
          ? const Text("no items yet")
          : TableView.builder(
              diagonalDragBehavior: DiagonalDragBehavior.free,
              verticalDetails:
                  ScrollableDetails.vertical(controller: _verticalController),
              horizontalDetails: ScrollableDetails.horizontal(
                  controller: _horizontalController),
              cellBuilder: (context, vicinity) =>
                  tableViewCells[vicinity.row][vicinity.column],
              // height of table cell
              columnBuilder: (index) => index >= tableViewCells[0].length
                  ? null
                  : TableSpan(
                      padding: padding,
                      backgroundDecoration: getBackGround(context, index),
                      extent: FixedTableSpanExtent(fieldWidths[index])),
              pinnedColumnCount: 1,
              // width of table cell
              rowBuilder: (index) => index >= tableViewCells.length
                  ? null
                  : TableSpan(
                      padding: padding,
                      backgroundDecoration: getBackGround(context, index),
                      extent: FixedTableSpanExtent(rowHeight!),
                    ),
              pinnedRowCount: 1,
            ),
    );
  }

  Widget finDocItemListShipment(CartState state) {
    List<FinDocItem> items = finDocUpdated.items;
    late final ScrollController _verticalController = ScrollController();
    late final ScrollController _horizontalController = ScrollController();
    // field headers
    List<dynamic> getItemFieldNames(
        {int? itemIndex,
        String? classificationId,
        FinDocItem? item,
        BuildContext? context}) {
      return ["#", "ProdId", "Description", "Qty", ' '];
    }

    // field lengths
    List<double> getItemFieldWidth(
        {int? itemIndex, FinDocItem? item, BuildContext? context}) {
      if (isPhone)
        return [6, 14, 25, 10, 20];
      else
        return [4, 8, 28, 10, 20];
    }

    // fields content
    List<dynamic> getItemFieldContent(FinDocItem item,
        {int? itemIndex, BuildContext? context}) {
      return [
        CircleAvatar(
          backgroundColor: Colors.green,
          child: Text(item.itemSeqId.toString()),
        ),
        Text("${item.productId}",
            textAlign: TextAlign.center, key: Key('itemProductId${itemIndex}')),
        Text("${item.description}",
            key: Key('itemDescription${itemIndex}'), textAlign: TextAlign.left),
        Text("${item.quantity}",
            textAlign: TextAlign.center, key: Key('itemQuantity${itemIndex}')),
      ];
    }

    // buttons
    List<Widget> getRowActionButtons({
      Bloc<dynamic, dynamic>? bloc,
      BuildContext? context,
      FinDocItem? item,
      int? itemIndex,
    }) =>
        readOnly
            ? []
            : [
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.delete_forever),
                  padding: EdgeInsets.all(0),
                  key: Key("itemDelete$itemIndex"),
                  onPressed: () {
                    _cartBloc.add(CartDeleteItem(itemIndex!));
                  },
                )
              ];

    var padding = SpanPadding(trailing: 8, leading: 8);
    SpanDecoration? getBackGround(BuildContext context, int index) {
      return index == 0
          ? SpanDecoration(
              color: Theme.of(context).colorScheme.tertiaryContainer)
          : null;
    }

    var (
      List<List<TableViewCell>> tableViewCells,
      List<double> fieldWidths,
      double? rowHeight
    ) = get2dTableData<FinDocItem>(
        getItemFieldNames, getItemFieldWidth, items, getItemFieldContent,
        getRowActionButtons: getRowActionButtons,
        context: context,
        bloc: _finDocBloc);
    return Flexible(
      child: items.isEmpty
          ? const Text("no items yet")
          : TableView.builder(
              diagonalDragBehavior: DiagonalDragBehavior.free,
              verticalDetails:
                  ScrollableDetails.vertical(controller: _verticalController),
              horizontalDetails: ScrollableDetails.horizontal(
                  controller: _horizontalController),
              cellBuilder: (context, vicinity) =>
                  tableViewCells[vicinity.row][vicinity.column],
              // height of table cell
              columnBuilder: (index) => index >= tableViewCells[0].length
                  ? null
                  : TableSpan(
                      padding: padding,
                      backgroundDecoration: getBackGround(context, index),
                      extent: FixedTableSpanExtent(fieldWidths[index])),
              pinnedColumnCount: 1,
              // width of table cell
              rowBuilder: (index) => index >= tableViewCells.length
                  ? null
                  : TableSpan(
                      padding: padding,
                      backgroundDecoration: getBackGround(context, index),
                      extent: FixedTableSpanExtent(rowHeight!),
                    ),
              pinnedRowCount: 1,
            ),
    );
  }

  Widget finDocItemListTransaction(CartState state) {
    List<FinDocItem> items = finDocUpdated.items;
    late final ScrollController _verticalController = ScrollController();
    late final ScrollController _horizontalController = ScrollController();
    // field headers
    List<dynamic> getItemFieldNames(
        {int? itemIndex,
        String? classificationId,
        FinDocItem? item,
        BuildContext? context}) {
      return ['Account', 'Debit', 'Credit', 'ProdId', if (!readOnly) 'del.'];
    }

    // field lengths
    List<double> getItemFieldWidth(
        {int? itemIndex, FinDocItem? item, BuildContext? context}) {
      return [12, 12, 12, 15, 15];
    }

    // fields content, using strings index not required
    // widgets also allowed, then index is used for the key on the widgets
    List<dynamic> getItemFieldContent(FinDocItem item,
        {int? itemIndex, BuildContext? context}) {
      return [
        Text(item.glAccount!.accountCode!, key: Key('accountCode$itemIndex')),
        Text((item.isDebit! ? item.price.currency() : ''),
            key: Key('debit$itemIndex')),
        Text(!item.isDebit! ? item.price.currency() : '',
            key: Key('credit$itemIndex')),
        Text(item.productId ?? '', key: Key('itemProductId$itemIndex')),
      ];
    }

    double getRowHeight({BuildContext? context}) {
      return 15;
    }

    // buttons
    List<Widget> getRowActionButtons({
      Bloc<dynamic, dynamic>? bloc,
      BuildContext? context,
      FinDocItem? item,
      int? itemIndex,
    }) =>
        [
          IconButton(
            padding: EdgeInsets.all(0),
            icon: const Icon(
              Icons.delete_forever,
              size: 20,
            ),
            key: Key("itemDelete$itemIndex"),
            onPressed: () {
              _cartBloc.add(CartDeleteItem(itemIndex!));
            },
          )
        ];

    var padding = SpanPadding(trailing: 10, leading: 10);
    SpanDecoration? getBackGround(BuildContext context, int index) {
      return index == 0
          ? SpanDecoration(
              color: Theme.of(context).colorScheme.tertiaryContainer)
          : null;
    } // field content

    var (
      List<List<TableViewCell>> tableViewCells,
      List<double> fieldWidths,
      double? rowHeight
    ) = get2dTableData<FinDocItem>(
        getItemFieldNames, getItemFieldWidth, items, getItemFieldContent,
        getRowActionButtons: getRowActionButtons,
        getRowHeight: getRowHeight,
        context: context,
        bloc: _finDocBloc);
    return items.isEmpty
        ? const Text("no items yet")
        : Flexible(
            child: Padding(
              padding: const EdgeInsets.only(left: 10.0),
              child: TableView.builder(
                diagonalDragBehavior: DiagonalDragBehavior.free,
                verticalDetails:
                    ScrollableDetails.vertical(controller: _verticalController),
                horizontalDetails: ScrollableDetails.horizontal(
                    controller: _horizontalController),
                cellBuilder: (context, vicinity) =>
                    tableViewCells[vicinity.row][vicinity.column],
                // height of table cell
                columnBuilder: (index) => index >= tableViewCells[0].length
                    ? null
                    : TableSpan(
                        padding: padding,
                        backgroundDecoration: getBackGround(context, index),
                        extent: FixedTableSpanExtent(fieldWidths[index])),
                pinnedColumnCount: 1,
                // width of table cell
                rowBuilder: (index) => index >= tableViewCells.length
                    ? null
                    : TableSpan(
                        padding: padding,
                        backgroundDecoration: getBackGround(context, index),
                        extent: FixedTableSpanExtent(rowHeight!),
                      ),
                pinnedRowCount: 1,
              ),
            ),
          );
  }
}
