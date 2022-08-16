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
import 'dart:io';
import 'package:core/domains/common/functions/helper_functions.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:image_picker/image_picker.dart';
import 'package:responsive_framework/responsive_wrapper.dart';
import 'package:core/domains/domains.dart';
import 'package:core/templates/@templates.dart';
import '../../../api_repository.dart';

final GlobalKey<ScaffoldMessengerState> ProductDialogKey =
    GlobalKey<ScaffoldMessengerState>();

class ProductDialog extends StatelessWidget {
  final Product product;
  const ProductDialog(this.product);
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (BuildContext context) =>
          CategoryBloc(context.read<APIRepository>())..add(CategoryFetch()),
      child: ProductDialogFull(product),
    );
  }
}

class ProductDialogFull extends StatefulWidget {
  final Product product;
  const ProductDialogFull(this.product);
  @override
  _ProductState createState() => _ProductState(product);
}

class _ProductState extends State<ProductDialogFull> {
  final Product product;
  _ProductState(this.product);

  final _formKey = GlobalKey<FormState>();
  TextEditingController _nameController = TextEditingController();
  TextEditingController _descriptionController = TextEditingController();
  TextEditingController _priceController = TextEditingController();
  TextEditingController _listPriceController = TextEditingController();
  TextEditingController _assetsController = TextEditingController();

  late bool useWarehouse;
  String? _selectedTypeId;
  XFile? _imageFile;
  dynamic _pickImageError;
  String? _retrieveDataError;
  late String classificationId;
  final ImagePicker _picker = ImagePicker();
  late List<Category> _selectedCategories;

  @override
  void initState() {
    super.initState();
    _nameController.text = product.productName ?? '';
    _descriptionController.text = product.description ?? '';
    _priceController.text =
        product.price == null ? '' : product.price.toString();
    _listPriceController.text =
        product.listPrice == null ? '' : product.listPrice.toString();
    _assetsController.text =
        product.assetCount == null ? '' : product.assetCount.toString();
    _selectedCategories = List.of(product.categories);
    _selectedTypeId = product.productTypeId ?? null;
    classificationId = GlobalConfiguration().get("classificationId");
    useWarehouse = product.useWarehouse;
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
    bool isPhone = ResponsiveWrapper.of(context).isSmallerThan(TABLET);
    if (classificationId == 'AppHotel') _selectedTypeId = 'Rental';
    return BlocConsumer<ProductBloc, ProductState>(
        listener: (context, state) async {
      switch (state.status) {
        case ProductStatus.success:
          Navigator.of(context).pop();
          break;
        case ProductStatus.failure:
          ProductDialogKey.currentState!
              .showSnackBar(snackBar(context, Colors.red, state.message ?? ''));
          break;
        default:
      }
    }, builder: (context, productState) {
      return BlocConsumer<CategoryBloc, CategoryState>(
          listener: (context, categoryState) async {
        switch (categoryState.status) {
          case CategoryStatus.failure:
            HelperFunctions.showMessage(
                context,
                'Error getting categories: ${categoryState.message}',
                Colors.red);
            break;
          default:
        }
      }, builder: (context, categoryState) {
        return Stack(children: [
          Dialog(
              key: Key('ProductDialog'),
              insetPadding: EdgeInsets.all(20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(clipBehavior: Clip.none, children: [
                Container(
                    width: isPhone ? 400 : 800,
                    height: isPhone ? 900 : 600,
                    padding: EdgeInsets.all(20),
                    child: listChild(classificationId, isPhone, categoryState)),
                Container(
                    height: 50,
                    width: isPhone ? 400 : 800,
                    decoration: BoxDecoration(
                        color: Theme.of(context).primaryColorDark,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        )),
                    child: Center(
                        child: Text('Product Information',
                            style: TextStyle(
                                fontSize: 20,
                                color: Colors.white,
                                fontWeight: FontWeight.bold)))),
                Positioned(top: 5, right: 5, child: DialogCloseButton())
              ])),
          if (productState.status == ProductStatus.updateLoading ||
              categoryState.status == CategoryStatus.loading)
            LoadingIndicator()
        ]);
      });
    });
  }

