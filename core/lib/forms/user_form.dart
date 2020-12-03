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
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:models/models.dart';
import '../blocs/@blocs.dart';
import '../helper_functions.dart';
import '../routing_constants.dart';
import '../widgets/@widgets.dart';
import 'package:responsive_framework/responsive_framework.dart';

class UserForm extends StatelessWidget {
  final FormArguments formArguments;
  UserForm(this.formArguments);

  @override
  Widget build(BuildContext context) {
    var a = (formArguments) =>
        (MyUserPage(formArguments.message, formArguments.object));
    return ShowNavigationRail(a(formArguments), 0);
  }
}

class MyUserPage extends StatefulWidget {
  final String message;
  final User user;
  MyUserPage(this.message, this.user);
  @override
  _MyUserState createState() => _MyUserState(message, user);
}

class _MyUserState extends State<MyUserPage> {
  final String message;
  final User user;
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  User updatedUser;
  bool loading = false;
  UserGroup _selectedUserGroup;
  PickedFile _imageFile;
  dynamic _pickImageError;
  String _retrieveDataError;
  final ImagePicker _picker = ImagePicker();
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
  _MyUserState([this.message, this.user]) {
    HelperFunctions.showTopMessage(scaffoldMessengerKey, message);
  }

  void _onImageButtonPressed(ImageSource source, {BuildContext context}) async {
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
      _retrieveDataError = response.exception.code;
    }
  }

  @override
  Widget build(BuildContext context) {
    Authenticate authenticate;
    return BlocBuilder<AuthBloc, AuthState>(builder: (context, state) {
      if (state is AuthAuthenticated) authenticate = state.authenticate;
      return ScaffoldMessenger(
          key: scaffoldMessengerKey,
          child: Scaffold(
              appBar: AppBar(
                automaticallyImplyLeading:
                    ResponsiveWrapper.of(context).isSmallerThan(TABLET),
                title: companyLogo(context, authenticate, 'User detail'),
                actions: <Widget>[
                  IconButton(
                      icon: Icon(Icons.home),
                      onPressed: () => Navigator.pushNamed(context, HomeRoute))
                ],
              ),
              floatingActionButton: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  SizedBox(height: 100),
                  FloatingActionButton(
                    onPressed: () {
                      _onImageButtonPressed(ImageSource.gallery,
                          context: context);
                    },
                    heroTag: 'image0',
                    tooltip: 'Pick Image from gallery',
                    child: const Icon(Icons.photo_library),
                  ),
                  SizedBox(height: 20),
                  FloatingActionButton(
                    onPressed: () {
                      _onImageButtonPressed(ImageSource.camera,
                          context: context);
                    },
                    heroTag: 'image1',
                    tooltip: 'Take a Photo',
                    child: const Icon(Icons.camera_alt),
                  ),
                ],
              ),
              drawer: myDrawer(context, authenticate),
              body: BlocListener<AuthBloc, AuthState>(
                listener: (context, state) {
                  if (state is AuthProblem) {
                    loading = false;
                    HelperFunctions.showMessage(
                        context, '${state.errorMessage}', Colors.red);
                  }
                  if (state is AuthLoading) {
                    loading = true;
                    HelperFunctions.showMessage(
                        context, '${state.message}', Colors.green);
                  }
                  if (state is AuthAuthenticated) {
                    Navigator.pushNamed(context, UsersRoute,
                        arguments: FormArguments(state.message));
                  }
                },
                child: Center(
                  child:
                      !kIsWeb && defaultTargetPlatform == TargetPlatform.android
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
                                return _showForm(authenticate, updatedUser);
                              })
                          : _showForm(authenticate, updatedUser),
                ),
              )));
    }
