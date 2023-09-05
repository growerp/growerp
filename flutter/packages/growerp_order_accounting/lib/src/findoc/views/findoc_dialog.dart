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
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:growerp_order_accounting/growerp_order_accounting.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:intl/intl.dart';
import 'package:growerp_core/growerp_core.dart';

class FinDocDialog extends StatelessWidget {
  final FinDoc finDoc;
  const FinDocDialog({required this.finDoc, super.key});

  @override
  Widget build(BuildContext context) {
    FinDocBloc finDocBloc = context.read<FinDocBloc>();
    if (finDoc.sales) {
      return MultiBlocProvider(providers: [
        BlocProvider<SalesCartBloc>(
            create: (context) => CartBloc(
                docType: finDoc.docType!,
                sales: true,
                finDocBloc: finDocBloc,
                repos: context.read<FinDocAPIRepository>())
              ..add(CartFetch(finDoc))),
        BlocProvider<UserBloc>(
            create: (context) => UserBloc(
                CompanyUserAPIRepository(
                    context.read<AuthBloc>().state.authenticate!.apiKey!),
                Role.customer)),
        BlocProvider<ProductBloc>(
            create: (context) => ProductBloc(CatalogAPIRepository(
                context.read<AuthBloc>().state.authenticate!.apiKey!))),
        BlocProvider<GlAccountBloc>(
            create: (context) => GlAccountBloc(AccountingAPIRepository(
                context.read<AuthBloc>().state.authenticate!.apiKey!))),
      ], child: FinDocPage(finDoc));
    }
    return MultiBlocProvider(providers: [
      BlocProvider<PurchaseCartBloc>(
          create: (context) => CartBloc(
              docType: finDoc.docType!,
              sales: false,
              finDocBloc: finDocBloc,
              repos: context.read<FinDocAPIRepository>())
            ..add(CartFetch(finDoc))),
      BlocProvider<UserBloc>(
          create: (context) => UserBloc(
              CompanyUserAPIRepository(
                  context.read<AuthBloc>().state.authenticate!.apiKey!),
              Role.supplier)),
      BlocProvider<ProductBloc>(
          create: (context) => ProductBloc(CatalogAPIRepository(
              context.read<AuthBloc>().state.authenticate!.apiKey!))),
      BlocProvider<GlAccountBloc>(
          create: (context) => GlAccountBloc(AccountingAPIRepository(
              context.read<AuthBloc>().state.authenticate!.apiKey!))),
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
  User? _selectedUser;
  Company? _selectedCompany;
  late bool isPhone;

  @override
  void initState() {
    super.initState();
    finDoc = widget.finDoc;
    finDocUpdated = finDoc;
    _selectedUser = finDocUpdated.otherUser;
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
                      "${u!.company!.name},\n${u.firstName ?? ''} ${u.lastName ?? ''}",
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
            height: isPhone ? 200 : 100,
            child: Form(
                key: _formKeyHeader,
                child: Column(
                    children: isPhone ? widgets : [Row(children: widgets)]))));
  }

  Widget headerEntryTransaction() {
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
                      "${u!.company!.name},\n${u.firstName ?? ''} ${u.lastName ?? ''}",
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
            height: isPhone ? 200 : 100,
            child: Form(
                key: _formKeyHeader,
                child: Column(
                    children: isPhone ? widgets : [Row(children: widgets)]))));
  }

  Widget updateButtons(state) {
    List<Widget> buttons = [
      ElevatedButton(
          child: const Text("Update header"),
          onPressed: () {
            _cartBloc.add(CartHeader(finDocUpdated.copyWith(
                otherUser: _selectedUser,
                otherCompany: _selectedCompany,
                description: _descriptionController.text)));
          }),
      ElevatedButton(
          key: const Key('addItem'),
          child: const Text('Add other Item'),
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
                      description: _descriptionController.text),
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
                  context, classificationId, _productBloc);
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
          Expanded(
              child: Padding(
                  padding: const EdgeInsets.fromLTRB(5, 0, 10, 5),
                  child: buttons[++i]))
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
                    "${FinDocType.translated(context, finDocUpdated.docType!)}"),
                onPressed: () {
                  finDocUpdated = finDocUpdated.copyWith(
                      // set order to created, others not. inprep only used by website.
                      status: finDocUpdated.docType == FinDocType.order
                          ? FinDocStatusVal.created
                          : FinDocStatusVal.inPreparation,
                      otherUser: _selectedUser,
                      otherCompany: _selectedUser?.company,
                      description: _descriptionController.text);
                  if (finDocUpdated.items.isNotEmpty &&
                      finDocUpdated.otherCompany != null) {
                    _cartBloc.add(CartCreateFinDoc(finDocUpdated));
                  } else {
                    HelperFunctions.showMessage(
                        context,
                        'A ${finDocUpdated.sales ? CoreLocalizations.of(context)!.customer : CoreLocalizations.of(context)!.supplier} '
                        '${CoreLocalizations.of(context)!.andAtLeastOne} '
                        '${FinDocType.translated(context, finDocUpdated.docType!)} '
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
}

Future addAnotherItemDialog(
    BuildContext context, bool sales, CartState state) async {
  final priceController = TextEditingController();
  final itemDescriptionController = TextEditingController();
  final quantityController = TextEditingController();
  ItemType? selectedItemType;
  return showDialog<FinDocItem>(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      var addOtherFormKey = GlobalKey<FormState>();
      return Dialog(
          key: const Key('addOtherItemDialog'),
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(20))),
          child: popUp(
            context: context,
            height: 520,
            title: 'Add another Item',
            child: SizedBox(
                child: Form(
                    key: addOtherFormKey,
                    child: SingleChildScrollView(
                        key: const Key('listView2'),
                        child: Column(children: <Widget>[
                          DropdownButtonFormField<ItemType>(
                            key: const Key('itemType'),
                            decoration:
                                const InputDecoration(labelText: 'Item Type'),
                            hint: const Text('ItemType'),
                            value: selectedItemType,
                            validator: (value) =>
                                value == null ? 'field required' : null,
                            items: state.itemTypes.map((item) {
                              return DropdownMenuItem<ItemType>(
                                  value: item, child: Text(item.itemTypeName));
                            }).toList(),
                            onChanged: (ItemType? newValue) {
                              selectedItemType = newValue;
                            },
                            isExpanded: true,
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                              key: const Key('itemDescription'),
                              decoration: const InputDecoration(
                                  labelText: 'Item Description'),
                              controller: itemDescriptionController,
                              validator: (value) {
                                if (value!.isEmpty) return 'Item description?';
                                return null;
                              }),
                          const SizedBox(height: 20),
                          TextFormField(
                            key: const Key('price'),
                            decoration: const InputDecoration(
                                labelText: 'Price/Amount'),
                            controller: priceController,
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value!.isEmpty) {
                                return 'Enter Price or Amount?';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            key: const Key('quantity'),
                            decoration:
                                const InputDecoration(labelText: 'Quantity'),
                            controller: quantityController,
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            key: const Key('ok'),
                            child: const Text('Ok'),
                            onPressed: () {
                              if (addOtherFormKey.currentState!.validate()) {
                                Navigator.of(context).pop(FinDocItem(
                                  itemType: selectedItemType,
                                  price: Decimal.parse(priceController.text),
                                  description: itemDescriptionController.text,
                                  quantity: quantityController.text.isEmpty
                                      ? Decimal.parse('1')
                                      : Decimal.parse(quantityController.text),
                                ));
                              }
                            },
                          ),
                        ])))),
          ));
    },
  );
}