  Widget listChild(String classificationId, bool isPhone, state) {
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
                return _showForm(classificationId, isPhone, state);
              })
          : _showForm(classificationId, isPhone, state);
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

  Widget _showForm(String classificationId, bool isPhone, CategoryState state) {
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

    List<Widget> _relCategories = [];
    _selectedCategories.asMap().forEach((index, category) {
      _relCategories.add(InputChip(
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
    _relCategories.add(IconButton(
      iconSize: 25,
      icon: Icon(Icons.add_circle),
      color: Colors.deepOrange,
      padding: const EdgeInsets.all(0.0),
      key: Key('addCategories'),
      onPressed: () async {
        var result = await showDialog(
            context: context,
            builder: (BuildContext context) {
              return MultiSelect<Category>(
                title: 'Select one or more categories',
                items: state.categories,
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

    List<Widget> _widgets = [
      TextFormField(
        key: Key('name'),
        decoration: InputDecoration(
            labelText: classificationId == 'AppHotel'
                ? 'Room Type Name'
                : 'Product Name'),
        controller: _nameController,
        validator: (value) {
          return value!.isEmpty ? 'Please enter a name?' : null;
        },
      ),
      TextFormField(
        key: Key('description'),
        maxLines: 3,
        decoration: InputDecoration(labelText: 'Description'),
        controller: _descriptionController,
        validator: (value) {
          return value!.isEmpty ? 'Please enter a description?' : null;
        },
      ),
      Row(
        children: [
          Expanded(
            child: TextFormField(
              key: Key('listPrice'),
              decoration: InputDecoration(labelText: 'List Price'),
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp('[0-9.,]+'))
              ],
              controller: _listPriceController,
              validator: (value) {
                return value!.isEmpty ? 'Please enter a list price?' : null;
              },
            ),
          ),
          Expanded(
            child: TextFormField(
              key: Key('price'),
              decoration: InputDecoration(labelText: 'Current Price'),
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp('[0-9.,]+'))
              ],
              controller: _priceController,
            ),
          )
        ],
      ),
      Visibility(
          visible: classificationId != 'AppHotel',
          child: Container(
              child: InputDecorator(
                  decoration: InputDecoration(
                      labelText: 'Related categories',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25.0),
                      )),
                  child: Wrap(spacing: 10.0, children: _relCategories)))),
      Visibility(
          visible: classificationId != 'AppHotel',
          child: DropdownButtonFormField<String>(
            key: Key('productTypeDropDown'),
            value: _selectedTypeId,
            decoration: InputDecoration(labelText: 'Product Type'),
            validator: (value) {
              return value == null ? 'field required' : null;
            },
            items: productTypes.map((item) {
              return DropdownMenuItem<String>(
                  child: Text(item, style: TextStyle(color: Color(0xFF4baa9b))),
                  value: item);
            }).toList(),
            onChanged: (String? newValue) {
              _selectedTypeId = newValue!;
            },
            isExpanded: true,
          )),
      Visibility(
          visible: classificationId != 'AppHotel',
          child: Row(
            children: [
              Expanded(
                child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25.0),
                      border: Border.all(
                          color: Colors.black45,
                          style: BorderStyle.solid,
                          width: 0.80),
                    ),
                    child: CheckboxListTile(
                        key: Key('useWarehouse'),
                        title: Text("Use Warehouse?",
                            style: TextStyle(color: Color(0xFF4baa9b))),
                        value: useWarehouse,
                        onChanged: (bool? value) {
                          setState(() {
                            useWarehouse = value!;
                          });
                        })),
              ),
              Expanded(
                child: TextFormField(
                  key: Key('assets'),
                  decoration: InputDecoration(labelText: 'Assets in warehouse'),
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.allow(RegExp('[0-9.,]+'))
                  ],
                  controller: _assetsController,
                ),
              )
            ],
          )),
      Row(children: [
        Expanded(
            child: ElevatedButton(
                key: Key('update'),
                child: Text(product.productId.isEmpty ? 'Create' : 'Update'),
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    Uint8List? image =
                        await HelperFunctions.getResizedImage(_imageFile?.path);
                    if (_imageFile?.path != null && image == null)
                      HelperFunctions.showMessage(
                          context, "Image upload error!", Colors.red);
                    else
                      context.read<ProductBloc>().add(ProductUpdate(Product(
                          productId: product.productId,
                          productName: _nameController.text,
                          assetClassId: classificationId == 'AppHotel'
                              ? 'Hotel Room'
                              : null,
                          description: _descriptionController.text,
                          listPrice: Decimal.parse(_listPriceController.text),
                          price: Decimal.parse(_priceController.text.isEmpty
                              ? '0.00'
                              : _priceController.text),
                          assetCount: _assetsController.text.isEmpty
                              ? 0
                              : int.parse(_assetsController.text),
                          categories: _selectedCategories,
                          productTypeId: _selectedTypeId,
                          useWarehouse: useWarehouse,
                          image: image)));
                  }
                }))
      ])
    ];

    List<Widget> rows = [];
    if (!ResponsiveWrapper.of(context).isSmallerThan(TABLET)) {
      // change list in two columns
      for (var i = 0; i < _widgets.length; i++)
        rows.add(Row(
          children: [
            Expanded(
                child:
                    Padding(padding: EdgeInsets.all(10), child: _widgets[i++])),
            Expanded(
                child: Padding(
                    padding: EdgeInsets.all(10),
                    child: i < _widgets.length ? _widgets[i] : Container()))
          ],
        ));
    }
    List<Widget> column = [];
    for (var i = 0; i < _widgets.length; i++)
      column.add(Padding(padding: EdgeInsets.all(10), child: _widgets[i]));

    return ScaffoldMessenger(
      key: ProductDialogKey,
      child: Scaffold(
          backgroundColor: Colors.transparent,
          floatingActionButton: imageButtons(context, _onImageButtonPressed),
          body: Form(
              key: _formKey,
              child: SingleChildScrollView(
                  key: Key('listView'),
                  child: Column(children: <Widget>[
                    SizedBox(height: 50),
                    Center(
                        child: Text(
                      'Product #${product.productId.isEmpty ? " New" : product.productId}',
                      style: TextStyle(
                          fontSize: 10,
                          color: Colors.black,
                          fontWeight: FontWeight.bold),
                      key: Key('header'),
                    )),
                    SizedBox(height: 10),
                    CircleAvatar(
                        backgroundColor: Colors.green,
                        radius: 80,
                        child: _imageFile != null
                            ? foundation.kIsWeb
                                ? Image.network(_imageFile!.path, scale: 0.3)
                                : Image.file(File(_imageFile!.path), scale: 0.3)
                            : product.image != null
                                ? Image.memory(product.image!, scale: 0.3)
                                : Text(
                                    product.productName?.substring(0, 1) ?? '',
                                    style: TextStyle(
                                        fontSize: 30, color: Colors.black))),
                    SizedBox(height: 10),
                    Column(children: (rows.isEmpty ? column : rows)),
                  ])))),
    );
  }
}
