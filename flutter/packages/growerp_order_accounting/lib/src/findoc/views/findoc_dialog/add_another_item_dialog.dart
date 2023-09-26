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
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

import '../../../../growerp_order_accounting.dart';

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