Future addTransactionItemDialog(BuildContext context, bool sales,
    CartState state, GlAccountBloc glAccountBloc) async {
  final priceController = TextEditingController();
  bool? isDebit;
  GlAccount selectedGlAccount = GlAccount();
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
                  borderRadius: BorderRadius.all(Radius.circular(20))),
              child: popUp(
                context: context,
                height: 520,
                title: 'Add another transaction Item',
                child: SizedBox(
                    child: Form(
                        key: addOtherFormKey,
                        child: SingleChildScrollView(
                            key: const Key('listView2'),
                            child: Column(children: <Widget>[
                              BlocBuilder<GlAccountBloc, GlAccountState>(
                                builder: (context, state) {
                                  switch (state.status) {
                                    case GlAccountStatus.failure:
                                      return const FatalErrorForm(
                                          message: 'server connection problem');
                                    case GlAccountStatus.success:
                                      return DropdownSearch<GlAccount>(
                                        selectedItem: selectedGlAccount,
                                        popupProps: PopupProps.menu(
                                          showSearchBox: true,
                                          searchFieldProps:
                                              const TextFieldProps(
                                            autofocus: true,
                                            decoration: InputDecoration(
                                                labelText: "Gl Account"),
                                          ),
                                          menuProps: MenuProps(
                                              borderRadius:
                                                  BorderRadius.circular(20.0)),
                                          title: popUp(
                                            context: context,
                                            title: 'Select GL Account',
                                            height: 50,
                                          ),
                                        ),
                                        dropdownDecoratorProps:
                                            const DropDownDecoratorProps(
                                                dropdownSearchDecoration:
                                                    InputDecoration(
                                                        labelText: 'Lead')),
                                        key: const Key('lead'),
                                        itemAsString: (GlAccount? u) =>
                                            "${u?.accountCode} ${u?.accountName} ",
                                        items: state.glAccounts,
                                        onChanged: (GlAccount? newValue) {
                                          selectedGlAccount = newValue!;
                                        },
                                      );
                                    default:
                                      return const Center(
                                          child: CircularProgressIndicator());
                                  }
                                },
                              ),
                              const SizedBox(height: 20),
                              BinaryRadioButton(
                                  isDebit: isDebit,
                                  onValueChanged: (isDebit) {}),
                              const SizedBox(height: 20),
                              TextFormField(
                                key: const Key('price'),
                                decoration:
                                    const InputDecoration(labelText: 'Amount'),
                                controller: priceController,
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value!.isEmpty) {
                                    return 'Enter Amount?';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton(
                                key: const Key('ok'),
                                child: const Text('Ok'),
                                onPressed: () {
                                  if (addOtherFormKey.currentState!
                                      .validate()) {
                                    Navigator.of(context).pop(FinDocItem(
                                      isDebit: isDebit,
                                      price:
                                          Decimal.parse(priceController.text),
                                    ));
                                  }
                                },
                              ),
                            ])))),
              )));
    },
  );
}

