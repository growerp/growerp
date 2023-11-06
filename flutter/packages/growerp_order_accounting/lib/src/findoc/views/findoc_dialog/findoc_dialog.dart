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
import 'package:global_configuration/global_configuration.dart';
import 'package:growerp_order_accounting/growerp_order_accounting.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

import 'add_another_item_dialog.dart';
import 'add_product_item_dialog.dart';
import 'add_rental_item_dialog.dart';
import 'add_transaction_item_dialog.dart';

class ShowFinDocDialog extends StatelessWidget {
  final FinDoc finDoc;
  final bool dialog;
  const ShowFinDocDialog(this.finDoc, {super.key, this.dialog = true});
  @override
  Widget build(BuildContext context) {
    RestClient restClient = context.read<RestClient>();
    return BlocProvider<FinDocBloc>(
        create: (context) => FinDocBloc(
            restClient, finDoc.sales, finDoc.docType!, context.read<String>())
          ..add(FinDocFetch(finDocId: finDoc.id()!, docType: finDoc.docType!)),
        child: BlocBuilder<FinDocBloc, FinDocState>(builder: (context, state) {
          if (state.status == FinDocStatus.success) {
            return RepositoryProvider.value(
                value: restClient,
                child: FinDocDialog(finDoc: state.finDocs[0]));
          } else {
            return const LoadingIndicator();
          }
        }));
  }
}

class FinDocDialog extends StatelessWidget {
  final FinDoc finDoc;
  const FinDocDialog({required this.finDoc, super.key});

