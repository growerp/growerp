/*
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

import '../../../../growerp_order_accounting.dart';
import 'package:growerp_order_accounting/l10n/generated/order_accounting_localizations.dart';

Future addAnotherItemDialog(
  BuildContext context,
  bool sales,
  CartState state,
) async {
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
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        child: popUp(
          context: context,
          height: 520,
          title: 'Add another Item',
          child: SizedBox(
            child: Form(
              key: addOtherFormKey,
              child: SingleChildScrollView(
                key: const Key('listView2'),
                child: Column(
                  children: <Widget>[
                    DropdownButtonFormField<ItemType>(
                      key: const Key('itemType'),
                      decoration: const InputDecoration(labelText: 'Item Type'),
                      hint: Text(OrderAccountingLocalizations.of(context)!.itemtype),
                      initialValue: selectedItemType,
                      validator: (value) =>
                          value == null ? 'field required' : null,
                      items: state.itemTypes.map((item) {
                        return DropdownMenuItem<ItemType>(
                          value: item,
                          child: Text(
                            "${item.itemTypeName} ${item.accountCode} ${item.accountName}",
                          ),
                        );
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
                        labelText: 'Item Description',
                      ),
                      controller: itemDescriptionController,
                      validator: (value) {
                        if (value!.isEmpty) return 'Item description?';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      key: const Key('price'),
                      decoration: const InputDecoration(
                        labelText: 'Price/Amount',
                      ),
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
                      decoration: const InputDecoration(labelText: 'Quantity'),
                      controller: quantityController,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 20),
                    OutlinedButton(
                      key: const Key('ok'),
                      child: Text(OrderAccountingLocalizations.of(context)!.ok),
                      onPressed: () {
                        if (addOtherFormKey.currentState!.validate()) {
                          Navigator.of(context).pop(
                            FinDocItem(
                              itemType: selectedItemType,
                              price: Decimal.parse(priceController.text),
                              description: itemDescriptionController.text,
                              quantity: quantityController.text.isEmpty
                                  ? Decimal.parse('1')
                                  : Decimal.parse(quantityController.text),
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
