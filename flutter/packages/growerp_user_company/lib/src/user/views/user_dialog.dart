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
import 'package:growerp_core/growerp_core.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../company/views/views.dart';

class ShowUserDialog extends StatelessWidget {
  final User user;
  const ShowUserDialog(this.user, {super.key});
  @override
  Widget build(BuildContext context) {
    CompanyUserAPIRepository repos = CompanyUserAPIRepository(
        context.read<AuthBloc>().state.authenticate!.apiKey!);
    return BlocProvider<UserBloc>(
        create: (context) => UserBloc(repos, Role.company),
        child: RepositoryProvider.value(value: repos, child: UserDialog(user)));
  }
}

class UserDialog extends StatefulWidget {
  final User user;
  const UserDialog(this.user, {super.key});
  @override
  UserDialogState createState() => UserDialogState();
}

class UserDialogState extends State<UserDialog> {
  late final GlobalKey<FormState> _userDialogFormKey;
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _loginNameController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _companyController = TextEditingController();
  final _companySearchBoxController = TextEditingController();

  bool loading = false;
  late List<UserGroup> localUserGroups;
  late UserGroup _selectedUserGroup;
  late Role _selectedRole;
  Company _selectedCompany = Company();
  XFile? _imageFile;
  dynamic _pickImageError;
  String? _retrieveDataError;
  late User updatedUser;
  late CompanyUserAPIRepository repos;
  final ImagePicker _picker = ImagePicker();
  late UserBloc _userBloc;
  bool _isLoginDisabled = false;
  late bool isPhone;
  bool _hasLogin = false;
  late final GlobalKey<ScaffoldMessengerState> _userDialogKey;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _userDialogFormKey = GlobalKey<FormState>();
    _userDialogKey = GlobalKey<ScaffoldMessengerState>();

