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
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:models/@models.dart';
import 'package:core/blocs/@blocs.dart';
import 'package:core/helper_functions.dart';
import 'package:core/templates/@templates.dart';
import 'package:responsive_framework/responsive_wrapper.dart';

import '@forms.dart';

class UserDialog extends StatelessWidget {
  final FormArguments formArguments;
  const UserDialog({Key? key, required this.formArguments}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print(">>>NavigateTo { UserDialog $formArguments");
    return UserPage(formArguments.message, formArguments.object as User);
  }
}

class UserPage extends StatefulWidget {
  final String? message;
  final User user;
  UserPage(this.message, this.user);
  @override
  _UserState createState() => _UserState();
}

class _UserState extends State<UserPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _companyController = TextEditingController();
  final _companySearchBoxController = TextEditingController();

  bool loading = false;
  UserGroup? _selectedUserGroup;
  Company? _selectedCompany;
  PickedFile? _imageFile;
  dynamic _pickImageError;
  String? _retrieveDataError;
  late User updatedUser;
  final ImagePicker _picker = ImagePicker();
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
  late bool isPhone;

  @override
  void initState() {
    super.initState();
    _firstNameController.text = widget.user.firstName ?? '';
    _lastNameController.text = widget.user.lastName ?? '';
    _nameController.text = widget.user.loginName ?? '';
    _emailController.text = widget.user.email ?? '';
    _companyController.text = widget.user.companyName ?? '';
    if (widget.user.userGroupId != null)
      _selectedUserGroup = userGroups
          .firstWhere((a) => a.userGroupId == widget.user.userGroupId);
    updatedUser = widget.user.copyWith();
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
    isPhone = ResponsiveWrapper.of(context).isSmallerThan(TABLET);
    var repos = context.read<Object>();
    User? user = widget.user;
    Authenticate? authenticate;
    return Dialog(
        key: Key('${user.groupDescription}UserDialog'),
        insetPadding: EdgeInsets.all(10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
            padding: EdgeInsets.all(20),
            width: 400,
            height: 750,
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
                              child: listChild(authenticate, repos))
                          : user.userGroupId == "GROWERP_M_ADMIN"
                              ? BlocListener<AdminBloc, UserState>(
                                  listener: (context, state) {
                                    listListener(state);
                                  },
                                  child: listChild(authenticate, repos))
                              : user.userGroupId == "GROWERP_M_SUPPLIER"
                                  ? BlocListener<SupplierBloc, UserState>(
                                      listener: (context, state) {
                                        listListener(state);
                                      },
                                      child: listChild(authenticate, repos))
                                  : user.userGroupId == "GROWERP_M_LEAD"
                                      ? BlocListener<LeadBloc, UserState>(
                                          listener: (context, state) {
                                            listListener(state);
                                          },
                                          child: listChild(authenticate, repos))
                                      : BlocListener<CustomerBloc, UserState>(
                                          listener: (context, state) {
                                            listListener(state);
                                          },
                                          child:
                                              listChild(authenticate, repos))));
            })));
  }

  Widget listChild(authenticate, repos) {
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
                  return _showForm(authenticate, repos);
                })
            : _showForm(authenticate, repos),
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
      Navigator.of(context).pop(updatedUser);
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

  Widget _showForm(authenticate, repos) {
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
    return _userDialog(repos, authenticate.company.name);
  }

  Widget _userDialog(repos, String companyName) {
    Future<List<Company>> getOwnedCompanies(filter) async {
      var response =
          await repos.getCompanies(filter: _companySearchBoxController.text);
      return response;
    }

    return Form(
        key: _formKey,
        child: ListView(children: <Widget>[
          Center(
              child: Text(
                  'User ${widget.user.groupDescription} #${updatedUser.partyId ?? " New"}',
                  style: TextStyle(
                      fontSize: isPhone ? 10 : 20,
                      color: Colors.black,
                      fontWeight: FontWeight.bold))),
          Visibility(
              visible: updatedUser.userGroupId == 'GROWERP_M_ADMIN' ||
                  updatedUser.userGroupId == 'GROWERP_M_EMPLOYEE',
              child: Center(child: Text(companyName))),
          SizedBox(height: 30),
          CircleAvatar(
              backgroundColor: Colors.green,
              radius: 80,
              child: _imageFile != null
                  ? kIsWeb
                      ? Image.network(_imageFile!.path)
                      : Image.file(File(_imageFile!.path))
                  : widget.user.image != null
                      ? Image.memory(widget.user.image!, height: 150)
                      : Text(widget.user.firstName?.substring(0, 1) ?? '',
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
          Visibility(
              visible:
                  !widget.user.loginDisabled || widget.user.loginName == null,
              child: TextFormField(
                key: Key('name'),
                decoration: InputDecoration(
                    labelText: 'User Login Name '
                        '${widget.user.userGroupId == "GROWERP_M_ADMIN" ? "" : "(Empty: none)"}'),
                controller: _nameController,
                validator: (value) {
                  if (widget.user.userGroupId == "GROWERP_M_ADMIN" &&
                      value!.isEmpty)
                    return 'An administrator needs a userlogin!';
                  return null;
                },
              )),
          SizedBox(height: 10),
          Visibility(
              visible: widget.user.email == null ||
                  !widget.user.email!.contains('example.com'),
              child: TextFormField(
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
              )),
          SizedBox(height: 10),
          Visibility(
              visible: updatedUser.userGroupId == 'GROWERP_M_ADMIN',
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
              visible: updatedUser.userGroupId != 'GROWERP_M_ADMIN' &&
                  updatedUser.userGroupId != 'GROWERP_M_EMPLOYEE',
              child: Column(children: [
                TextFormField(
                  key: Key('newCompanyName'),
                  decoration: InputDecoration(labelText: 'New Company Name'),
                  controller: _companyController,
                  validator: (value) {
                    if (value!.isEmpty && _selectedCompany == null)
                      return 'Please enter an existing or new company?';
                    return null;
                  },
                ),
                SizedBox(height: 10),
                DropdownSearch<Company>(
                  label: 'Existing Company',
                  dialogMaxWidth: 300,
                  autoFocusSearchBox: true,
                  selectedItem: _selectedCompany,
                  dropdownSearchDecoration: InputDecoration(
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25.0)),
                  ),
                  searchBoxDecoration: InputDecoration(
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25.0)),
                  ),
                  showSearchBox: true,
                  searchBoxController: _companySearchBoxController,
                  isFilteredOnline: true,
                  key: Key('dropCompany'),
                  itemAsString: (Company? u) => "${u!.name}",
                  onFind: (String filter) =>
                      getOwnedCompanies(_companySearchBoxController.text),
                  onChanged: (Company? newValue) {
                    setState(() {
                      _selectedCompany = newValue;
                    });
                  },
                  validator: (value) =>
                      value == null && _companyController.text == ''
                          ? "Select an existing or Create a new company"
                          : null,
                )
              ])),
          SizedBox(height: 10),
          Visibility(
              visible: updatedUser.userGroupId != 'GROWERP_M_ADMIN' &&
                  updatedUser.userGroupId != 'GROWERP_M_EMPLOYEE',
              child: Row(children: [
                Expanded(
                    child: Text(updatedUser.companyAddress != null
                        ? "${updatedUser.companyAddress!.city!} ${updatedUser.companyAddress!.country!}"
                        : "No address yet")),
                SizedBox(
                    width: 100,
                    child: ElevatedButton(
                      onPressed: () async {
                        var result = await showDialog(
                            barrierDismissible: true,
                            context: context,
                            builder: (BuildContext context) {
                              return AddressDialog(
                                  address: updatedUser.companyAddress);
                            });
                        if (result != null)
                          setState(() {
                            updatedUser =
                                updatedUser.copyWith(companyAddress: result);
                          });
                      },
                      child: Text(updatedUser.companyAddress != null
                          ? 'Update\nAddress'
                          : 'Add\nAddress'),
                    ))
              ])),
          SizedBox(height: 10),
          Row(children: [
            Expanded(
                child: ElevatedButton(
                    key: Key('cancel'),
                    child: Text('Cancel'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    })),
            SizedBox(width: 10),
            Expanded(
                child: ElevatedButton(
                    key: Key('update'),
                    child:
                        Text(updatedUser.partyId == null ? 'Create' : 'Update'),
                    onPressed: () async {
                      if (_formKey.currentState!.validate() && !loading) {
                        updatedUser = updatedUser.copyWith(
                            firstName: _firstNameController.text,
                            lastName: _lastNameController.text,
                            email: _emailController.text,
                            loginName: _nameController.text,
                            userGroupId: _selectedUserGroup!.userGroupId,
                            language: Localizations.localeOf(context)
                                .languageCode
                                .toString(),
                            companyName: _companyController.text,
                            image: await HelperFunctions.getResizedImage(
                                _imageFile?.path));
                        if (_imageFile?.path != null &&
                            updatedUser.image == null)
                          HelperFunctions.showMessage(
                              context,
                              "Image upload error or larger than 50K",
                              Colors.red);
                        else
                          updatedUser.userGroupId == "GROWERP_M_EMPLOYEE"
                              ? BlocProvider.of<EmployeeBloc>(context)
                                  .add(UpdateUser(updatedUser))
                              : updatedUser.userGroupId == "GROWERP_M_ADMIN"
                                  ? BlocProvider.of<AdminBloc>(context)
                                      .add(UpdateUser(updatedUser))
                                  : updatedUser.userGroupId ==
                                          "GROWERP_M_SUPPLIER"
                                      ? BlocProvider.of<SupplierBloc>(context)
                                          .add(UpdateUser(updatedUser))
                                      : updatedUser.userGroupId ==
                                              "GROWERP_M_LEAD"
                                          ? BlocProvider.of<LeadBloc>(context)
                                              .add(UpdateUser(updatedUser))
                                          : updatedUser.userGroupId ==
                                                  "GROWERP_M_CUSTOMER"
                                              ? BlocProvider.of<CustomerBloc>(
                                                      context)
                                                  .add(UpdateUser(updatedUser))
                                              : print(
                                                  "Not recognized usergroupId: "
                                                  "${updatedUser.userGroupId}");
                      }
                    })),
          ])
        ]));
  }
}