Future addProductItemDialog(BuildContext context, String classificationId,
    ProductBloc productBloc) async {
  final priceController = TextEditingController();
  final itemDescriptionController = TextEditingController();
  final quantityController = TextEditingController();
  final productSearchBoxController = TextEditingController();
  Product? selectedProduct;

  return showDialog<FinDocItem>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        var addProductFormKey = GlobalKey<FormState>();
        return StatefulBuilder(
          builder: (context, setState) {
            return BlocProvider.value(
                value: productBloc,
                child: Dialog(
                    key: const Key('addProductItemDialog'),
                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(20))),
                    child: popUp(
                        context: context,
                        height: 520,
                        title: 'Add a Product',
                        child: Form(
                            key: addProductFormKey,
                            child: SingleChildScrollView(
                                key: const Key('listView3'),
                                child: Column(children: <Widget>[
                                  BlocBuilder<ProductBloc, ProductState>(
                                      builder: (context, productState) {
                                    switch (productState.status) {
                                      case ProductStatus.failure:
                                        return const FatalErrorForm(
                                            message:
                                                'server connection problem');
                                      case ProductStatus.success:
                                        return DropdownSearch<Product>(
                                          selectedItem: selectedProduct,
                                          popupProps: PopupProps.menu(
                                            showSearchBox: true,
                                            searchFieldProps: TextFieldProps(
                                              autofocus: true,
                                              decoration: const InputDecoration(
                                                labelText: 'Product name',
                                              ),
                                              controller:
                                                  productSearchBoxController,
                                            ),
                                            title: popUp(
                                              context: context,
                                              title: 'Select product',
                                              height: 50,
                                            ),
                                          ),
                                          dropdownDecoratorProps:
                                              const DropDownDecoratorProps(
                                                  dropdownSearchDecoration:
                                                      InputDecoration(
                                                          labelText:
                                                              'Product')),
                                          key: const Key('product'),
                                          itemAsString: (Product? u) =>
                                              "${u!.pseudoId}\n${u.productName}",
                                          asyncItems: (String filter) {
                                            productBloc.add(ProductFetch(
                                                searchString: filter,
                                                assetClassId:
                                                    classificationId ==
                                                            'AppHotel'
                                                        ? 'Hotel Room'
                                                        : ''));
                                            return Future.value(
                                                productState.products);
                                          },
                                          onChanged: (Product? newValue) {
                                            setState(() {
                                              selectedProduct = newValue;
                                            });
                                            if (newValue != null) {
                                              priceController.text =
                                                  newValue.price.toString();
                                              itemDescriptionController.text =
                                                  "${newValue.productName}";
                                            }
                                          },
                                          validator: (value) => value == null
                                              ? "Select a product?"
                                              : null,
                                        );
                                      default:
                                        return const Center(
                                            child: CircularProgressIndicator());
                                    }
                                  }),
                                  const SizedBox(height: 20),
                                  TextFormField(
                                      key: const Key('itemDescription'),
                                      decoration: const InputDecoration(
                                          labelText: 'Item Description'),
                                      controller: itemDescriptionController,
                                      validator: (value) {
                                        if (value!.isEmpty) {
                                          return 'Item description?';
                                        }
                                        return null;
                                      }),
                                  const SizedBox(height: 20),
                                  TextFormField(
                                    key: const Key('itemPrice'),
                                    decoration: const InputDecoration(
                                        labelText: 'Price/Amount'),
                                    controller: priceController,
                                    validator: (value) {
                                      if (value!.isEmpty) {
                                        return 'Enter Price or Amount?';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  TextFormField(
                                    key: const Key('itemQuantity'),
                                    keyboardType: TextInputType.number,
                                    inputFormatters: <TextInputFormatter>[
                                      FilteringTextInputFormatter.allow(
                                          RegExp('[0-9.,]+'))
                                    ],
                                    decoration: const InputDecoration(
                                        labelText: 'Quantity'),
                                    controller: quantityController,
                                    validator: (value) => value == null
                                        ? "Enter a quantity?"
                                        : null,
                                  ),
                                  const SizedBox(height: 20),
                                  Row(children: [
                                    Expanded(
                                      child: ElevatedButton(
                                        key: const Key('ok'),
                                        child: const Text('Add product'),
                                        onPressed: () {
                                          if (addProductFormKey.currentState!
                                              .validate()) {
                                            Navigator.of(context)
                                                .pop(FinDocItem(
                                              itemType: ItemType(
                                                  itemTypeId: 'ItemProduct'),
                                              productId:
                                                  selectedProduct!.productId,
                                              price: Decimal.parse(
                                                  priceController.text),
                                              description:
                                                  itemDescriptionController
                                                      .text,
                                              quantity: quantityController
                                                      .text.isEmpty
                                                  ? Decimal.parse('1')
                                                  : Decimal.parse(
                                                      quantityController.text),
                                            ));
                                          }
                                        },
                                      ),
                                    )
                                  ])
                                ]))))));
          },
        );
      });
}

