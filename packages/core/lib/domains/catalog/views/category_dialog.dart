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

import 'dart:io';
import 'package:core/domains/common/functions/helper_functions.dart';
import 'package:core/templates/@templates.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:image_picker/image_picker.dart';
import 'package:core/domains/domains.dart';
import '../../../api_repository.dart';

final GlobalKey<ScaffoldMessengerState> CategoryDialogKey =
    GlobalKey<ScaffoldMessengerState>();

class CategoryDialog extends StatelessWidget {
  final Category category;
  const CategoryDialog(this.category);
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (BuildContext context) =>
          ProductBloc(context.read<APIRepository>())..add(ProductFetch()),
      child: CategoryDialogFull(category),
    );
  }
}

class CategoryDialogFull extends StatefulWidget {
  final Category category;
  CategoryDialogFull(this.category);
  @override
  _CategoryState createState() => _CategoryState(category);
}

class _CategoryState extends State<CategoryDialogFull> {
  final Category category;
  final _formKey = GlobalKey<FormState>();
  TextEditingController _nameController = TextEditingController();
  TextEditingController _descrController = TextEditingController();
  bool loading = false;
  late Category updatedCategory;
  XFile? _imageFile;
  dynamic _pickImageError;
  String? _retrieveDataError;
  List<Product> _selectedProducts = [];
  late String classificationId;

  final ImagePicker _picker = ImagePicker();

  _CategoryState(this.category);

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
    final response = await _picker.retrieveLostData();
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
  void initState() {
    classificationId = GlobalConfiguration().get("classificationId");
    _nameController..text = category.categoryName;
    _descrController..text = category.description;
    _selectedProducts = List.of(category.products);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CategoryBloc, CategoryState>(
        listener: (context, state) async {
      switch (state.status) {
        case CategoryStatus.success:
          Navigator.of(context).pop();
          break;
        case CategoryStatus.failure:
          CategoryDialogKey.currentState!
              .showSnackBar(snackBar(context, Colors.red, state.message ?? ''));
          break;
        default:
      }
    }, builder: (context, categoryState) {
      return BlocConsumer<ProductBloc, ProductState>(
          listener: (context, state) async {
        switch (state.status) {
          case ProductStatus.failure:
            HelperFunctions.showMessage(context,
                'Error getting products: ${state.message}', Colors.red);
            break;
          default:
        }
      }, builder: (context, productState) {
        return Stack(children: [
          Dialog(
              key: Key('CategoryDialog'),
              insetPadding: EdgeInsets.all(20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(clipBehavior: Clip.none, children: [
                Container(
                    width: 400,
                    height: 650,
                    padding: EdgeInsets.all(20),
                    child: listChild(productState)),
                Container(
                    height: 50,
                    width: 400,
                    decoration: BoxDecoration(
                        color: Theme.of(context).primaryColorDark,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        )),
                    child: Center(
                        child: Text('Category Information',
                            style: TextStyle(
                                fontSize: 20,
                                color: Colors.white,
                                fontWeight: FontWeight.bold)))),
                Positioned(top: 5, right: 5, child: DialogCloseButton()),
              ])),
          if (categoryState.status == CategoryStatus.updateLoading ||
              productState.status == ProductStatus.loading)
            LoadingIndicator(),
        ]);
      });
    });
  }

