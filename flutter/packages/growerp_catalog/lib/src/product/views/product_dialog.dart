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

final GlobalKey<ScaffoldMessengerState> productDialogKey =
    GlobalKey<ScaffoldMessengerState>();

class ProductDialog extends StatefulWidget {
  final Product product;
  const ProductDialog(this.product, {super.key});
  @override
  ProductDialogState createState() => ProductDialogState();
}

class ProductDialogState extends State<ProductDialog> {
  late final GlobalKey<FormState> _productDialogFormKey;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _listPriceController = TextEditingController();
  final TextEditingController _assetsController = TextEditingController();

  late bool useWarehouse;
  late ProductBloc _productBloc;

  String? _selectedTypeId;
  XFile? _imageFile;
  dynamic _pickImageError;
  String? _retrieveDataError;
  late String classificationId;
  final ImagePicker _picker = ImagePicker();
  late List<Category> _selectedCategories;
  final ScrollController _scrollController = ScrollController();
  late String currencyId;
  late String currencySymbol;

  @override
  void initState() {
    super.initState();
    currencyId = context
        .read<AuthBloc>()
        .state
        .authenticate!
        .company!
        .currency!
        .currencyId!;
    currencySymbol = NumberFormat.simpleCurrency(
            locale: Platform.localeName, name: currencyId)
        .currencySymbol;
    _productBloc = context.read<ProductBloc>();
    context
        .read<CategoryBloc>()
        .add(const CategoryFetch(isForDropDown: true, limit: 3));
    classificationId = context.read<String>();
    _nameController.text = widget.product.productName ?? '';
    _idController.text = widget.product.pseudoId;
    _descriptionController.text = widget.product.description ?? '';
    _priceController.text = widget.product.price == null
        ? ''
        : widget.product.price.currency(currencyId: '');
    _listPriceController.text = widget.product.listPrice == null
        ? ''
        : widget.product.listPrice.currency(currencyId: '');
    _assetsController.text = widget.product.assetCount == null
        ? ''
        : widget.product.assetCount.toString();
    _selectedCategories = List.of(widget.product.categories);
    _selectedTypeId = widget.product.productTypeId;
    useWarehouse = widget.product.useWarehouse;
    _productDialogFormKey = GlobalKey<FormState>();
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
    if (classificationId == 'AppHotel') _selectedTypeId = 'Rental';
    return BlocConsumer<ProductBloc, ProductState>(
        listener: (context, state) async {
      switch (state.status) {
        case ProductStatus.success:
          Navigator.of(context).pop();
          break;
        case ProductStatus.failure:
          productDialogKey.currentState!
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
        if (productState.status == ProductStatus.updateLoading ||
            categoryState.status == CategoryStatus.loading) {
          return const LoadingIndicator();
        } else {
          return Dialog(
              key: const Key('ProductDialog'),
              insetPadding: const EdgeInsets.only(left: 20, right: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: popUp(
                  context: context,
                  child: listChild(classificationId, isPhone, categoryState),
                  title: classificationId == 'AppAdmin'
                      ? 'Product Information'
                      : 'Room Type Information',
                  height: classificationId == 'AppAdmin' ? 750 : 600,
                  width: isPhone ? 450 : 800));
        }
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

    List<Widget> widgets = [
      TextFormField(
        key: const Key('id'),
        decoration: InputDecoration(
            labelText:
                classificationId == 'AppHotel' ? 'Room Type Id' : 'Product Id'),
        controller: _idController,
      ),
      TextFormField(
        key: const Key('name'),
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
        key: const Key('description'),
        maxLines: 3,
        decoration: const InputDecoration(labelText: 'Description'),
        controller: _descriptionController,
        validator: (value) {
          return value!.isEmpty ? 'Please enter a description?' : null;
        },
      ),
      Row(
        children: [
          Expanded(
            child: TextFormField(
              key: const Key('listPrice'),
              decoration:
                  InputDecoration(labelText: 'List Price($currencySymbol)'),
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp('[0-9.,]+'))
              ],
              controller: _listPriceController,
              validator: (value) {
                return value!.isEmpty ? 'Please enter a list price?' : null;
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextFormField(
              key: const Key('price'),
              decoration:
                  InputDecoration(labelText: 'Current Price($currencySymbol)'),
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp('[0-9.,]+'))
              ],
              controller: _priceController,
            ),
          )
        ],
      ),
      const SizedBox(height: 10),
      Visibility(
          visible: classificationId != 'AppHotel',
          child: InputDecorator(
              decoration: InputDecoration(
                  labelText: 'Related categories',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25.0),
                  )),
              child: Wrap(spacing: 10.0, children: relCategories))),
      Visibility(
          visible: classificationId != 'AppHotel',
          child: DropdownButtonFormField<String>(
            key: const Key('productTypeDropDown'),
            value: _selectedTypeId,
            decoration: const InputDecoration(labelText: 'Product Type'),
            validator: (value) {
              return value == null ? 'field required' : null;
            },
            items: productTypes.map((item) {
              return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item,
                      style: const TextStyle(color: Color(0xFF4baa9b))));
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _selectedTypeId = newValue!;
              });
            },
            isExpanded: true,
          )),
      if (classificationId != 'AppHotel' && _selectedTypeId != 'Service')
        Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25.0),
              border: Border.all(
                  color: Colors.black45, style: BorderStyle.solid, width: 0.80),
            ),
            child: CheckboxListTile(
                key: const Key('useWarehouse'),
                title: const Text("Use Warehouse?",
                    style: TextStyle(color: Color(0xFF4baa9b))),
                value: useWarehouse,
                onChanged: (bool? value) {
                  setState(() {
                    useWarehouse = value!;
                  });
                })),
      if (classificationId != 'AppHotel' && _selectedTypeId != 'Service')
        TextFormField(
          key: const Key('assets'),
          decoration: const InputDecoration(labelText: 'Assets in warehouse'),
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.allow(RegExp('[0-9.,]+'))
          ],
          controller: _assetsController,
        ),
      Row(children: [
        Expanded(
            child: ElevatedButton(
                key: const Key('update'),
                child: Text(
                    widget.product.productId.isEmpty ? 'Create' : 'Update'),
                onPressed: () async {
                  if (_productDialogFormKey.currentState!.validate()) {
                    Uint8List? image =
                        await HelperFunctions.getResizedImage(_imageFile?.path);
                    if (!mounted) return;
                    if (_imageFile?.path != null && image == null) {
                      HelperFunctions.showMessage(
                          context, "Image upload error!", Colors.red);
                    } else {
                      _productBloc.add(ProductUpdate(Product(
                          productId: widget.product.productId,
                          pseudoId: _idController.text,
                          productName: _nameController.text,
                          assetClassId: classificationId == 'AppHotel'
                              ? 'Hotel Room'
                              : 'AsClsInventoryFin', // finished good
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
                  }
                }))
      ])
    ];

    List<Widget> rows = [];
    if (!ResponsiveBreakpoints.of(context).isMobile) {
      // change list in two columns
      for (var i = 0; i < widgets.length; i++) {
        rows.add(Row(
          children: [
            Expanded(
                child: Padding(
                    padding: const EdgeInsets.all(10), child: widgets[i++])),
            Expanded(
                child: Padding(
                    padding: const EdgeInsets.all(10),
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

    return ScaffoldMessenger(
      key: productDialogKey,
      child: Scaffold(
          backgroundColor: Colors.transparent,
          floatingActionButton:
              ImageButtons(_scrollController, _onImageButtonPressed),
          body: Form(
              key: _productDialogFormKey,
              child: SingleChildScrollView(
                  key: const Key('listView'),
                  controller: _scrollController,
                  child: Column(children: <Widget>[
                    Center(
                        child: Text(
                      'Product #${widget.product.productId.isEmpty ? " New" : widget.product.productId}',
                      style: const TextStyle(
                          color: Colors.black,
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
                      key: const Key('header'),
                    )),
                    const SizedBox(height: 10),
                    CircleAvatar(
                        radius: 60,
                        child: _imageFile != null
                            ? foundation.kIsWeb
                                ? Image.network(_imageFile!.path, scale: 0.3)
                                : Image.file(File(_imageFile!.path), scale: 0.3)
                            : widget.product.image != null
                                ? Image.memory(widget.product.image!,
                                    scale: 0.3)
                                : Text(
                                    widget.product.productName
                                            ?.substring(0, 1) ??
                                        '',
                                    style: const TextStyle(fontSize: 30))),
                    const SizedBox(height: 10),
                    Column(children: (rows.isEmpty ? column : rows)),
                  ])))),
    );
  }
}