  @override
  Widget build(BuildContext context) {
    FinDocBloc finDocBloc = context.read<FinDocBloc>();
    RestClient restClient = context.read<RestClient>();
    if (finDoc.sales) {
      return MultiBlocProvider(providers: [
        BlocProvider<SalesCartBloc>(
            create: (context) => CartBloc(
                docType: finDoc.docType!,
                sales: true,
                finDocBloc: finDocBloc,
                restClient: restClient)
              ..add(CartFetch(finDoc))),
        BlocProvider<UserBloc>(
            create: (context) =>
                UserBloc(context.read<RestClient>(), Role.customer)),
        BlocProvider<ProductBloc>(
            create: (context) => ProductBloc(
                context.read<RestClient>(), context.read<String>())),
        BlocProvider<GlAccountBloc>(
            create: (context) => GlAccountBloc(context.read<RestClient>())),
      ], child: FinDocPage(finDoc));
    }
    return MultiBlocProvider(providers: [
      BlocProvider<PurchaseCartBloc>(
          create: (context) => CartBloc(
              docType: finDoc.docType!,
              sales: false,
              finDocBloc: finDocBloc,
              restClient: restClient)
            ..add(CartFetch(finDoc))),
      BlocProvider<UserBloc>(
          create: (context) =>
              UserBloc(context.read<RestClient>(), Role.supplier)),
      BlocProvider<ProductBloc>(
          create: (context) =>
              ProductBloc(context.read<RestClient>(), context.read<String>())),
      BlocProvider<GlAccountBloc>(
          create: (context) => GlAccountBloc(context.read<RestClient>())),
    ], child: FinDocPage(finDoc));
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
  final _userSearchBoxController = TextEditingController();
  late CartBloc _cartBloc;
  late UserBloc _userBloc;
  late ProductBloc _productBloc;
  late GlAccountBloc _glAccountBloc;
  late FinDocBloc _finDocBloc;
  late String classificationId;
  late FinDoc finDocUpdated;
  late FinDoc finDoc; // incoming finDoc
  bool? _isPosted = false;
  User? _selectedUser;
  Company? _selectedCompany;
  late bool isPhone;

  @override
  void initState() {
    super.initState();
    finDoc = widget.finDoc;
    finDocUpdated = finDoc;
    _selectedUser = finDocUpdated.otherUser;
    _isPosted = finDocUpdated.isPosted ?? false;
    _selectedCompany =
        finDocUpdated.otherCompany ?? finDocUpdated.otherUser?.company;
    _finDocBloc = context.read<FinDocBloc>();
    _userBloc = context.read<UserBloc>();
    _userBloc.add(const UserFetch());
    _glAccountBloc = context.read<GlAccountBloc>();
    _glAccountBloc.add(const GlAccountFetch());
    _productBloc = context.read<ProductBloc>();
    _productBloc.add(const ProductFetch());
    _descriptionController.text = finDocUpdated.description ?? "";
    if (finDoc.sales) {
      _cartBloc = context.read<SalesCartBloc>() as CartBloc;
    } else {
      _cartBloc = context.read<PurchaseCartBloc>() as CartBloc;
    }
    classificationId = GlobalConfiguration().get("classificationId");
  }

  @override
  Widget build(BuildContext context) {
    isPhone = ResponsiveBreakpoints.of(context).isMobile;

    blocConsumerListener(BuildContext context, CartState state,
        [bool mounted = true]) async {
      switch (state.status) {
        case CartStatus.complete:
          HelperFunctions.showMessage(
              context,
              '${finDoc.idIsNull() ? "Add" : "Update"} successfull',
              Colors.green);
          await Future.delayed(const Duration(milliseconds: 500));
          if (!mounted) return const Text('not mounted!');
          Navigator.of(context).pop();
          break;
        case CartStatus.failure:
          HelperFunctions.showMessage(context, '${state.message}', Colors.red);
          break;
        default:
          return const Center(child: CircularProgressIndicator());
      }
    }

    blocConsumerBuilder(BuildContext context, CartState state) {
      switch (state.status) {
        case CartStatus.inProcess:
          finDocUpdated = state.finDoc;
          return Column(children: [
            widget.finDoc.docType == FinDocType.transaction
                ? headerEntryTransaction()
                : headerEntry(),
            SizedBox(height: isPhone ? 110 : 50, child: updateButtons(state)),
            widget.finDoc.docType == FinDocType.transaction
                ? finDocItemListTransaction(state)
                : finDocItemList(state),
            const SizedBox(height: 10),
            Center(
                child: Text(
                    "Items# ${finDocUpdated.items.length}   Grand total : ${finDocUpdated.grandTotal == null ? "0.00" : finDocUpdated.grandTotal.toString()}",
                    key: const Key('grandTotal'))),
            const SizedBox(height: 10),
            SizedBox(height: 40, child: generalButtons()),
          ]);
        default:
          return const LoadingIndicator();
      }
    }

    return Dialog(
        key: Key("FinDocDialog${finDoc.sales == true ? 'Sales' : 'Purchase'}"
            "${finDoc.docType}"),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        insetPadding: const EdgeInsets.all(10),
        child: SingleChildScrollView(
            key: const Key('listView1'),
            child: popUp(
              title: "${finDoc.docType} #${finDoc.id() ?? ' new'}",
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
            )));
  }

  Widget headerEntry() {
    List<Widget> widgets = [
      if (widget.finDoc.docType != FinDocType.transaction)
        Expanded(
            child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
          child: BlocBuilder<UserBloc, UserState>(builder: (context, state) {
            switch (state.status) {
              case UserStatus.failure:
                return const FatalErrorForm(
                    message: 'server connection problem');
              case UserStatus.success:
                return DropdownSearch<User>(
                  selectedItem: _selectedUser,
                  popupProps: PopupProps.menu(
                    showSearchBox: true,
                    searchFieldProps: TextFieldProps(
                      autofocus: true,
                      decoration: InputDecoration(
                          labelText:
                              "${finDocUpdated.sales ? 'Customer' : 'Supplier'} name"),
                      controller: _userSearchBoxController,
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
                      labelText: finDocUpdated.sales ? 'Customer' : 'Supplier',
                    ),
                  ),
                  key: Key(
                      finDocUpdated.sales == true ? 'customer' : 'supplier'),
                  itemAsString: (User? u) =>
                      " ${u!.company!.name},\n${u.firstName ?? ''} ${u.lastName ?? ''}",
                  asyncItems: (String filter) {
                    _userBloc.add(UserFetch(searchString: filter));
                    return Future.value(state.users);
                  },
                  onChanged: (User? newValue) {
                    setState(() {
                      _selectedUser = newValue;
                      _selectedCompany = newValue!.company;
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
        )),
      Expanded(
          child: Padding(
              padding: const EdgeInsets.all(10),
              child: TextFormField(
                key: const Key('description'),
                decoration:
                    InputDecoration(labelText: '${finDoc.docType} Description'),
                controller: _descriptionController,
              ))),
    ];

    return Center(
        child: SizedBox(
            height: isPhone ? 150 : 100,
            child: Form(
                key: _formKeyHeader,
                child: Column(
                    children: isPhone ? widgets : [Row(children: widgets)]))));
  }

  Widget headerEntryTransaction() {
    return Padding(
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
        child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    key: const Key('description'),
                    decoration: InputDecoration(
                        labelText: '${finDoc.docType} Description'),
                    controller: _descriptionController,
                  ),
                ),
                if (finDoc.docType == FinDocType.transaction)
                  Column(children: [
                    const Text("Post?"),
                    Radio(
                        key: const Key('isPosted'),
                        value: true,
                        groupValue: _isPosted,
                        toggleable: true,
                        onChanged: (newValue) {
                          setState(() {
                            _isPosted = newValue;
                          });
                        }),
                  ])
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
                otherUser: _selectedUser,
                otherCompany: _selectedCompany,
                description: _descriptionController.text,
                isPosted: _isPosted)));
          }),
      ElevatedButton(
          key: const Key('addItem'),
          child: Text(widget.finDoc.docType == FinDocType.transaction
              ? 'Add transaction'
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
                      otherUser: _selectedUser,
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
                        otherUser: _selectedUser,
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
              final dynamic finDocItem = await addProductItemDialog(
                  context, classificationId, _productBloc, _glAccountBloc);
              if (finDocItem != null) {
                _cartBloc.add(CartAdd(
                    finDoc: finDocUpdated.copyWith(
                        otherUser: _selectedUser,
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
                      status: finDocUpdated.docType == FinDocType.order
                          ? FinDocStatusVal.created
                          : FinDocStatusVal.inPreparation,
                      otherUser: _selectedUser,
                      otherCompany: _selectedUser?.company,
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

    return Expanded(
        child: ListView.builder(
            itemCount: items.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return ListTile(
                  leading: !isPhone
                      ? const CircleAvatar(
                          backgroundColor: Colors.transparent,
                        )
                      : null,
                  title: Column(children: [
                    Row(children: <Widget>[
                      if (!isPhone)
                        const Expanded(
                            child:
                                Text("Item Type", textAlign: TextAlign.center)),
                      const Expanded(
                          child:
                              Text("Description", textAlign: TextAlign.center)),
                      if (!isPhone)
                        const Expanded(
                            child:
                                Text("    Qty", textAlign: TextAlign.center)),
                      const Text("Price", textAlign: TextAlign.center),
                      if (!isPhone)
                        const Expanded(
                            child:
                                Text("SubTotal", textAlign: TextAlign.center)),
                      const Expanded(
                          child: Text(" ", textAlign: TextAlign.center)),
                    ]),
                    const Divider(),
                  ]),
                );
              }
              if (index == 1 && items.isEmpty) {
                return const Center(
                    heightFactor: 20,
                    child: Text("no items found!",
                        key: Key('empty'), textAlign: TextAlign.center));
              }
              final item = items[index - 1];
              var itemType = item.itemType != null
                  ? state.itemTypes.firstWhere(
                      (e) => e.itemTypeId == item.itemType!.itemTypeId)
                  : ItemType();
              return ListTile(
                  key: const Key('productItem'),
                  leading: !isPhone
                      ? CircleAvatar(
                          backgroundColor: Colors.green,
                          child: Text(item.itemSeqId.toString()),
                        )
                      : null,
                  title: Row(children: <Widget>[
                    if (!isPhone)
                      Expanded(
                          child: Text(itemType.itemTypeName,
                              textAlign: TextAlign.left,
                              key: Key('itemType${index - 1}'))),
                    Expanded(
                        child: Text("${item.description}",
                            key: Key('itemDescription${index - 1}'),
                            textAlign: TextAlign.left)),
                    if (!isPhone)
                      Expanded(
                          child: Text("${item.quantity}",
                              textAlign: TextAlign.center,
                              key: Key('itemQuantity${index - 1}'))),
                    Text("${item.price}", key: Key('itemPrice${index - 1}')),
                    if (!isPhone)
                      Expanded(
                        key: Key('subTotal${index - 1}'),
                        child: Text(
                            (item.price! *
                                    (item.quantity ?? Decimal.parse('1')))
                                .toString(),
                            textAlign: TextAlign.center),
                      ),
                  ]),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_forever),
                    key: Key("delete${index - 1}"),
                    onPressed: () {
                      _cartBloc.add(CartDeleteItem(index - 1));
                    },
                  ));
            }));
  }

  Widget finDocItemListTransaction(CartState state) {
    List<FinDocItem> items = finDocUpdated.items;

    return Expanded(
        child: items.isEmpty
            ? const Text("no items yet")
            : SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: DataTable(
                    dividerThickness: 0.0,
                    dataRowMaxHeight: 25,
                    dataRowMinHeight: 15,
                    columns: const [
                      DataColumn(label: Expanded(child: Text('Account'))),
                      DataColumn(label: Expanded(child: Text('Debit'))),
                      DataColumn(label: Expanded(child: Text('Credit'))),
                      DataColumn(label: Expanded(child: Text(''))),
                    ],
                    rows: List.generate(items.length, (index) {
                      return DataRow(cells: [
                        DataCell(Text(items[index].glAccount!.accountCode!,
                            key: Key('accountCode$index'))),
                        DataCell(Text(
                            items[index].isDebit!
                                ? items[index].price.toString()
                                : '',
                            key: Key('debit$index'))),
                        DataCell(Text(
                            !items[index].isDebit!
                                ? items[index].price.toString()
                                : '',
                            key: Key('credit$index'))),
                        DataCell(IconButton(
                          icon: const Icon(
                            Icons.delete_forever,
                            size: 15,
                          ),
                          key: Key("delete$index"),
                          onPressed: () {
                            _cartBloc.add(CartDeleteItem(index));
                          },
                        )),
                      ]);
                    })),
              ));
  }
}
