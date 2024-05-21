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

import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

import '../../../accounting/accounting.dart';

Future addProductItemDialog(BuildContext context) async {
  final priceController = TextEditingController();
  final itemDescriptionController = TextEditingController();
  final quantityController = TextEditingController();
  final productSearchBoxController = TextEditingController();
  GlAccount? selectedGlAccount;
  Product? selectedProduct;
  GlAccountBloc glAccountBloc = context.read<GlAccountBloc>();
  DataFetchBloc<Products> productBloc = context.read<DataFetchBloc<Products>>();
  String classificationId = context.read<String>();

  return showDialog<FinDocItem>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        var addProductFormKey = GlobalKey<FormState>();
        return StatefulBuilder(
          builder: (context, setState) {
            return BlocProvider.value(
                value: productBloc,
                child: BlocProvider.value(
                    value: glAccountBloc,
                    child: Dialog(
                        key: const Key('addProductItemDialog'),
                        shape: const RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(20))),
                        child: popUp(
                            context: context,
                            height: 600,
                            title: 'Add a Product',
                            child: Form(
                                key: addProductFormKey,
                                child: SingleChildScrollView(
                                    key: const Key('listView3'),
                                    child: Column(children: <Widget>[
                                      BlocBuilder<DataFetchBloc<Products>,
                                              DataFetchState>(
                                          builder: (context, state) {
                                        switch (state.status) {
                                          case DataFetchStatus.failure:
                                            return const FatalErrorForm(
                                                message:
                                                    'server connection problem');
                                          case DataFetchStatus.loading:
                                            return LoadingIndicator();
                                          case DataFetchStatus.success:
                                            return DropdownSearch<Product>(
                                              selectedItem: selectedProduct,
                                              popupProps: PopupProps.menu(
                                                showSelectedItems: true,
                                                isFilterOnline: true,
                                                showSearchBox: true,
                                                searchFieldProps:
                                                    TextFieldProps(
                                                  autofocus: true,
                                                  decoration:
                                                      const InputDecoration(
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
                                                  " ${u!.productName}[${u.pseudoId}]",
                                              asyncItems: (String filter) {
                                                productBloc.add(GetDataEvent(
                                                    () => context
                                                        .read<RestClient>()
                                                        .getProduct(
                                                            searchString:
                                                                filter,
                                                            limit: 3,
                                                            isForDropDown: true,
                                                            assetClassId:
                                                                classificationId ==
                                                                        'AppHotel'
                                                                    ? 'Hotel Room'
                                                                    : '')));
                                                return Future.delayed(
                                                    const Duration(
                                                        milliseconds: 150), () {
                                                  return Future.value(
                                                      (productBloc.state.data
                                                              as Products)
                                                          .products);
                                                });
                                              },
                                              compareFn: (item, sItem) =>
                                                  item.pseudoId ==
                                                  sItem.pseudoId,
                                              onChanged: (Product? newValue) {
                                                setState(() {
                                                  selectedProduct = newValue;
                                                });
                                                if (newValue != null) {
                                                  priceController.text =
                                                      newValue.listPrice == null
                                                          ? ''
                                                          : newValue.listPrice
                                                              .toString();
                                                  itemDescriptionController
                                                          .text =
                                                      "${newValue.productName}";
                                                }
                                              },
                                              validator: (value) =>
                                                  value == null
                                                      ? "Select a product?"
                                                      : null,
                                            );
                                          default:
                                            return const Center(
                                                child: LoadingIndicator());
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
                                      BlocBuilder<GlAccountBloc,
                                              GlAccountState>(
                                          builder: (context, glAccountState) {
                                        switch (glAccountState.status) {
                                          case GlAccountStatus.failure:
                                            return const FatalErrorForm(
                                                message:
                                                    'server connection problem');
                                          case GlAccountStatus.success:
                                            return DropdownSearch<GlAccount>(
                                              selectedItem: selectedGlAccount,
                                              popupProps: PopupProps.menu(
                                                isFilterOnline: true,
                                                showSelectedItems: true,
                                                showSearchBox: true,
                                                searchFieldProps:
                                                    const TextFieldProps(
                                                  autofocus: true,
                                                  decoration: InputDecoration(
                                                      labelText: 'Gl Account'),
                                                ),
                                                menuProps: MenuProps(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20.0)),
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
                                                              labelText:
                                                                  'GL Account')),
                                              key: const Key('glAccount'),
                                              itemAsString: (GlAccount? u) =>
                                                  " ${u?.accountCode} ${u?.accountName} ",
                                              asyncItems:
                                                  (String filter) async {
                                                glAccountBloc.add(
                                                    GlAccountFetch(
                                                        searchString: filter,
                                                        limit: 3));
                                                return Future.delayed(
                                                    const Duration(
                                                        milliseconds: 100), () {
                                                  return Future.value(
                                                      glAccountBloc
                                                          .state.glAccounts);
                                                });
                                              },
                                              compareFn: (item, sItem) =>
                                                  item.accountCode ==
                                                  sItem.accountCode,
                                              onChanged: (GlAccount? newValue) {
                                                selectedGlAccount = newValue!;
                                              },
                                            );
                                          default:
                                            return const Center(
                                                child: LoadingIndicator());
                                        }
                                      }),
                                      const SizedBox(height: 20),
                                      Row(children: [
                                        Expanded(
                                          child: ElevatedButton(
                                            key: const Key('ok'),
                                            child: const Text('Add product'),
                                            onPressed: () {
                                              if (addProductFormKey
                                                  .currentState!
                                                  .validate()) {
                                                Navigator.of(context)
                                                    .pop(FinDocItem(
                                                  itemType: ItemType(
                                                      itemTypeId:
                                                          'ItemProduct'),
                                                  productId: selectedProduct!
                                                      .productId,
                                                  price: Decimal.parse(
                                                      priceController.text),
                                                  description:
                                                      itemDescriptionController
                                                          .text,
                                                  glAccount: selectedGlAccount,
                                                  quantity: quantityController
                                                          .text.isEmpty
                                                      ? Decimal.parse('1')
                                                      : Decimal.parse(
                                                          quantityController
                                                              .text),
                                                ));
                                              }
                                            },
                                          ),
                                        )
                                      ])
                                    ])))))));
          },
        );
      });
}