//      return Container(child: Text("needs logging in"));
        );
  }

  Text _getRetrieveErrorWidget() {
    if (_retrieveDataError != null) {
      final Text result = Text(_retrieveDataError);
      _retrieveDataError = null;
      return result;
    }
    return null;
  }

  Widget _showForm(authenticate, updatedUser) {
    _firstNameController..text = user?.firstName;
    _lastNameController..text = user?.lastName;
    _nameController..text = user?.name;
    _emailController..text = user?.email;
    final Text retrieveError = _getRetrieveErrorWidget();
    if (_selectedUserGroup == null && user?.userGroupId != null)
      _selectedUserGroup =
          userGroups.firstWhere((a) => a.userGroupId == user?.userGroupId);
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
            width: 400,
            child: Form(
                key: _formKey,
                child: ListView(children: <Widget>[
                  SizedBox(height: 30),
                  GestureDetector(
                    onTap: () async {
                      PickedFile pickedFile =
                          await _picker.getImage(source: ImageSource.gallery);
                      BlocProvider.of<AuthBloc>(context)
                          .add(UploadImage(user.partyId, pickedFile.path));
                    },
                    child: CircleAvatar(
                        backgroundColor: Colors.green,
                        radius: 80,
                        child: _imageFile != null
                            ? kIsWeb
                                ? Image.network(_imageFile.path)
                                : Image.file(File(_imageFile.path))
                            : user?.image != null
                                ? Image.memory(user?.image)
                                : Text(user?.firstName?.substring(0, 1) ?? '',
                                    style: TextStyle(
                                        fontSize: 30, color: Colors.black))),
                  ),
                  SizedBox(height: 30),
                  TextFormField(
                    key: Key('firstName'),
                    decoration: InputDecoration(labelText: 'First Name'),
                    controller: _firstNameController,
                    validator: (value) {
                      if (value.isEmpty) return 'Please enter your first name?';
                      return null;
                    },
                  ),
                  SizedBox(height: 20),
                  TextFormField(
                    key: Key('lastName'),
                    decoration: InputDecoration(labelText: 'Last Name'),
                    controller: _lastNameController,
                    validator: (value) {
                      if (value.isEmpty) return 'Please enter your last name?';
                      return null;
                    },
                  ),
                  SizedBox(height: 20),
                  TextFormField(
                    key: Key('name'),
                    decoration: InputDecoration(labelText: 'User Login Name'),
                    controller: _nameController,
                    validator: (value) {
                      if (value.isEmpty) return 'Please enter a login name?';
                      return null;
                    },
                  ),
                  SizedBox(height: 10),
                  TextFormField(
                    key: Key('email'),
                    decoration: InputDecoration(labelText: 'Email address'),
                    controller: _emailController,
                    validator: (String value) {
                      if (value.isEmpty) return 'Please enter Email address?';
                      if (!RegExp(
                              r"[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?")
                          .hasMatch(value)) {
                        return 'This is not a valid email';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 10),
                  DropdownButtonFormField<UserGroup>(
                    key: Key('dropDown'),
                    hint: Text('User Group'),
                    value: _selectedUserGroup,
                    validator: (value) =>
                        value == null ? 'field required' : null,
                    items: userGroups?.map((item) {
                      return DropdownMenuItem<UserGroup>(
                          child: Text(item.description), value: item);
                    })?.toList(),
                    onChanged: (UserGroup newValue) {
                      setState(() {
                        _selectedUserGroup = newValue;
                      });
                    },
                    isExpanded: true,
                  ),
                  SizedBox(height: 20),
                  RaisedButton(
                      disabledColor: Colors.grey,
                      key: Key('update'),
                      child: Text(user?.partyId == null ? 'Create' : 'Update'),
                      onPressed: () {
                        if (_formKey.currentState.validate() && !loading) {
                          updatedUser = User(
                            partyId: user?.partyId,
                            firstName: _firstNameController.text,
                            lastName: _lastNameController.text,
                            email: _emailController.text,
                            name: _nameController.text,
                            userGroupId: _selectedUserGroup.userGroupId,
                            language: Localizations.localeOf(context)
                                .languageCode
                                .toString(),
                            country: Localizations.localeOf(context)
                                .languageCode
                                .toString(),
                          );
                          BlocProvider.of<AuthBloc>(context).add(UpdateEmployee(
                            updatedUser,
                            _imageFile?.path,
                          ));
                        }
                      })
                ]))));
  }
}
