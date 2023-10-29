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
import 'package:growerp_core/growerp_core.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:image_picker/image_picker.dart';
import 'package:growerp_models/growerp_models.dart';

class CategoryDialog extends StatelessWidget {
  final Category category;
  const CategoryDialog(this.category, {super.key});
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (BuildContext context) => ProductBloc(CatalogAPIRepository(
          context.read<AuthBloc>().state.authenticate!.apiKey!))
        ..add(const ProductFetch()),
      child: CategoryDialogFull(category),
    );
  }
}

class CategoryDialogFull extends StatefulWidget {
  final Category category;
  const CategoryDialogFull(this.category, {super.key});
  @override
  CategoryDialogState createState() => CategoryDialogState();
}

class CategoryDialogState extends State<CategoryDialogFull> {
  final _categoryDialogFormKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descrController = TextEditingController();
  bool loading = false;
  late Category updatedCategory;
  XFile? _imageFile;
  dynamic _pickImageError;
  String? _retrieveDataError;
  List<Product> _selectedProducts = [];
  late String classificationId;
  late CategoryBloc _categoryBloc;
  final ImagePicker _picker = ImagePicker();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    classificationId = GlobalConfiguration().get("classificationId");
    _nameController.text = widget.category.categoryName;
    _descrController.text = widget.category.description;
    _selectedProducts = List.of(widget.category.products);
    _categoryBloc = context.read<CategoryBloc>();
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
  Widget build(BuildContext context) {
    return BlocConsumer<CategoryBloc, CategoryState>(
        listener: (context, state) async {
      switch (state.status) {
        case CategoryStatus.success:
          Navigator.of(context).pop();
          break;
        case CategoryStatus.failure:
          HelperFunctions.showMessage(
              context, 'Error: ${state.message}', Colors.red);
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
        if (productState.status == ProductStatus.loading ||
            categoryState.status == CategoryStatus.loading) {
          return const LoadingIndicator();
        } else {
          return Dialog(
              key: const Key('CategoryDialog'),
              insetPadding: const EdgeInsets.all(20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: popUp(
                  context: context,
                  child: listChild(productState),
                  title: 'Category Information',
                  height: 650,
                  width: 350));
        }
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

    List<Widget> relProducts = [];
    _selectedProducts.asMap().forEach((index, product) {
      relProducts.add(InputChip(
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
    relProducts.add(IconButton(
      iconSize: 25,
      icon: const Icon(Icons.add_circle),
      color: Colors.deepOrange,
      padding: const EdgeInsets.all(0.0),
      key: const Key('addProducts'),
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

    return ScaffoldMessenger(
        child: Scaffold(
            backgroundColor: Colors.transparent,
            floatingActionButton:
                ImageButtons(_scrollController, _onImageButtonPressed),
            body: Form(
                key: _categoryDialogFormKey,
                child: SingleChildScrollView(
                    controller: _scrollController,
                    key: const Key('listView'),
                    child: Column(children: [
                      Center(
                          child: Text(
                        'Category #${widget.category.categoryId.isEmpty ? " New" : widget.category.categoryId}',
                        style: const TextStyle(
                            fontSize: 10,
                            color: Colors.black,
                            fontWeight: FontWeight.bold),
                        key: const Key('header'),
                      )),
                      const SizedBox(height: 30),
                      CircleAvatar(
                          backgroundColor: Colors.green,
                          radius: 70,
                          child: _imageFile != null
                              ? foundation.kIsWeb
                                  ? Image.network(_imageFile!.path, scale: 0.3)
                                  : Image.file(File(_imageFile!.path),
                                      scale: 0.3)
                              : widget.category.image != null
                                  ? Image.memory(widget.category.image!,
                                      scale: 0.3)
                                  : Text(
                                      widget.category.categoryName.isEmpty
                                          ? '?'
                                          : widget.category.categoryName
                                              .substring(0, 1),
                                      style: const TextStyle(
                                          fontSize: 30, color: Colors.black))),
                      const SizedBox(height: 10),
                      TextFormField(
                        key: const Key('name'),
                        decoration:
                            const InputDecoration(labelText: 'Category Name'),
                        controller: _nameController,
                        validator: (value) {
                          return value!.isEmpty
                              ? 'Please enter a category name?'
                              : null;
                        },
                      ),
                      TextFormField(
                        key: const Key('description'),
                        decoration:
                            const InputDecoration(labelText: 'Description'),
                        controller: _descrController,
                        maxLines: 3,
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Please enter a category description?';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      InputDecorator(
                          decoration: InputDecoration(
                              labelText:
                                  'Related Products${widget.category.nbrOfProducts > widget.category.products.length ? ' total: '
                                      '${widget.category.nbrOfProducts}, '
                                      'shown first ${widget.category.products.length}' : ''}',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25.0),
                              )),
                          child: Wrap(spacing: 10.0, children: relProducts)),
                      const SizedBox(height: 10),
                      ElevatedButton(
                          key: const Key('update'),
                          child: Text(widget.category.categoryId.isEmpty
                              ? 'Create'
                              : 'Update'),
                          onPressed: () async {
                            if (_categoryDialogFormKey.currentState!
                                .validate()) {
                              _categoryBloc.add(CategoryUpdate(Category(
                                  categoryId: widget.category.categoryId,
                                  categoryName: _nameController.text,
                                  description: _descrController.text,
                                  products: _selectedProducts,
                                  image: await HelperFunctions.getResizedImage(
                                      _imageFile?.path))));
                            }
                          }),
                    ])))));
  }
}
