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
import 'package:universal_io/io.dart';

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:intl/intl.dart';

import '../../../accounting/accounting.dart';

Future addProductItemDialog(BuildContext context) async {
  final priceController = TextEditingController();
  final itemDescriptionController = TextEditingController();
  final quantityController = TextEditingController();
  GlAccount? selectedGlAccount;
  Product? selectedProduct;
  GlAccountBloc glAccountBloc = context.read<GlAccountBloc>();
  DataFetchBloc<Products> productBloc = context.read<DataFetchBloc<Products>>();
  String currencyId = context
      .read<AuthBloc>()
      .state
      .authenticate!
      .company!
      .currency!
      .currencyId!;
  String currencySymbol = NumberFormat.simpleCurrency(
    locale: Platform.localeName,
    name: currencyId,
  ).currencySymbol;
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
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                ),
                child: popUp(
                  context: context,
                  height: 600,
                  title: 'Add a Product',
                  child: Form(
                    key: addProductFormKey,
                    child: SingleChildScrollView(
                      key: const Key('listView'),
                      child: Column(
                        children: <Widget>[
                          BlocBuilder<DataFetchBloc<Products>, DataFetchState>(
                            builder: (context, state) {
                              switch (state.status) {
                                case DataFetchStatus.failure:
                                  return const FatalErrorForm(
                                    message: 'server connection problem',
                                  );
                                case DataFetchStatus.loading:
                                  return const LoadingIndicator();
                                case DataFetchStatus.success:
                                  return Autocomplete<Product>(
                                    key: const Key('product'),
                                    initialValue: TextEditingValue(
                                      text: selectedProduct != null
                                          ? " ${selectedProduct!.productName}[${selectedProduct!.pseudoId}]"
                                          : '',
                                    ),
                                    displayStringForOption: (Product u) =>
                                        " ${u.productName}[${u.pseudoId}]",
                                    optionsBuilder:
                                        (TextEditingValue textEditingValue) {
                                          final products =
                                              (productBloc.state.data
                                                      as Products)
                                                  .products;
                                          final query = textEditingValue.text
                                              .toLowerCase()
                                              .trim();
                                          if (query.isEmpty) return products;
                                          return products.where((p) {
                                            final display =
                                                " ${p.productName}[${p.pseudoId}]"
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
                                            key: const Key('productField'),
                                            controller: textController,
                                            focusNode: focusNode,
                                            decoration: const InputDecoration(
                                              labelText: 'Product',
                                            ),
                                            onFieldSubmitted: (_) =>
                                                onFieldSubmitted(),
                                            validator: (value) =>
                                                (value == null || value.isEmpty)
                                                ? "Select a product?"
                                                : null,
                                          );
                                        },
                                    optionsViewBuilder:
                                        (context, onSelected, options) {
                                          return Align(
                                            alignment: Alignment.topLeft,
                                            child: Material(
                                              elevation: 4,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              child: ConstrainedBox(
                                                constraints:
                                                    const BoxConstraints(
                                                      maxHeight: 250,
                                                      maxWidth: 400,
                                                    ),
                                                child: ListView.builder(
                                                  padding: EdgeInsets.zero,
                                                  shrinkWrap: true,
                                                  itemCount: options.length,
                                                  itemBuilder: (context, idx) {
                                                    final p = options.elementAt(
                                                      idx,
                                                    );
                                                    return ListTile(
                                                      dense: true,
                                                      title: Text(
                                                        " ${p.productName}[${p.pseudoId}]",
                                                      ),
                                                      onTap: () =>
                                                          onSelected(p),
                                                    );
                                                  },
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                    onSelected: (Product newValue) {
                                      setState(() {
                                        selectedProduct = newValue;
                                      });
                                      priceController.text =
                                          newValue.price == null
                                          ? ''
                                          : newValue.price.currency(
                                              currencyId: '',
                                            );
                                      itemDescriptionController.text =
                                          "${newValue.productName}";
                                    },
                                  );
                                default:
                                  return const Center(
                                    child: LoadingIndicator(),
                                  );
                              }
                            },
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            key: const Key('itemDescription'),
                            decoration: const InputDecoration(
                              labelText: 'Item Description',
                            ),
                            controller: itemDescriptionController,
                            validator: (value) {
                              if (value!.isEmpty) {
                                return 'Item description?';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            key: const Key('itemPrice'),
                            decoration: InputDecoration(
                              labelText: 'Price/Amount($currencySymbol)',
                            ),
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
                                RegExp('[0-9.,]+'),
                              ),
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Quantity',
                            ),
                            controller: quantityController,
                            validator: (value) =>
                                value == null ? "Enter a quantity?" : null,
                          ),
                          const SizedBox(height: 20),
                          BlocBuilder<GlAccountBloc, GlAccountState>(
                            builder: (context, glAccountState) {
                              switch (glAccountState.status) {
                                case GlAccountStatus.failure:
                                  return const FatalErrorForm(
                                    message: 'server connection problem',
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
                                            return glAccountBloc
                                                .state
                                                .glAccounts;
                                          }
                                          return glAccountBloc.state.glAccounts
                                              .where((gl) {
                                                final display =
                                                    " ${gl.accountCode} ${gl.accountName} "
                                                        .toLowerCase();
                                                return display.contains(query);
                                              })
                                              .toList();
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
                                            decoration: const InputDecoration(
                                              labelText: 'GL Account',
                                            ),
                                            onFieldSubmitted: (_) =>
                                                onFieldSubmitted(),
                                          );
                                        },
                                    optionsViewBuilder:
                                        (context, onSelected, options) {
                                          return Align(
                                            alignment: Alignment.topLeft,
                                            child: Material(
                                              elevation: 4,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              child: ConstrainedBox(
                                                constraints:
                                                    const BoxConstraints(
                                                      maxHeight: 250,
                                                      maxWidth: 400,
                                                    ),
                                                child: ListView.builder(
                                                  padding: EdgeInsets.zero,
                                                  shrinkWrap: true,
                                                  itemCount: options.length,
                                                  itemBuilder: (context, idx) {
                                                    final gl = options
                                                        .elementAt(idx);
                                                    return ListTile(
                                                      dense: true,
                                                      title: Text(
                                                        " ${gl.accountCode} ${gl.accountName} ",
                                                      ),
                                                      onTap: () =>
                                                          onSelected(gl),
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
                                  return const Center(
                                    child: LoadingIndicator(),
                                  );
                              }
                            },
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  key: const Key('ok'),
                                  child: const Text('Add product'),
                                  onPressed: () {
                                    if (addProductFormKey.currentState!
                                        .validate()) {
                                      Navigator.of(context).pop(
                                        FinDocItem(
                                          itemType: ItemType(
                                            itemTypeId: 'ItemProduct',
                                          ),
                                          product: selectedProduct!,
                                          price: Decimal.parse(
                                            priceController.text,
                                          ),
                                          description:
                                              itemDescriptionController.text,
                                          glAccount: selectedGlAccount,
                                          quantity:
                                              quantityController.text.isEmpty
                                              ? Decimal.parse('1')
                                              : Decimal.parse(
                                                  quantityController.text,
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
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}