  Widget listChild(state) {
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
                return _showForm(state);
              })
          : _showForm(state);
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

  Widget _showForm(state) {
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
    return _categoryDialog(state);
  }

  Widget _categoryDialog(state) {
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

    List<Widget> _relProducts = [];
    _selectedProducts.asMap().forEach((index, product) {
      _relProducts.add(InputChip(
          label: Text(
            product.productName ?? '',
            key: Key(product.productId),
          ),
          deleteIcon: const Icon(
            Icons.cancel,
            key: Key("deleteChip"),
          ),
          onDeleted: () async {
            setState(() {
              _selectedProducts.removeAt(index);
            });
          }));
    });
    _relProducts.add(IconButton(
      iconSize: 25,
      icon: Icon(Icons.add_circle),
      color: Colors.deepOrange,
      padding: const EdgeInsets.all(0.0),
      key: Key('addProducts'),
      onPressed: () async {
        var result = await showDialog(
            context: context,
            builder: (BuildContext context) {
              return MultiSelect<Product>(
                title: 'Select one or more products',
                items: state.products,
                selectedItems: _selectedProducts,
              );
            });
        if (result != null) {
          setState(() {
            _selectedProducts = result;
          });
        }
      },
    ));

    return Center(
        child: Container(
            padding: EdgeInsets.all(20),
            child: ScaffoldMessenger(
                key: CategoryDialogKey,
                child: Scaffold(
                    backgroundColor: Colors.transparent,
                    floatingActionButton:
                        imageButtons(context, _onImageButtonPressed),
                    body: Form(
                        key: _formKey,
                        child:
                            ListView(key: Key('listView'), children: <Widget>[
                          SizedBox(height: 10),
                          Center(
                              child: Text(
                            'Category #${category.categoryId.isEmpty ? " New" : category.categoryId}',
                            style: TextStyle(
                                fontSize: 10,
                                color: Colors.black,
                                fontWeight: FontWeight.bold),
                            key: Key('header'),
                          )),
                          SizedBox(height: 30),
                          CircleAvatar(
                              backgroundColor: Colors.green,
                              radius: 80,
                              child: _imageFile != null
                                  ? foundation.kIsWeb
                                      ? Image.network(_imageFile!.path,
                                          scale: 0.3)
                                      : Image.file(File(_imageFile!.path),
                                          scale: 0.3)
                                  : category.image != null
                                      ? Image.memory(category.image!,
                                          scale: 0.3)
                                      : Text(
                                          category.categoryName.isEmpty
                                              ? '?'
                                              : category.categoryName
                                                  .substring(0, 1),
                                          style: TextStyle(
                                              fontSize: 30,
                                              color: Colors.black))),
                          SizedBox(height: 30),
                          TextFormField(
                            key: Key('name'),
                            decoration:
                                InputDecoration(labelText: 'Category Name'),
                            controller: _nameController,
                            validator: (value) {
                              return value!.isEmpty
                                  ? 'Please enter a category name?'
                                  : null;
                            },
                          ),
                          SizedBox(height: 10),
                          TextFormField(
                            key: Key('description'),
                            decoration:
                                InputDecoration(labelText: 'Description'),
                            controller: _descrController,
                            maxLines: 3,
                            validator: (value) {
                              if (value!.isEmpty)
                                return 'Please enter a category description?';
                              return null;
                            },
                          ),
                          SizedBox(height: 10),
                          Container(
                              child: InputDecorator(
                                  decoration: InputDecoration(
                                      labelText: 'Related Products' +
                                          (category.nbrOfProducts >
                                                  category.products.length
                                              ? ' total: '
                                                  '${category.nbrOfProducts}, '
                                                  'shown first ${category.products.length}'
                                              : ''),
                                      border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(25.0),
                                      )),
                                  child: Wrap(
                                      spacing: 10.0, children: _relProducts))),
                          SizedBox(height: 10),
                          ElevatedButton(
                              key: Key('update'),
                              child: Text(category.categoryId.isEmpty
                                  ? 'Create'
                                  : 'Update'),
                              onPressed: () async {
                                if (_formKey.currentState!.validate()) {
                                  updatedCategory = Category(
                                      categoryId: category.categoryId,
                                      categoryName: _nameController.text,
                                      description: _descrController.text,
                                      products: _selectedProducts,
                                      image:
                                          await HelperFunctions.getResizedImage(
                                              _imageFile?.path));
                                  if (_imageFile?.path != null &&
                                      updatedCategory.image == null)
                                    HelperFunctions.showMessage(context,
                                        "Image upload error!", Colors.red);
                                  else
                                    context
                                        .read<CategoryBloc>()
                                        .add(CategoryUpdate(
                                          updatedCategory,
                                        ));
                                }
                              }),
                        ]))))));
  }
}
