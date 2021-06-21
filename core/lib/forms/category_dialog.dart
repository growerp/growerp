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
import 'package:core/templates/@templates.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:models/@models.dart';
import 'package:core/blocs/@blocs.dart';
import 'package:core/helper_functions.dart';

class CategoryDialog extends StatelessWidget {
  final FormArguments formArguments;
  const CategoryDialog({Key? key, required this.formArguments})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CategoryPage(
        formArguments.message, formArguments.object as ProductCategory);
  }
}

class CategoryPage extends StatefulWidget {
  final String? message;
  final ProductCategory? category;
  CategoryPage(this.message, this.category);
  @override
  _CategoryState createState() => _CategoryState(message, category);
}

class _CategoryState extends State<CategoryPage> {
  final message;
  final category;
  final _formKey = GlobalKey<FormState>();
  TextEditingController _nameController = TextEditingController();
  TextEditingController _descrController = TextEditingController();

  bool loading = false;
  late ProductCategory updatedCategory;
  PickedFile? _imageFile;
  dynamic _pickImageError;
  String? _retrieveDataError;

  final ImagePicker _picker = ImagePicker();
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
  _CategoryState(this.message, this.category) {
    HelperFunctions.showTopMessage(scaffoldMessengerKey, message);
  }

  void _onImageButtonPressed(ImageSource source,
      {BuildContext? context}) async {
    try {
      final pickedFile = await _picker.getImage(
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
    final LostData response = await _picker.getLostData();
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
        listener: (context, state) {
      if (state is CategoryProblem) {
        loading = false;
        HelperFunctions.showMessage(
            context, '${state.errorMessage}', Colors.red);
      }
      if (state is CategorySuccess) {
        HelperFunctions.showMessage(context, '${state.message}', Colors.green);
        Navigator.of(context).pop();
      }
    }, builder: (BuildContext context, state) {
      if (state is CategoryLoading) return Container();
      return GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: ScaffoldMessenger(
              key: scaffoldMessengerKey,
              child: GestureDetector(
                  onTap: () {},
                  child: Dialog(
                      key: Key('CategoryDialog'),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Container(
                          padding: EdgeInsets.all(20),
                          width: 400,
                          height: 600,
                          child: Scaffold(
                              backgroundColor: Colors.transparent,
                              floatingActionButton:
                                  imageButtons(context, _onImageButtonPressed),
                              body: Builder(
                                builder: (context) => !kIsWeb &&
                                        defaultTargetPlatform ==
                                            TargetPlatform.android
                                    ? FutureBuilder<void>(
                                        future: retrieveLostData(),
                                        builder: (BuildContext context,
                                            AsyncSnapshot<void> snapshot) {
                                          if (snapshot.hasError) {
                                            return Text(
                                              'Pick image error: ${snapshot.error}}',
                                              textAlign: TextAlign.center,
                                            );
                                          }
                                          return _showForm();
                                        })
                                    : _showForm(),
                              )))))));
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

  Widget _showForm() {
    if (category != null) {
      _nameController..text = category?.categoryName ?? '';
      _descrController..text = category?.description ?? '';
    }
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
    return Center(
        child: Container(
            child: Form(
                key: _formKey,
                child: ListView(children: <Widget>[
                  SizedBox(height: 30),
                  CircleAvatar(
                      backgroundColor: Colors.green,
                      radius: 80,
                      child: _imageFile != null
                          ? kIsWeb
                              ? Image.network(_imageFile!.path)
                              : Image.file(File(_imageFile!.path))
                          : category?.image != null
                              ? Image.memory(category?.image)
                              : Text(
                                  category?.categoryName?.substring(0, 1) ?? '',
                                  style: TextStyle(
                                      fontSize: 30, color: Colors.black))),
                  SizedBox(height: 30),
                  TextFormField(
                    key: Key('name'),
                    decoration: InputDecoration(labelText: 'Category Name'),
                    controller: _nameController,
                    validator: (value) {
                      if (value!.isEmpty)
                        return 'Please enter a category name?';
                      return null;
                    },
                  ),
                  SizedBox(height: 30),
                  TextFormField(
                    key: Key('descr'),
                    decoration: InputDecoration(labelText: 'Description'),
                    controller: _descrController,
                    maxLines: 5,
                    validator: (value) {
                      if (value!.isEmpty)
                        return 'Please enter a category description?';
                      return null;
                    },
                  ),
                  SizedBox(height: 20),
                  Row(children: [
                    ElevatedButton(
                        key: Key('cancel'),
                        child: Text('Cancel'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        }),
                    SizedBox(width: 20),
                    Expanded(
                        child: ElevatedButton(
                            key: Key('update'),
                            child: Text(category?.categoryId == null
                                ? 'Create'
                                : 'Update'),
                            onPressed: () async {
                              if (_formKey.currentState!.validate() &&
                                  !loading) {
                                updatedCategory = ProductCategory(
                                    categoryId: category?.categoryId,
                                    categoryName: _nameController.text,
                                    description: _descrController.text,
                                    image:
                                        await HelperFunctions.getResizedImage(
                                            _imageFile?.path));
                                if (_imageFile?.path != null &&
                                    updatedCategory.image == null)
                                  HelperFunctions.showMessage(
                                      context,
                                      "Image upload error or larger than 50K",
                                      Colors.red);
                                else
                                  BlocProvider.of<CategoryBloc>(context)
                                      .add(UpdateCategory(
                                    updatedCategory,
                                  ));
                              }
                            })),
                  ])
                ]))));
  }
}
