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
import 'package:models/@models.dart';
import 'package:core/blocs/@blocs.dart';
import 'package:core/helper_functions.dart';
import 'package:core/templates/@templates.dart';

class UserDialog extends StatelessWidget {
  final FormArguments formArguments;
  const UserDialog({Key? key, required this.formArguments}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return UserPage(formArguments.message, formArguments.object as User);
  }
}

class UserPage extends StatefulWidget {
  final String? message;
  final User user;
  UserPage(this.message, this.user);
  @override
  _UserState createState() => _UserState(message, user);
}

class _UserState extends State<UserPage> {
  final String? message;
  final User user;
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _companyController = TextEditingController();

  User? updatedUser;
  bool loading = false;
  UserGroup? _selectedUserGroup;
  PickedFile? _imageFile;
  dynamic _pickImageError;
  String? _retrieveDataError;
  final ImagePicker _picker = ImagePicker();
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  _UserState(this.message, this.user);

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
    User? user = widget.user;
    Authenticate? authenticate;
    updatedUser = widget.user;
    return Dialog(
        insetPadding: EdgeInsets.all(10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
            padding: EdgeInsets.all(20),
            width: 400,
            height: 700,
            child: BlocBuilder<AuthBloc, AuthState>(builder: (context, state) {
              if (state is AuthAuthenticated) authenticate = state.authenticate;
              return ScaffoldMessenger(
                  key: scaffoldMessengerKey,
                  child: Scaffold(
                      floatingActionButton:
                          imageButtons(context, _onImageButtonPressed),
                      body: user.userGroupId == "GROWERP_M_EMPLOYEE"
                          ? BlocListener<EmployeeBloc, UserState>(
                              listener: (context, state) {
                                listListener(state);
                              },
                              child: listChild(authenticate))
                          : user.userGroupId == "GROWERP_M_ADMIN"
                              ? BlocListener<AdminBloc, UserState>(
                                  listener: (context, state) {
                                    listListener(state);
                                  },
                                  child: listChild(authenticate))
                              : user.userGroupId == "GROWERP_M_SUPPLIER"
                                  ? BlocListener<SupplierBloc, UserState>(
                                      listener: (context, state) {
                                        listListener(state);
                                      },
                                      child: listChild(authenticate))
                                  : user.userGroupId == "GROWERP_M_LEAD"
                                      ? BlocListener<LeadBloc, UserState>(
                                          listener: (context, state) {
                                            listListener(state);
                                          },
                                          child: listChild(authenticate))
                                      : BlocListener<CustomerBloc, UserState>(
                                          listener: (context, state) {
                                            listListener(state);
                                          },
                                          child: listChild(authenticate))));
            })));
  }

  Widget listChild(authenticate) {
    return Center(child: Builder(builder: (BuildContext context) {
      return Center(
        child: !kIsWeb && defaultTargetPlatform == TargetPlatform.android
            ? FutureBuilder<void>(
                future: retrieveLostData(),
                builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
                  if (snapshot.hasError) {
                    return Text(
                      'Pick image error: ${snapshot.error}}',
                      textAlign: TextAlign.center,
                    );
                  }
                  return _showForm(authenticate, updatedUser);
                })
            : _showForm(authenticate, updatedUser),
      );
    }));
  }

  listListener(state) {
    if (state is UserProblem) {
      loading = false;
      HelperFunctions.showMessage(context, '${state.errorMessage}', Colors.red);
    }
    if (state is UserLoading) {
      loading = true;
      HelperFunctions.showMessage(context, '${state.message}', Colors.green);
    }
    if (state is UserSuccess) {
      Navigator.of(context).pop();
    }
  }

  Text? _getRetrieveErrorWidget() {
    if (_retrieveDataError != null) {
      final Text result = Text(_retrieveDataError!);
      _retrieveDataError = null;
      return result;
    }
    return null;
  }

  Widget _showForm(authenticate, updatedUser) {
    User? user = widget.user;
    if (user != null) {
      _firstNameController.text = user.firstName ?? '';
      _lastNameController.text = user.lastName ?? '';
      _nameController.text = user.name ?? '';
      _emailController.text = user.email ?? '';
      _companyController.text = user.companyName ?? '';
      if (_selectedUserGroup == null && user.userGroupId != null)
        _selectedUserGroup =
            userGroups.firstWhere((a) => a.userGroupId == user.userGroupId);
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
    return _UserDialog(widget.user, updatedUser);
  }

  Widget _UserDialog(user, updatedUser) {
    return Form(
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
                  : user!.image != null
                      ? Image.memory(user.image!, height: 150)
                      : Text(user.firstName?.substring(0, 1) ?? '',
                          style: TextStyle(fontSize: 30, color: Colors.black))),
          SizedBox(height: 20),
          TextFormField(
            key: Key('firstName'),
            decoration: InputDecoration(labelText: 'First Name'),
            controller: _firstNameController,
            validator: (value) {
              if (value!.isEmpty) return 'Please enter a first name?';
              return null;
            },
          ),
          SizedBox(height: 10),
          TextFormField(
            key: Key('lastName'),
            decoration: InputDecoration(labelText: 'Last Name'),
            controller: _lastNameController,
            validator: (value) {
              if (value!.isEmpty) return 'Please enter a last name?';
              return null;
            },
          ),
          SizedBox(height: 10),
          TextFormField(
            key: Key('name'),
            decoration: InputDecoration(labelText: 'User Login Name'),
            controller: _nameController,
            validator: (value) {
              if (value!.isEmpty) return 'Please enter a login name?';
              return null;
            },
          ),
          SizedBox(height: 10),
          TextFormField(
            key: Key('email'),
            decoration: InputDecoration(labelText: 'Email address'),
            controller: _emailController,
            validator: (String? value) {
              if (value!.isEmpty) return 'Please enter Email address?';
              if (!RegExp(
                      r"[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?")
                  .hasMatch(value)) {
                return 'This is not a valid email';
              }
              return null;
            },
          ),
          SizedBox(height: 10),
          Visibility(
              visible: user!.userGroupId == null,
              child: DropdownButtonFormField<UserGroup>(
                key: Key('dropDown'),
                hint: Text('User Group'),
                value: _selectedUserGroup,
                validator: (value) => value == null ? 'field required' : null,
                items: userGroups.map((item) {
                  return DropdownMenuItem<UserGroup>(
                      child: Text(item.description!), value: item);
                }).toList(),
                onChanged: (UserGroup? newValue) {
                  setState(() {
                    _selectedUserGroup = newValue;
                  });
                },
                isExpanded: true,
              )),
          SizedBox(height: 10),
          Visibility(
              visible: user.userGroupId != 'GROWERP_M_ADMIN' &&
                  user.userGroupId != 'GROWERP_M_EMPLOYEE',
              child: TextFormField(
                key: Key('companyName'),
                decoration: InputDecoration(labelText: 'Company Name'),
                controller: _companyController,
                validator: (value) {
                  if (value!.isEmpty) return 'Please enter a company name?';
                  return null;
                },
              )),
          SizedBox(height: 10),
          ElevatedButton(
              key: Key('update'),
              child: Text(user.partyId == null ? 'Create' : 'Update'),
              onPressed: () async {
                if (_formKey.currentState!.validate() && !loading) {
                  updatedUser = User(
                      partyId: user.partyId,
                      firstName: _firstNameController.text,
                      lastName: _lastNameController.text,
                      email: _emailController.text,
                      name: _nameController.text,
                      userGroupId: _selectedUserGroup!.userGroupId,
                      language: Localizations.localeOf(context)
                          .languageCode
                          .toString(),
                      companyPartyId: user.companyPartyId,
                      companyName: _companyController.text,
                      image: await HelperFunctions.getResizedImage(
                          _imageFile?.path));
                  user.userGroupId == "GROWERP_M_EMPLOYEE"
                      ? BlocProvider.of<EmployeeBloc>(context).add(UpdateUser(
                          updatedUser,
                        ))
                      : user.userGroupId == "GROWERP_M_ADMIN"
                          ? BlocProvider.of<AdminBloc>(context).add(UpdateUser(
                              updatedUser,
                            ))
                          : user.userGroupId == "GROWERP_M_SUPPLIER"
                              ? BlocProvider.of<SupplierBloc>(context)
                                  .add(UpdateUser(
                                  updatedUser,
                                ))
                              : user.userGroupId == "GROWERP_M_LEAD"
                                  ? BlocProvider.of<LeadBloc>(context)
                                      .add(UpdateUser(
                                      updatedUser,
                                    ))
                                  : BlocProvider.of<CustomerBloc>(context)
                                      .add(UpdateUser(
                                      updatedUser,
                                    ));
                }
              }),
          SizedBox(height: 10),
          ElevatedButton(
              key: Key('cancel'),
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              })
        ]));
  }
}
