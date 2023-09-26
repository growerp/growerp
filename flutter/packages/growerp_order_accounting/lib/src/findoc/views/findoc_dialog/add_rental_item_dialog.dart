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
import 'package:growerp_core/growerp_core.dart';
import 'package:intl/intl.dart';
import 'package:growerp_models/growerp_models.dart';

import '../../../../growerp_order_accounting.dart';

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
                                                  " ${u!.productName}",
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