/// [addRentalItemDialog] add a rental order item [FinDocItem]
Future addRentalItemDialog(BuildContext context, ProductBloc productBloc,
    FinDocBloc finDocBloc) async {
  final priceController = TextEditingController();
  final itemDescriptionController = TextEditingController();
  final quantityController = TextEditingController();
  final productSearchBoxController = TextEditingController();
  Product? selectedProduct;
  DateTime startDate = CustomizableDateTime.current;
  List<String> rentalDays = [];
  String classificationId = GlobalConfiguration().get("classificationId");

  return showDialog<FinDocItem>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        bool whichDayOk(DateTime day) {
          var formatter = DateFormat('yyyy-MM-dd');
          String date = formatter.format(day);
          if (rentalDays.contains(date)) return false;
          return true;
        }

        DateTime firstFreeDate() {
          var nowDate = CustomizableDateTime.current;
          while (whichDayOk(nowDate) == false) {
            nowDate = nowDate.add(const Duration(days: 1));
          }
          return nowDate;
        }

        var addRentalFormKey = GlobalKey<FormState>();
        return BlocProvider.value(
            value: finDocBloc,
            child: BlocProvider.value(
                value: productBloc,
                child: Dialog(
                    key: const Key('addRentalItemDialog'),
                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(20))),
                    child: popUp(
                      context: context,
                      height: 600,
                      title: 'Add a Reservation',
                      child: StatefulBuilder(
                        builder: (BuildContext context, StateSetter setState) {
                          Future<void> selectDate(BuildContext context) async {
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: firstFreeDate(),
                              firstDate: CustomizableDateTime.current,
                              lastDate: DateTime(
                                  CustomizableDateTime.current.year + 1),
                              selectableDayPredicate: whichDayOk,
                              builder: (BuildContext context, Widget? child) {
                                return Theme(
                                    data:
                                        ThemeData(primarySwatch: Colors.green),
                                    child: child!);
                              },
                            );
                            if (picked != null && picked != startDate) {
                              setState(() {
                                startDate = picked;
                              });
                            }
                          }

                          return Form(
                              key: addRentalFormKey,
                              child: SingleChildScrollView(
                                  key: const Key('listView4'),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      BlocBuilder<ProductBloc, ProductState>(
                                          builder: (context, productState) {
                                        switch (productState.status) {
                                          case ProductStatus.failure:
                                            return const FatalErrorForm(
                                                message:
                                                    'server connection problem');
                                          case ProductStatus.success:
                                            rentalDays =
                                                productState.occupancyDates;
                                            return DropdownSearch<Product>(
                                              key: const Key('product'),
                                              selectedItem: selectedProduct,
                                              dropdownDecoratorProps:
                                                  const DropDownDecoratorProps(
                                                      dropdownSearchDecoration:
                                                          InputDecoration(
                                                              labelText:
                                                                  'Product')),
                                              popupProps: PopupProps.menu(
                                                showSearchBox: true,
                                                searchFieldProps:
                                                    TextFieldProps(
                                                  autofocus: true,
                                                  decoration: InputDecoration(
                                                    labelText:
                                                        classificationId ==
                                                                'AppHotel'
                                                            ? 'Room Type'
                                                            : 'Product',
                                                  ),
                                                  controller:
                                                      productSearchBoxController,
                                                ),
                                                title: popUp(
                                                  context: context,
                                                  title: 'Select product',
                                                  height: 50,
                                                ),
                                              ),
                                              itemAsString: (Product? u) =>
                                                  "${u!.productName}",
                                              asyncItems: (String filter) {
                                                context.read<ProductBloc>().add(
                                                    ProductFetch(
                                                        searchString: filter,
                                                        assetClassId:
                                                            classificationId ==
                                                                    'AppHotel'
                                                                ? 'Hotel Room'
                                                                : ''));
                                                return Future.value(
                                                    productState.products);
                                              },
                                              onChanged:
                                                  (Product? newValue) async {
                                                selectedProduct = newValue;
                                                priceController.text =
                                                    newValue!.price.toString();
                                                itemDescriptionController.text =
                                                    "${newValue.productName}";
                                                context.read<ProductBloc>().add(
                                                    ProductRentalOccupancy(
                                                        productId: newValue
                                                            .productId));
                                                while (!whichDayOk(startDate)) {
                                                  startDate = startDate.add(
                                                      const Duration(days: 1));
                                                }
                                              },
                                              validator: (value) =>
                                                  value == null
                                                      ? 'Select product?'
                                                      : null,
                                            );
                                          default:
                                            return const Center(
                                                child:
                                                    CircularProgressIndicator());
                                        }
                                      }),
                                      const SizedBox(height: 20),
                                      TextFormField(
                                        key: const Key('itemDescription'),
                                        decoration: const InputDecoration(
                                            labelText: 'Item Description'),
                                        controller: itemDescriptionController,
                                        validator: (value) => value!.isEmpty
                                            ? 'Item description?'
                                            : null,
                                      ),
                                      const SizedBox(height: 20),
                                      TextFormField(
                                        key: const Key('price'),
                                        decoration: const InputDecoration(
                                            labelText: 'Price/Amount'),
                                        controller: priceController,
                                        validator: (value) => value!.isEmpty
                                            ? 'Enter Price?'
                                            : null,
                                      ),
                                      const SizedBox(height: 20),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              "${startDate.toLocal()}"
                                                  .split(' ')[0],
                                              key: const Key('date'),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          ElevatedButton(
                                            key: const Key('setDate'),
                                            child: const Text(
                                              'Select date',
                                            ),
                                            onPressed: () =>
                                                selectDate(context),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 20),
                                      TextFormField(
                                        key: const Key('quantity'),
                                        decoration: const InputDecoration(
                                            labelText: 'Nbr. of days'),
                                        controller: quantityController,
                                      ),
                                      const SizedBox(height: 20),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: ElevatedButton(
                                              key: const Key('okRental'),
                                              child:
                                                  const Text('Add reservation'),
                                              onPressed: () {
                                                if (addRentalFormKey
                                                    .currentState!
                                                    .validate()) {
                                                  Navigator.of(context)
                                                      .pop(FinDocItem(
                                                    itemType: ItemType(
                                                        itemTypeId:
                                                            'ItemRental'),
                                                    productId: selectedProduct!
                                                        .productId,
                                                    price: Decimal.parse(
                                                        priceController.text),
                                                    description:
                                                        itemDescriptionController
                                                            .text,
                                                    rentalFromDate: startDate,
                                                    rentalThruDate:
                                                        startDate.add(Duration(
                                                            days: int.parse(
                                                                quantityController
                                                                        .text
                                                                        .isEmpty
                                                                    ? '1'
                                                                    : quantityController
                                                                        .text))),
                                                    quantity:
                                                        Decimal.parse('1'),
                                                  ));
                                                }
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  )));
                        },
                      ),
                    ))));
      });
}
