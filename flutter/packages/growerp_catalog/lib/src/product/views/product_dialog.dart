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
import 'package:intl/intl.dart';
import 'package:universal_io/io.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:growerp_models/growerp_models.dart';

import '../../category/blocs/category_bloc.dart';
import '../product.dart';

class ProductDialog extends StatefulWidget {
  final Product product;
  const ProductDialog(this.product, {super.key});
  @override
  ProductDialogState createState() => ProductDialogState();
}

class ProductDialogState extends State<ProductDialog> {
  late final GlobalKey<FormBuilderState> _productDialogFormKey;

  late bool useWarehouse;
  late ProductBloc _productBloc;

  Uom? _selectedUom;
  XFile? _imageFile;
  dynamic _pickImageError;
  String? _retrieveDataError;
  String? _selectedProductTypeId;
  late String classificationId;
  final ImagePicker _picker = ImagePicker();
  late List<Category> _selectedCategories;
  late List<Category> _categories;
  late List<Uom> _uoms;
  List<Uom> _uomTypes = [];
  List<Uom> uomsOfType = [];
  final ScrollController _scrollController = ScrollController();
  late Currency currency;
  late String currencyId;
  late Currency _currencySelected;
  late String currencySymbol;
  late double top;
  double? right;

  @override
  void initState() {
    super.initState();
    currency = context.read<AuthBloc>().state.authenticate!.company!.currency!;
    currencyId = currency.currencyId!;
    currencySymbol = NumberFormat.simpleCurrency(
            locale: Platform.localeName,
            name: widget.product.currency?.currencyId ?? currencyId)
        .currencySymbol;
    _productBloc = context.read<ProductBloc>();
    context
        .read<CategoryBloc>()
        .add(const CategoryFetch(isForDropDown: true, limit: 3));
    classificationId = context.read<String>();
    _selectedCategories = List.of(widget.product.categories);
    useWarehouse = widget.product.useWarehouse;
    _currencySelected = widget.product.currency != null
        ? currencies.firstWhere(
            (x) => x.currencyId == widget.product.currency?.currencyId)
        : currency;
    currencyId = _currencySelected.currencyId!;
    _selectedProductTypeId = widget.product.productTypeId;
    _productDialogFormKey = GlobalKey<FormBuilderState>();
    top = -100;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onImageButtonPressed(ImageSource source,
      {BuildContext? context}) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
      );
      setState(() {
        _imageFile = pickedFile;
      });
    } catch (e) {
      setState(() {
        _pickImageError = e;
      });
    }
  }

  Future<void> retrieveLostData() async {
    final LostDataResponse response = await _picker.retrieveLostData();
    if (response.isEmpty) {
      return;
    }
    if (response.file != null) {
      setState(() {
        _imageFile = response.file;
      });
    } else {
      _retrieveDataError = response.exception!.code;
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isPhone = ResponsiveBreakpoints.of(context).isMobile;
    right = right ?? (isPhone ? 20 : 150);
    if (classificationId == 'AppHotel') _selectedProductTypeId = 'Rental';
    return BlocConsumer<ProductBloc, ProductState>(
        listener: (context, state) async {
      switch (state.status) {
        case ProductStatus.success:
          Navigator.of(context).pop();
        case ProductStatus.failure:
          HelperFunctions.showMessage(context, '${state.message}', Colors.red);
        default:
      }
    }, builder: (context, state) {
      if (state.status == ProductStatus.loading ||
          state.status == ProductStatus.initial) {
        return const LoadingIndicator();
      } else {
        return BlocBuilder<CategoryBloc, CategoryState>(
          builder: (context, categoryState) {
            if (categoryState.status == CategoryStatus.loading ||
                categoryState.status == CategoryStatus.initial) {
              return const LoadingIndicator();
            }
            _categories = categoryState.categories;
            _uoms = state.uoms.isEmpty ? [Uom()] : state.uoms;
            // get unique list of types only
            Set<String> seenUomTypeIds = <String>{};
            _uomTypes = _uoms
                .where((uom) =>
                    uom.uomTypeId.isNotEmpty &&
                    seenUomTypeIds.add(uom.uomTypeId))
                .toList();

            _selectedUom ??= (() {
              if (widget.product.amountUom != null) {
                try {
                  return _uoms.firstWhere(
                      (uom) => uom.uomId == widget.product.amountUom!.uomId);
                } catch (e) {
                  return _uoms.isNotEmpty ? _uoms.first : Uom();
                }
              } else {
                return _uoms.firstWhere((uom) => uom.uomId == 'OTH_ea');
              }
            })();
            uomsOfType = _uoms
                .where((uom) => uom.uomTypeId == _selectedUom?.uomTypeId)
                .toList();

            return Dialog(
                key: const Key('ProductDialog'),
                insetPadding: const EdgeInsets.only(left: 20, right: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: popUp(
                  context: context,
                  title: (classificationId == 'AppAdmin'
                          ? 'Product #'
                          : 'Room Type #') +
                      (widget.product.productId.isEmpty
                          ? 'New'
                          : widget.product.pseudoId),
                  height: isPhone
                      ? (classificationId == 'AppAdmin' ? 850 : 700)
                      : (classificationId == 'AppAdmin' ? 700 : 600),
                  width: isPhone ? 450 : 800,
                  child: listChild(classificationId, isPhone),
                ));
          },
        );
      }
    });
  }

  Widget listChild(String classificationId, bool isPhone) {
    return Builder(builder: (BuildContext context) {
      return !foundation.kIsWeb &&
              foundation.defaultTargetPlatform == TargetPlatform.android
          ? FutureBuilder<void>(
              future: retrieveLostData(),
              builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
                if (snapshot.hasError) {
                  return Text(
                    'Pick image error: ${snapshot.error}}',
                    textAlign: TextAlign.center,
                  );
                }
                return _showForm(classificationId, isPhone);
              })
          : _showForm(classificationId, isPhone);
    });
  }

  Text? _getRetrieveErrorWidget() {
    if (_retrieveDataError != null) {
      final Text result = Text(_retrieveDataError!);
      _retrieveDataError = null;
      return result;
    }
    return null;
  }

  Widget _showForm(String classificationId, bool isPhone) {
    final Text? retrieveError = _getRetrieveErrorWidget();
    if (retrieveError != null) {
      return retrieveError;
    }
    if (_pickImageError != null) {
      return Text(
        'Pick image error: $_pickImageError',
        textAlign: TextAlign.center,
      );
    }

    List<Widget> relCategories = _buildRelatedCategories();

    List<Widget> widgets = _buildFormFields(classificationId, relCategories);

    List<Widget> rows = [];
    if (!ResponsiveBreakpoints.of(context).isMobile) {
      // change list in two columns
      for (var i = 0; i < widgets.length; i++) {
        rows.add(Row(
          children: [
            Expanded(
                flex: 1,
                child: Padding(
                    padding: const EdgeInsets.all(5), child: widgets[i++])),
            Expanded(
                flex: 1,
                child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: i < widgets.length ? widgets[i] : Container()))
          ],
        ));
      }
    }
    List<Widget> column = [];
    for (var i = 0; i < widgets.length; i++) {
      column.add(Padding(
          padding: const EdgeInsets.only(bottom: 10), child: widgets[i]));
    }

    return Stack(
      children: [
        FormBuilder(
            key: _productDialogFormKey,
            child: SingleChildScrollView(
                key: const Key('listView'),
                controller: _scrollController,
                child: Column(children: <Widget>[
                  CircleAvatar(
                      radius: 60,
                      child: _imageFile != null
                          ? foundation.kIsWeb
                              ? Image.network(_imageFile!.path, scale: 0.3)
                              : Image.file(File(_imageFile!.path), scale: 0.3)
                          : widget.product.image != null
                              ? Image.memory(widget.product.image!, scale: 0.3)
                              : Text(
                                  widget.product.productName?.substring(0, 1) ??
                                      '',
                                  style: const TextStyle(fontSize: 30))),
                  const SizedBox(height: 10),
                  Column(children: (rows.isEmpty ? column : rows)),
                ]))),
        Positioned(
          right: right,
          top: top,
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                top += details.delta.dy;
                right = right! - details.delta.dx;
              });
            },
            child: ImageButtons(_scrollController, _onImageButtonPressed),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildRelatedCategories() {
    List<Widget> relCategories = [];
    _selectedCategories.asMap().forEach((index, category) {
      relCategories.add(InputChip(
        label: Text(
          category.categoryName,
          key: Key(category.categoryName),
        ),
        deleteIcon: const Icon(
          Icons.cancel,
          key: Key("deleteChip"),
        ),
        onDeleted: () async {
          setState(() {
            _selectedCategories.removeAt(index);
          });
        },
      ));
    });
    relCategories.add(IconButton(
      iconSize: 25,
      icon: const Icon(Icons.add_circle),
      color: Colors.deepOrange,
      padding: const EdgeInsets.all(0.0),
      key: const Key('addCategories'),
      onPressed: () async {
        var result = await showDialog(
            context: context,
            builder: (BuildContext context) {
              return MultiSelect<Category>(
                title: 'Select one or more categories',
                items: _categories,
                selectedItems: _selectedCategories,
              );
            });
        if (result != null) {
          setState(() {
            _selectedCategories = result;
          });
        }
      },
    ));
    return relCategories;
  }

  List<Widget> _buildFormFields(
      String classificationId, List<Widget> relCategories) {
    return [
      Row(
        children: [
          Expanded(
            flex: 1,
            child: FormBuilderTextField(
              name: 'id',
              key: const Key('id'),
              initialValue: widget.product.pseudoId,
              decoration: InputDecoration(
                  labelText: classificationId == 'AppHotel'
                      ? 'Room Type Id'
                      : 'Product Id'),
            ),
          ),
          if (classificationId != 'AppHotel')
            Expanded(
              flex: 2,
              child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 5, 0, 5),
                  child: FormBuilderDropdown<String>(
                    key: const Key('productTypeDropDown'),
                    name: 'productType',
                    initialValue: _selectedProductTypeId,
                    decoration:
                        const InputDecoration(labelText: 'Product Type'),
                    validator: FormBuilderValidators.compose([
                      FormBuilderValidators.required(),
                    ]),
                    items: productTypes.map((item) {
                      return DropdownMenuItem<String>(
                          value: item,
                          child: Text(item,
                              style:
                                  const TextStyle(color: Color(0xFF4baa9b))));
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedProductTypeId = newValue!;
                      });
                    },
                  )),
            ),
        ],
      ),
      FormBuilderTextField(
        name: 'name',
        key: const Key('name'),
        initialValue: widget.product.productName ?? '',
        decoration: InputDecoration(
            labelText: classificationId == 'AppHotel'
                ? 'Room Type Name'
                : 'Product Name'),
        validator: FormBuilderValidators.compose([
          FormBuilderValidators.required(),
        ]),
      ),
      FormBuilderTextField(
        name: 'description',
        key: const Key('description'),
        initialValue: widget.product.description ?? '',
        maxLines: 3,
        decoration: const InputDecoration(labelText: 'Description'),
        validator: FormBuilderValidators.compose([
          FormBuilderValidators.required(),
        ]),
      ),
      InputDecorator(
        decoration: InputDecoration(
            labelText: 'Prices',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(25.0),
            )),
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: FormBuilderTextField(
                name: 'listPrice',
                key: const Key('listPrice'),
                initialValue: widget.product.listPrice == null
                    ? ''
                    : widget.product.listPrice.currency(currencyId: ''),
                decoration:
                    InputDecoration(labelText: 'List Price($currencySymbol)'),
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(RegExp('[0-9.,]+'))
                ],
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(),
                ]),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 1,
              child: FormBuilderTextField(
                name: 'price',
                key: const Key('price'),
                initialValue: widget.product.price == null
                    ? ''
                    : widget.product.price.currency(currencyId: ''),
                decoration: InputDecoration(
                    labelText: 'Current Price($currencySymbol)'),
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(RegExp('[0-9.,]+'))
                ],
              ),
            ),
            Expanded(
              flex: 1,
              child: FormBuilderDropdown<Currency>(
                name: 'currency',
                key: const Key('currency'),
                initialValue: _currencySelected,
                decoration: const InputDecoration(labelText: 'Currency'),
                hint: const Text('Currency'),
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(
                      errorText: 'Currency field required!'),
                ]),
                items: currencies.map((item) {
                  return DropdownMenuItem<Currency>(
                      value: item, child: Text(item.currencyId!));
                }).toList(),
                onChanged: (Currency? newValue) {
                  setState(() {
                    _currencySelected = newValue!;
                  });
                },
              ),
            ),
          ],
        ),
      ),
      if (classificationId != 'AppHotel')
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 5, 0, 5),
          child: InputDecorator(
              decoration: InputDecoration(
                  labelText: 'Related categories',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25.0),
                  )),
              child: Wrap(spacing: 10.0, children: relCategories)),
        ),
      if (classificationId != 'AppHotel' && _selectedProductTypeId != 'Service')
        InputDecorator(
            decoration: InputDecoration(
                labelText: 'Warehouse/Inventory',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                )),
            child: Row(
              children: [
                Expanded(
                  child: FormBuilderCheckbox(
                      key: const Key('useWarehouse'),
                      name: 'useWarehouse',
                      initialValue: useWarehouse,
                      title: const Text("Use Warehouse?",
                          style: TextStyle(color: Color(0xFF4baa9b))),
                      onChanged: (bool? value) {
                        setState(() {
                          useWarehouse = value ?? false;
                        });
                      }),
                ),
                Expanded(
                  child: FormBuilderTextField(
                    name: 'assets',
                    key: const Key('assets'),
                    initialValue: widget.product.assetCount == null
                        ? ''
                        : widget.product.assetCount.toString(),
                    decoration:
                        const InputDecoration(labelText: 'Assets in warehouse'),
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.allow(RegExp('[0-9.,]+'))
                    ],
                  ),
                ),
              ],
            )),
      InputDecorator(
          decoration: InputDecoration(
              labelText: 'Type/Amount',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25.0),
              )),
          child: Column(
            children: [
              Row(
                children: [
                  // UOM Type dropdown (first level)
                  Expanded(
                    child: FormBuilderDropdown<Uom>(
                      key: const Key('uomTypeDropDown'),
                      name: 'uomType',
                      initialValue: _uomTypes.any(
                              (uom) => uom.uomTypeId == _selectedUom?.uomTypeId)
                          ? _uomTypes.firstWhere(
                              (uom) => uom.uomTypeId == _selectedUom?.uomTypeId)
                          : (_uomTypes.isNotEmpty ? _uoms.first : null),
                      decoration: const InputDecoration(labelText: 'UOM Type'),
                      items: _uomTypes.map((uom) {
                        return DropdownMenuItem<Uom>(
                            value: uom,
                            child: Text(uom.typeDescription,
                                style:
                                    const TextStyle(color: Color(0xFF4baa9b))));
                      }).toList(),
                      onChanged: (Uom? newValue) {
                        if (newValue != null) {
                          setState(() {
                            // Find the first UOM of the selected type
                            uomsOfType = _uoms
                                .where((uom) =>
                                    uom.uomTypeId == newValue.uomTypeId)
                                .toList();
                            // Set selected UOM to the first item of the new type
                            if (uomsOfType.isNotEmpty) {
                              _selectedUom = uomsOfType.first;

                              // Update the form field value using patchValue
                              _productDialogFormKey.currentState?.patchValue({
                                'uom': _selectedUom,
                              });
                            }
                          });
                        }
                      },
                    ),
                  ),
                  // UOM dropdown (second level - dependent on UOM Type)
                  Expanded(
                    child: Semantics(
                        key: const Key('uomDropDown'),
                        child: FormBuilderDropdown<Uom>(
                          key: ValueKey(
                              'uom_${_selectedUom?.uomTypeId}'), // Force rebuild when type changes
                          name: 'uom',
                          initialValue: _selectedUom,
                          decoration: const InputDecoration(
                              labelText: 'Unit of Measure'),
                          validator: (value) {
                            return value == null
                                ? 'Please select a unit of measure'
                                : null;
                          },
                          items: uomsOfType.map((uom) {
                            return DropdownMenuItem<Uom>(
                                value: uom,
                                child: Text(uom.description,
                                    style: const TextStyle(
                                        color: Color(0xFF4baa9b))));
                          }).toList(),
                          onChanged: (Uom? newValue) {
                            if (newValue != null) {
                              _selectedUom = newValue;
                            }
                          },
                        )),
                  ),
                ],
              ),
              // Amount field
              FormBuilderTextField(
                name: 'amount',
                key: const Key('amount'),
                initialValue: widget.product.amount == null
                    ? '1'
                    : widget.product.amount.toString(),
                decoration: const InputDecoration(labelText: 'Amount/Quantity'),
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(RegExp('[0-9.,]+'))
                ],
              ),
            ],
          )),
      OutlinedButton(
          key: const Key('update'),
          child: Text(widget.product.productId.isEmpty ? 'Create' : 'Update'),
          onPressed: () async {
            if (_productDialogFormKey.currentState!.saveAndValidate()) {
              final formData = _productDialogFormKey.currentState!.value;
              Uint8List? image =
                  await HelperFunctions.getResizedImage(_imageFile?.path);
              if (!mounted) return;
              if (_imageFile?.path != null && image == null) {
                HelperFunctions.showMessage(
                    context, "Image upload error!", Colors.red);
              } else {
                _productBloc.add(ProductUpdate(Product(
                    productId: widget.product.productId,
                    pseudoId: formData['id'] ?? '',
                    productName: formData['name'] ?? '',
                    assetClassId: classificationId == 'AppHotel'
                        ? 'Hotel Room'
                        : 'AsClsInventoryFin', // finished good
                    description: formData['description'] ?? '',
                    listPrice: Decimal.parse(formData['listPrice'] ?? '0.00'),
                    price: Decimal.parse(
                        formData['price'].isEmpty ? '0.00' : formData['price']),
                    currency: formData['currency'] ?? _currencySelected,
                    amount: Decimal.parse(formData['amount'].isEmpty
                        ? '0.00'
                        : formData['amount']),
                    amountUom: formData['amountUom'] ?? _selectedUom,
                    assetCount:
                        formData['assets'] == null || formData['assets'].isEmpty
                            ? 0
                            : int.parse(formData['assets']),
                    categories: _selectedCategories,
                    productTypeId:
                        formData['productType'] ?? _selectedProductTypeId,
                    useWarehouse:
                        (formData['productType'] ?? _selectedProductTypeId) ==
                                'Service'
                            ? false
                            : formData['useWarehouse'] ?? false,
                    image: image)));
              }
            }
          })
    ];
  }
}
