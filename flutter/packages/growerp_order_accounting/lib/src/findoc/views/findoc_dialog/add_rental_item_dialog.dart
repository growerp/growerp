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
import 'package:intl/intl.dart';
import 'package:growerp_models/growerp_models.dart';

import '../../../../growerp_order_accounting.dart';

/// [addRentalItemDialog] add a rental order item [FinDocItem]
Future addRentalItemDialog(
  BuildContext context,
  DataFetchBloc<Products> productBloc,
  FinDocBloc finDocBloc,
) async {
  final priceController = TextEditingController();
  final itemDescriptionController = TextEditingController();
  final quantityController = TextEditingController();
  Product? selectedProduct;
  DateTime startDate = CustomizableDateTime.current;
  List<DateTime> rentalDays = [];
  String classificationId = context.read<String>();
  quantityController.text = quantityController.text == ''
      ? '1'
      : quantityController.text; // Default quantity for rental items is 1 day

  return showDialog<FinDocItem>(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      bool whichDayOk(DateTime day) {
        var formatter = DateFormat('yyyy-MM-dd');
        String date = formatter.format(day);
        if (rentalDays.any((d) => formatter.format(d) == date)) return false;
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
              borderRadius: BorderRadius.all(Radius.circular(20)),
            ),
            child: popUp(
              context: context,
              height: 600,
              title: 'Add a Reservation',
              child: StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) {
                  Future<void> selectDate(BuildContext context) async {
                    finDocBloc.add(
                      FinDocProductRentalDates(selectedProduct?.productId),
                    );
                    // Get locale from LocaleBloc to respect user's language selection
                    final localeState = context.read<LocaleBloc>().state;
                    final themeState = context.read<ThemeBloc>().state;

                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: firstFreeDate(),
                      firstDate: CustomizableDateTime.current,
                      lastDate: DateTime(CustomizableDateTime.current.year + 1),
                      selectableDayPredicate: whichDayOk,
                      locale: localeState.locale,
                      builder: (BuildContext context, Widget? child) {
                        final isDark = themeState.themeMode == ThemeMode.dark;
                        final surfaceColor = isDark
                            ? Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest
                            : Theme.of(context).colorScheme.surface;

                        return Theme(
                          data: isDark
                              ? ThemeData.dark(useMaterial3: true).copyWith(
                                  primaryColor: Colors.green,
                                  colorScheme: ColorScheme.dark(
                                    primary: Colors.green,
                                    secondary: Colors.green,
                                    surface: surfaceColor,
                                  ),
                                  scaffoldBackgroundColor: surfaceColor,
                                )
                              : ThemeData.light(useMaterial3: true).copyWith(
                                  primaryColor: Colors.green,
                                  colorScheme: ColorScheme.light(
                                    primary: Colors.green,
                                    secondary: Colors.green,
                                    surface: surfaceColor,
                                  ),
                                ),
                          child: child!,
                        );
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
                                          ? '${selectedProduct!.productName}[${selectedProduct!.pseudoId}]'
                                          : '',
                                    ),
                                    displayStringForOption: (Product u) =>
                                        '${u.productName}[${u.pseudoId}]',
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
                                                '${p.productName}[${p.pseudoId}]'
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
                                            decoration: InputDecoration(
                                              labelText:
                                                  classificationId == 'AppHotel'
                                                  ? 'Room Type'
                                                  : 'Product',
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
                                                        '${p.productName}[${p.pseudoId}]',
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
                                    onSelected: (Product newValue) async {
                                      selectedProduct = newValue;
                                      priceController.text = newValue.price
                                          .toString();
                                      itemDescriptionController.text =
                                          newValue.productName ?? '';
                                      finDocBloc.add(
                                        FinDocProductRentalDates(
                                          newValue.productId,
                                        ),
                                      );
                                      await Future.delayed(
                                        const Duration(milliseconds: 800),
                                        () {},
                                      );
                                      setState(() {
                                        rentalDays =
                                            finDocBloc
                                                .state
                                                .productRentalDates
                                                .isNotEmpty
                                            ? finDocBloc
                                                  .state
                                                  .productRentalDates[0]
                                                  .dates
                                            : [];
                                        startDate = firstFreeDate();
                                      });
                                    },
                                  );
                                default:
                                  return const Center(
                                    child: LoadingIndicator(),
                                  );
                              }
                            },
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            key: const Key('itemDescription'),
                            decoration: const InputDecoration(
                              labelText: 'Item Description',
                            ),
                            controller: itemDescriptionController,
                            validator: (value) =>
                                value!.isEmpty ? 'Item description?' : null,
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            key: const Key('price'),
                            decoration: const InputDecoration(
                              labelText: 'Price/Amount',
                            ),
                            controller: priceController,
                            validator: (value) =>
                                value!.isEmpty ? 'Enter Price?' : null,
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: FormField<DateTime>(
                                  key: const Key('setDate'),
                                  initialValue: startDate,
                                  validator: (value) => value == null
                                      ? 'Select a start date'
                                      : null,
                                  builder: (field) => InkWell(
                                    onTap: () async {
                                      await selectDate(context);
                                      field.didChange(startDate);
                                    },
                                    child: InputDecorator(
                                      decoration: InputDecoration(
                                        labelText: 'Start Date',
                                        errorText: field.errorText,
                                        suffixIcon: const Icon(
                                          Icons.arrow_drop_down,
                                        ),
                                      ),
                                      child: Text(
                                        "${startDate.toLocal()}".split(' ')[0],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextFormField(
                                  key: const Key('quantity'),
                                  decoration: const InputDecoration(
                                    labelText: 'Number of days',
                                  ),
                                  controller: quantityController,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  key: const Key('okRental'),
                                  child: const Text('Add reservation'),
                                  onPressed: () {
                                    if (addRentalFormKey.currentState!
                                        .validate()) {
                                      Navigator.of(context).pop(
                                        FinDocItem(
                                          itemType: ItemType(
                                            itemTypeId: 'ItemRental',
                                          ),
                                          product: selectedProduct!,
                                          price: Decimal.parse(
                                            priceController.text,
                                          ),
                                          description:
                                              itemDescriptionController.text,
                                          rentalFromDate: startDate.noon(),
                                          rentalThruDate: startDate
                                              .add(
                                                Duration(
                                                  days: int.parse(
                                                    quantityController.text,
                                                  ),
                                                ),
                                              )
                                              .noon(),
                                          quantity: Decimal.parse(
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
                  );
                },
              ),
            ),
          ),
        ),
      );
    },
  );
}
