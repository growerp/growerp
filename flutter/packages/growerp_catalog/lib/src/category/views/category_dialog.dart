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

import 'package:universal_io/io.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:growerp_models/growerp_models.dart';

import '../../../growerp_catalog.dart';

class CategoryDialog extends StatefulWidget {
  final Category category;
  const CategoryDialog(this.category, {super.key});
  @override
  CategoryDialogState createState() => CategoryDialogState();
}

class CategoryDialogState extends State<CategoryDialog> {
  final _categoryDialogFormKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _nameController = TextEditingController();
  final _descrController = TextEditingController();
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
  CatalogLocalizations? _localizations;

  @override
  void initState() {
    super.initState();
    classificationId = GlobalConfiguration().get("classificationId");
    _idController.text = widget.category.pseudoId;
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
    _localizations = CatalogLocalizations.of(context);
    return BlocConsumer<CategoryBloc, CategoryState>(
      listenWhen: (previous, current) =>
          current.status == CategoryStatus.failure ||
          (current.status == CategoryStatus.success &&
              current.message != null &&
              current.message!.isNotEmpty),
      listener: (context, state) async {
        switch (state.status) {
          case CategoryStatus.success:
            Navigator.of(context).pop();
            break;
          case CategoryStatus.failure:
            HelperFunctions.showMessage(
              context,
              _localizations!.error(state.message ?? ''),
              Colors.red,
            );
            break;
          default:
        }
      },
      builder: (context, categoryState) {
        return BlocConsumer<ProductBloc, ProductState>(
          listener: (context, state) async {
            switch (state.status) {
              case ProductStatus.failure:
                HelperFunctions.showMessage(
                  context,
                  _localizations!.errorGettingProducts(state.message ?? ''),
                  Colors.red,
                );
                break;
              default:
            }
          },
          builder: (context, productState) {
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
                  title: _localizations!.categoryNumber(
                    widget.category.categoryId.isEmpty
                        ? _localizations!.newItem
                        : widget.category.pseudoId,
                  ),
                  height: 650,
                  width: 350,
                ),
              );
            }
          },
        );
      },
    );
  }

  Widget listChild(ProductState state) {
    return Builder(
      builder: (BuildContext context) {
        return !foundation.kIsWeb &&
                foundation.defaultTargetPlatform == TargetPlatform.android
            ? FutureBuilder<void>(
                future: retrieveLostData(),
                builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
                  if (snapshot.hasError) {
                    return Text(
                      _localizations!.pickImageError(snapshot.error.toString()),
                      textAlign: TextAlign.center,
                    );
                  }
                  return _showForm(state);
                },
              )
            : _showForm(state);
      },
    );
  }

  Text? _getRetrieveErrorWidget() {
    if (_retrieveDataError != null) {
      final Text result = Text(_retrieveDataError!);
      _retrieveDataError = null;
      return result;
    }
    return null;
  }

  Widget _showForm(ProductState state) {
    final Text? retrieveError = _getRetrieveErrorWidget();
    if (retrieveError != null) {
      return retrieveError;
    }
    if (_pickImageError != null) {
      return Text(
        _localizations!.pickImageError(_pickImageError.toString()),
        textAlign: TextAlign.center,
      );
    }

    List<Widget> relProducts = [];
    _selectedProducts.asMap().forEach((index, product) {
      relProducts.add(
        InputChip(
          label: Text(product.productName ?? '', key: Key(product.productId)),
          deleteIcon: const Icon(Icons.cancel, key: Key("deleteChip")),
          onDeleted: () async {
            setState(() {
              _selectedProducts.removeAt(index);
            });
          },
        ),
      );
    });
    relProducts.add(
      IconButton(
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
                title: _localizations!.selectProducts,
                items: state.products,
                selectedItems: _selectedProducts,
              );
            },
          );
          if (result != null) {
            setState(() {
              _selectedProducts = result;
            });
          }
        },
      ),
    );
    return SingleChildScrollView(
      controller: _scrollController,
      key: const Key('listView'),
      child: Form(
        key: _categoryDialogFormKey,
        child: Column(
          children: [
            const SizedBox(height: 10),
            StyledImageUpload(
              label: 'Category Image',
              subtitle: 'Click to upload. JPG, PNG up to 2MB',
              image: _imageFile != null
                  ? (foundation.kIsWeb
                        ? NetworkImage(_imageFile!.path)
                        : FileImage(File(_imageFile!.path)))
                  : null,
              imageBytes: _imageFile == null ? widget.category.image : null,
              fallbackText: widget.category.categoryName.isEmpty
                  ? '?'
                  : widget.category.categoryName.substring(0, 1),
              onUploadTap: () async {
                final pickedFile = await HelperFunctions.pickImage();
                if (pickedFile != null) {
                  setState(() {
                    _imageFile = pickedFile;
                  });
                }
              },
              onRemove: (_imageFile != null || widget.category.image != null)
                  ? () {
                      setState(() {
                        _imageFile = null;
                      });
                    }
                  : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              key: const Key('Id'),
              decoration: InputDecoration(
                labelText: _localizations!.categoryId,
              ),
              controller: _idController,
            ),
            TextFormField(
              key: const Key('name'),
              decoration: InputDecoration(
                labelText: _localizations!.categoryName,
              ),
              controller: _nameController,
              validator: (value) {
                return value!.isEmpty
                    ? _localizations!.enterCategoryName
                    : null;
              },
            ),
            TextFormField(
              key: const Key('description'),
              decoration: InputDecoration(
                labelText: _localizations!.description,
              ),
              controller: _descrController,
              maxLines: 3,
              validator: (value) {
                if (value!.isEmpty) {
                  return _localizations!.enterCategoryDescription;
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            GroupingDecorator(
              labelText:
                  '${_localizations!.relatedProducts}${widget.category.nbrOfProducts > widget.category.products.length ? _localizations!.totalShown(widget.category.nbrOfProducts, widget.category.products.length) : ''}',
              child: Wrap(spacing: 10.0, children: relProducts),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              key: const Key('update'),
              child: Text(
                widget.category.categoryId.isEmpty
                    ? _localizations!.create
                    : _localizations!.update,
              ),
              onPressed: () async {
                if (_categoryDialogFormKey.currentState!.validate()) {
                  _categoryBloc.add(
                    CategoryUpdate(
                      Category(
                        categoryId: widget.category.categoryId,
                        categoryName: _nameController.text,
                        description: _descrController.text,
                        products: _selectedProducts,
                        image: await HelperFunctions.getResizedImage(
                          _imageFile?.path,
                        ),
                      ),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