    if (widget.user.partyId != null) {
      _firstNameController.text = widget.user.firstName ?? '';
      _lastNameController.text = widget.user.lastName ?? '';
      _loginNameController.text = widget.user.loginName ?? '';
      _telephoneController.text = widget.user.telephoneNr ?? '';
      _emailController.text = widget.user.email ?? '';
      _isLoginDisabled = widget.user.loginDisabled ?? false;
      _hasLogin = widget.user.userId != null;
    }
    if (widget.user.company != null) {
      _selectedCompany = Company(
          partyId: widget.user.company!.partyId,
          name: widget.user.company!.name);
    }
    _selectedRole = widget.user.company!.role ?? Role.unknown;
    _selectedUserGroup = widget.user.userGroup ?? UserGroup.employee;
    localUserGroups = UserGroup.values;
    updatedUser = widget.user;
    _userBloc = context.read<UserBloc>();
    repos = context.read<CompanyUserAPIRepository>();
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
    isPhone = ResponsiveBreakpoints.of(context).isMobile;
    User? user = widget.user;
    return BlocConsumer<UserBloc, UserState>(
        listenWhen: (previous, current) =>
            previous.status == UserStatus.loading,
        listener: (context, state) {
          if (state.status == UserStatus.failure) {
            loading = false;
            // message on this dialog
            _userDialogKey.currentState!.showSnackBar(
                snackBar(context, Colors.red, state.message ?? ''));
          }
          if (state.status == UserStatus.success) {
            // message on parent page
            HelperFunctions.showMessage(context, state.message, Colors.green);
            Navigator.of(context).pop(state.users[0]);
          }
        },
        builder: (context, state) {
          return Stack(children: [
            scaffoldWidget(user, context),
            if (state.status == UserStatus.loading) const LoadingIndicator(),
          ]);
        });
  }

  Dialog scaffoldWidget(User user, BuildContext context) {
    return Dialog(
      key: Key('UserDialog${_selectedRole.name}'),
      insetPadding: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: popUp(
          context: context,
          title:
              "${_selectedRole == Role.company ? widget.user.userGroup != null && widget.user.userGroup == UserGroup.admin ? 'Admininistrator' : 'Employee' : _selectedRole.name} contact person information",
          width: isPhone ? 400 : 1000,
          height: isPhone ? 700 : 700,
          child: ScaffoldMessenger(
              key: _userDialogKey,
              child: Scaffold(
                  backgroundColor: Colors.transparent,
                  floatingActionButton:
                      ImageButtons(_scrollController, _onImageButtonPressed),
                  body: listChild()))),
    );
  }

  Widget listChild() {
    return !kIsWeb && defaultTargetPlatform == TargetPlatform.android
        ? FutureBuilder<void>(
            future: retrieveLostData(),
            builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
              if (snapshot.hasError) {
                return Text(
                  'Pick image error: ${snapshot.error}}',
                  textAlign: TextAlign.center,
                );
              }
              return _showForm();
            })
        : _showForm();
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
    return _userDialog();
  }

  Widget _userDialog() {
    Authenticate authenticate = context.read<AuthBloc>().state.authenticate!;
    User? currentUser = authenticate.user;
    if (_selectedRole == Role.company) {
      _selectedCompany = authenticate.company!;
    }

    Future<List<Company>> getOwnedCompanies(filter) async {
      ApiResult<List<Company>> result = await repos.getCompanies(
          filter: _companySearchBoxController.text, mainCompanies: false);
      return result.when(
          success: (data) => data,
          failure: (_) => [Company(name: 'get data error!')]);
    }

    List<Widget> widgets = [
      InputDecorator(
        decoration: InputDecoration(
          labelText: 'User information',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25.0),
          ),
        ),
        child: Column(
          children: [
            Row(children: [
              Expanded(
                  child: TextFormField(
                key: const Key('firstName'),
                decoration: const InputDecoration(labelText: 'First Name'),
                controller: _firstNameController,
                validator: (value) {
                  if (value!.isEmpty) return 'Please enter a first name?';
                  return null;
                },
              )),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  key: const Key('lastName'),
                  decoration: const InputDecoration(labelText: 'Last Name'),
                  controller: _lastNameController,
                  validator: (value) {
                    if (value!.isEmpty) return 'Please enter a last name?';
                    return null;
                  },
                ),
              )
            ]),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    key: const Key('userEmail'),
                    decoration:
                        const InputDecoration(labelText: 'Email address'),
                    controller: _emailController,
                    validator: (String? value) {
                      if (value!.isNotEmpty &&
                          !RegExp(r"[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?")
                              .hasMatch(value)) {
                        return 'This is not a valid email';
                      }
                      if (value.isEmpty &&
                          _loginNameController.text.isNotEmpty) {
                        return 'Email for login required!';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    key: const Key('userTelephoneNr'),
                    decoration:
                        const InputDecoration(labelText: 'Telephone number'),
                    controller: _telephoneController,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      Visibility(
          visible: _selectedRole != Role.company,
          child: InputDecorator(
              decoration: InputDecoration(
                labelText: "${_selectedCompany.role?.value ?? Role.unknown}"
                    " Company information",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                ),
              ),
              child: Column(children: [
                Row(children: [
                  Expanded(
                    child: DropdownSearch<Company>(
                      key: const Key('userCompanyName'),
                      selectedItem: _selectedCompany.name == null
                          ? Company(name: '')
                          : _selectedCompany,
                      popupProps: PopupProps.menu(
                        showSearchBox: true,
                        searchFieldProps: TextFieldProps(
                          autofocus: true,
                          decoration:
                              const InputDecoration(labelText: "company,name"),
                          controller: _companySearchBoxController,
                        ),
                        menuProps: MenuProps(
                            borderRadius: BorderRadius.circular(20.0)),
                        title: popUp(
                          context: context,
                          title: 'Select company',
                          height: 50,
                          width: 450,
                        ),
                      ),
                      dropdownDecoratorProps: const DropDownDecoratorProps(
                          dropdownSearchDecoration:
                              InputDecoration(labelText: 'Company')),
                      itemAsString: (Company? u) => " ${u!.name}",
                      asyncItems: (String? filter) =>
                          getOwnedCompanies(_companySearchBoxController.text),
                      onChanged: (Company? newValue) {
                        setState(() {
                          _selectedCompany = newValue ?? Company();
                        });
                      },
                      validator: (value) =>
                          value == null && _companyController.text == ''
                              ? "Select an existing or Create a new company"
                              : null,
                    ),
                  ),
                ]),
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (_selectedCompany.name != null)
                      Expanded(
                          child: ElevatedButton(
                        key: const Key('editCompany'),
                        onPressed: () async {
                          await showDialog(
                              barrierDismissible: true,
                              context: context,
                              builder: (BuildContext context) {
                                return ShowCompanyDialog(_selectedCompany);
                              });
                        },
                        child: const Text('Update Company'),
                      )),
                    const SizedBox(width: 10),
                    Expanded(
                        child: ElevatedButton(
                      key: const Key('newCompany'),
                      onPressed: () async {
                        var result = await showDialog(
                            barrierDismissible: true,
                            context: context,
                            builder: (BuildContext context) {
                              return ShowCompanyDialog(Company(
                                  partyId: '_NEW_', role: _selectedRole));
                            });
                        if (result is Company) {
                          setState(() {
                            _selectedCompany = result;
                            _selectedRole = result.role!;
                          });
                        }
                      },
                      child: const Text('New Company'),
                    )),
                  ],
                ),
              ]))),
      Visibility(
        visible: widget.user.company!.role == Role.company,
        child: InputDecorator(
            decoration: InputDecoration(
              labelText: 'User Login',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25.0),
              ),
            ),
            child: Column(children: [
              TextFormField(
                readOnly: !(currentUser!.userGroup == UserGroup.admin),
                key: const Key('loginName'),
                decoration:
                    const InputDecoration(labelText: 'User Login Name '),
                controller: _loginNameController,
                onChanged: (value) {
                  if (value.isNotEmpty != _hasLogin) {
                    return setState(() {
                      _hasLogin = !_hasLogin;
                    });
                  }
                },
                validator: (value) {
                  if (widget.user.userGroup == UserGroup.admin &&
                      value!.isEmpty) {
                    return 'An administrator needs a username!';
                  }
                  return null;
                },
              ),
              if (currentUser.userGroup == UserGroup.admin &&
                  _loginNameController.text.isNotEmpty)
                Column(children: [
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(
                        child: DropdownButtonFormField<UserGroup>(
                      decoration: const InputDecoration(
                          labelText: 'Security User Group'),
                      key: const Key('userGroup'),
                      hint: const Text('Security User Group'),
                      value: _selectedUserGroup,
                      validator: (value) =>
                          value == null ? 'field required' : null,
                      items: localUserGroups.map((item) {
                        return DropdownMenuItem<UserGroup>(
                            value: item, child: Text(item.name));
                      }).toList(),
                      onChanged: (UserGroup? newValue) {
                        setState(() {
                          _selectedUserGroup = newValue!;
                        });
                      },
                      isExpanded: true,
                    )),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 100,
                      height: 60,
                      child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Disabled',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25.0),
                            ),
                          ),
                          child: Checkbox(
                            key: const Key('loginDisabled'),
                            value: _isLoginDisabled,
                            onChanged: (bool? value) {
                              setState(() {
                                _isLoginDisabled = value!;
                              });
                            },
                          )),
                    )
                  ])
                ])
            ])),
      )
    ];
    Widget updateButton = Row(children: [
      if (widget.user.partyId != null)
        ElevatedButton(
            style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(Colors.red)),
            key: const Key('deleteUser'),
            child: const Text('Delete User'),
            onPressed: () async {
              var result =
                  await confirmDeleteUserComp(context, widget.user.userGroup!);
              if (result != null) {
                if (!mounted) return;
                // delete company too?
                if (widget.user.partyId == authenticate.user!.partyId!) {
                  context
                      .read<UserBloc>()
                      .add(UserDelete(widget.user.copyWith(image: null)));
                  Navigator.of(context).pop(updatedUser);
                  context.read<AuthBloc>().add(const AuthLoggedOut());
                } else {
                  context
                      .read<UserBloc>()
                      .add(UserDelete(widget.user.copyWith(image: null)));
                }
              }
            }),
      const SizedBox(width: 10),
      Expanded(
          child: ElevatedButton(
              key: const Key('updateUser'),
              child: Text(updatedUser.partyId == null ? 'Create' : 'Update'),
              onPressed: () async {
                if (_userDialogFormKey.currentState!.validate()) {
                  updatedUser = updatedUser.copyWith(
                      firstName: _firstNameController.text,
                      lastName: _lastNameController.text,
                      email: _emailController.text,
                      loginName: _loginNameController.text,
                      telephoneNr: _telephoneController.text,
                      loginDisabled: _isLoginDisabled,
                      userGroup: _selectedUserGroup,
                      language: Localizations.localeOf(context)
                          .languageCode
                          .toString(),
                      company: _selectedCompany.name != null
                          ? _selectedCompany
                          : Company(
                              name:
                                  "${_lastNameController.text}, ${_firstNameController.text}",
                              role: _selectedRole),
                      image: await HelperFunctions.getResizedImage(
                          _imageFile?.path));
                  if (!mounted) return;
                  if (_imageFile?.path != null && updatedUser.image == null) {
                    HelperFunctions.showMessage(
                        context, "Image upload error!", Colors.red);
                  } else {
                    _userBloc.add(UserUpdate(updatedUser));
                    if (context
                            .read<AuthBloc>()
                            .state
                            .authenticate!
                            .user!
                            .partyId ==
                        updatedUser.partyId) {
                      context.read<UserBloc>().add(UserUpdate(updatedUser));
                    }
                  }
                }
              }))
    ]);

    List<Widget> column = [];
    for (var i = 0; i < widgets.length; i++) {
      column.add(Padding(padding: const EdgeInsets.all(10), child: widgets[i]));
    }
    column.add(updateButton);

    List<Widget> rows = [];
    if (!ResponsiveBreakpoints.of(context).isMobile) {
      rows.add(const SizedBox(height: 20));
      rows.add(SizedBox(
          height: 350,
          child: MasonryGridView.count(
            itemCount: widgets.length,
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            itemBuilder: (context, index) {
              return widgets[index];
            },
          )));
      rows.add(updateButton);
    }

    return Form(
        key: _userDialogFormKey,
        child: SingleChildScrollView(
            controller: _scrollController,
            key: const Key('listView'),
            child: Column(children: <Widget>[
              Center(
                  child: Text(
                'User $_selectedRole'
                ' #${updatedUser.partyId ?? " New"}',
                style:
                    const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                key: const Key('header'),
              )),
              Center(
                  child: Text(
                'Company #${updatedUser.company!.partyId ?? ""}',
                style:
                    const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                key: const Key('compHeader'),
              )),
              const SizedBox(height: 10),
              CircleAvatar(
                  backgroundColor: Colors.green,
                  radius: 80,
                  child: _imageFile != null
                      ? kIsWeb
                          ? Image.network(_imageFile!.path, scale: 0.3)
                          : Image.file(File(_imageFile!.path), scale: 0.3)
                      : widget.user.image != null
                          ? Image.memory(widget.user.image!, scale: 0.3)
                          : Text(widget.user.firstName?.substring(0, 1) ?? '',
                              style: const TextStyle(fontSize: 30))),
              Column(children: rows.isNotEmpty ? rows : column),
            ])));
  }
}
